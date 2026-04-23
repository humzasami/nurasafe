// Core/RAGEngine.swift
// Retrieval-Augmented Generation — hybrid BM25 + E5 semantic retrieval.
//
// Pipeline:
//   1. Load KnowledgeBase.json
//   2. Embed each chunk with multilingual-e5-small when model is available
//   3. At query time:
//      a. Always compute BM25 lexical score for every candidate
//      b. Detect if E5 embeddings are degenerate (all cosine scores cluster > 0.88 with < 0.06 spread)
//         — this happens when SimpleTokenizer maps most words to unkToken (100)
//      c. Degenerate E5: BM25 is sole ranker (weight 1.0)
//      d. Healthy E5: E5(0.60) + BM25(0.40) hybrid
//   4. Scenario filter: when active mode is set, only consider chunks from that scenario + "general"

import Foundation

// MARK: - Knowledge Chunk (bundle JSON)

struct KnowledgeChunk: Codable {
    let id: String
    let scenario: String
    let title: String
    let content: String
}

private extension KnowledgeChunkEntity {
    init(chunk: KnowledgeChunk, embedding: [Float]?) {
        self.id = chunk.id
        self.scenario = chunk.scenario
        self.title = chunk.title
        self.content = chunk.content
        self.embeddingData = embedding ?? []
    }

    var hasEmbedding: Bool { !embeddingData.isEmpty }
}

// MARK: - RAG Engine

@MainActor
final class RAGEngine {

    @MainActor static let shared = RAGEngine()

    private let topK = 3
    private let vectorThreshold: Float = 0.25

    /// Degenerate embedding detection thresholds.
    /// When the top-20 vector scores all have min > 0.88 AND spread < 0.06,
    /// the SimpleTokenizer is mapping most words to unkToken — embeddings carry no signal.
    private let degenerateSpreadThreshold: Float = 0.06
    private let degenerateMinScore: Float = 0.88

    private var allChunks: [KnowledgeChunk] = []
    private(set) var isIndexed = false

    private let embeddingService = EmbeddingService.shared
    private let vectorStore = VectorStore.shared
    private let indexStore = KnowledgeIndexStore.shared

    private init() {}

    // MARK: - Build Index

    func buildIndex() async {
        guard !isIndexed else { return }

        guard let chunks = loadKnowledgeBase() else {
            print("[RAG] ERROR: KnowledgeBase.json not found in app bundle.")
            return
        }
        allChunks = chunks

        embeddingService.reloadFromBundleIfNeeded()

        guard embeddingService.isAvailable else {
            print("[RAG] E5 model not loaded — BM25-only mode active (still functional).")
            AppLog.rag.warning("E5 unavailable — BM25-only retrieval")
            ObjectBoxKnowledgeStore.replaceAll(chunks: chunks)
            isIndexed = true
            print("[RAG] Index ready: \(chunks.count) chunks | mode: BM25 lexical only | topK=\(topK)")
            return
        }

        await buildSemanticIndex(chunks: chunks)
        isIndexed = true
        print("[RAG] Index ready: \(chunks.count) chunks | mode: E5+BM25 hybrid | topK=\(topK)")
        AppLog.rag.info("Index ready: \(chunks.count) chunks, hybrid BM25+E5, topK=\(self.topK)")
    }

    private func buildSemanticIndex(chunks: [KnowledgeChunk]) async {
        if indexStore.isUpToDate(), indexStore.hasEmbeddingCache {
            let entities = indexStore.loadAllChunks()
            let embedded = entities.filter(\.hasEmbedding)
            let items = embedded.map { (id: $0.id, embedding: $0.embeddingData) }
            if items.count == chunks.count {
                vectorStore.insertAll(items)
                ObjectBoxKnowledgeStore.replaceAll(chunks: chunks)
                print("[RAG] ✓ Loaded \(items.count) embeddings from disk cache → VectorStore")
                return
            }
            print("[RAG] Cache incomplete (\(embedded.count)/\(chunks.count)) — re-embedding.")
        } else if !indexStore.isUpToDate() {
            print("[RAG] Knowledge base changed — clearing embedding cache.")
            indexStore.clearAll()
        }

        print("[RAG] ⏳ Computing E5 embeddings for \(chunks.count) chunks…")
        let entities: [KnowledgeChunkEntity] = await Task.detached(priority: .utility) {
            var result: [KnowledgeChunkEntity] = []
            for (i, chunk) in chunks.enumerated() {
                let embedding = EmbeddingService.shared.embedPassage(
                    title: chunk.title,
                    content: chunk.content
                )
                result.append(KnowledgeChunkEntity(chunk: chunk, embedding: embedding))
                if (i + 1) % 10 == 0 { print("[RAG]   Embedded \(i + 1)/\(chunks.count)…") }
            }
            return result
        }.value

        let vectorItems = entities.compactMap { e -> (id: String, embedding: [Float])? in
            guard e.hasEmbedding else { return nil }
            return (id: e.id, embedding: e.embeddingData)
        }
        if vectorItems.isEmpty, embeddingService.isAvailable {
            print("[RAG] ⚠️ E5 available but 0 embeddings — tokenizer/model mismatch. BM25 will be primary.")
            AppLog.rag.error("Semantic index empty despite E5 available")
        }
        vectorStore.insertAll(vectorItems)
        indexStore.saveChunks(entities)
        indexStore.markUpToDate()
        ObjectBoxKnowledgeStore.replaceAll(chunks: chunks)
        print("[RAG] ✓ Semantic index: \(vectorItems.count) vectors persisted")
    }

    // MARK: - Retrieve

    /// Hybrid BM25 + E5 retrieval.
    /// - Parameters:
    ///   - query: LLM-compressed retrieval phrase (used for E5 embedding).
    ///   - userMessageForSignals: Verbatim user message (used for BM25 scoring — more faithful to intent).
    ///   - scenario: Active emergency scenario — filters candidates to that scenario + "general".
    func retrieve(query: String, userMessageForSignals: String? = nil, scenario: EmergencyScenario? = nil) async -> [KnowledgeChunk] {
        guard isIndexed, !allChunks.isEmpty else {
            AppLog.rag.warning("retrieve skipped: index not ready")
            return []
        }

        // Use verbatim user message for BM25 (more faithful to intent than LLM-compressed query)
        let signalText: String = {
            let u = userMessageForSignals?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return u.isEmpty ? query : u
        }()

        let candidates = candidates(for: scenario)
        guard !candidates.isEmpty else {
            print("╚═ [RAG] ⚠️  No candidates after scenario filter")
            return []
        }

        // ── Step 1: BM25 lexical scoring (always computed) ──────────────────────
        let bm25Raw = bm25Score(query: signalText, candidates: candidates)
        let maxBM25 = bm25Raw.values.max() ?? 1.0
        let normBM25: [String: Float] = maxBM25 > 0 ? bm25Raw.mapValues { $0 / maxBM25 } : bm25Raw

        // ── Step 2: E5 semantic scoring (when available) ─────────────────────────
        var normSemantic: [String: Float] = [:]
        var embeddingsDegenerate = true

        if embeddingService.isAvailable, vectorStore.count > 0,
           let queryEmbedding = embeddingService.embedQuery(query) {
            let candidateIds = Set(candidates.map(\.id))
            let rawResults = vectorStore.search(
                query: queryEmbedding,
                topK: candidates.count,
                threshold: vectorThreshold
            )
            let filtered = rawResults.filter { candidateIds.contains($0.id) }

            // Degenerate detection: all top scores cluster tightly → embeddings carry no signal
            let topScores = filtered.prefix(20).map(\.similarity)
            if topScores.count >= 5 {
                let maxS = topScores.max() ?? 0
                let minS = topScores.min() ?? 0
                let spread = maxS - minS
                embeddingsDegenerate = (minS > degenerateMinScore && spread < degenerateSpreadThreshold)
                if embeddingsDegenerate {
                    print("[RAG] ⚠️ Degenerate E5 (spread=\(String(format: "%.3f", spread)), min=\(String(format: "%.3f", minS))) — BM25 primary")
                    AppLog.rag.warning("Degenerate E5 embeddings — BM25 primary ranker")
                }
            } else {
                embeddingsDegenerate = filtered.isEmpty
            }

            if !embeddingsDegenerate {
                // Normalise relative to range (not absolute) so small differences are amplified
                let semMin = filtered.map(\.similarity).min() ?? 0
                let semMax = filtered.map(\.similarity).max() ?? 1
                let semRange = max(semMax - semMin, 0.001)
                for r in filtered {
                    normSemantic[r.id] = (r.similarity - semMin) / semRange
                }
            }
        }

        // ── Step 3: Combine and rank ──────────────────────────────────────────────
        // Healthy E5:    semantic(0.60) + BM25(0.40)
        // Degenerate E5: BM25(1.00) — semantic is noise, don't let it corrupt results
        let semanticWeight: Float = embeddingsDegenerate ? 0.0 : 0.60
        let lexicalWeight: Float  = embeddingsDegenerate ? 1.0 : 0.40

        var combined: [(KnowledgeChunk, Float)] = candidates.map { chunk in
            let sem = normSemantic[chunk.id] ?? 0
            let lex = normBM25[chunk.id] ?? 0
            let uaeAdj = Self.uaeOfficialSourcesAdjustment(lexicalSignal: signalText, chunk: chunk)
            return (chunk, semanticWeight * sem + lexicalWeight * lex + uaeAdj)
        }
        combined.sort { $0.1 > $1.1 }

        let results = Array(combined.prefix(topK).map(\.0))
        let scoreRows: [(String, Float)] = results.map { ch in
            (ch.id, combined.first(where: { $0.0.id == ch.id })?.1 ?? 0)
        }

        let mode = embeddingsDegenerate ? "BM25" : "E5+BM25"
        logSemanticResults(results, scores: scoreRows, mode: mode)
        return results
    }

    // MARK: - BM25 Scoring

    /// BM25 (Okapi BM25) lexical scorer.
    /// k1=1.5 (TF saturation), b=0.75 (length normalisation).
    /// Title matches get 3× weight; scenario/ID matches get 1.8× weight.
    private func bm25Score(query: String, candidates: [KnowledgeChunk]) -> [String: Float] {
        let k1: Float = 1.5
        let b: Float  = 0.75

        let queryTerms = bm25Tokenize(query)
        guard !queryTerms.isEmpty else { return [:] }

        let N = Float(candidates.count)
        let docLengths = candidates.map { bm25DocLen($0) }
        let avgDocLen = docLengths.isEmpty ? 1.0 : Float(docLengths.reduce(0, +)) / N

        var idf: [String: Float] = [:]
        for term in queryTerms {
            let df = Float(candidates.filter { bm25Haystack($0).contains(term) }.count)
            idf[term] = log((N - df + 0.5) / (df + 0.5) + 1.0)
        }

        var scores: [String: Float] = [:]
        for (i, chunk) in candidates.enumerated() {
            let docLen = Float(docLengths[i])
            let hay = bm25Haystack(chunk)
            let titleLower = chunk.title.lowercased()
            let scenarioLower = chunk.scenario.lowercased()
            var score: Float = 0

            for term in queryTerms {
                let tf = Float(bm25TermFrequency(hay, term: term))
                let termIDF = idf[term] ?? 0
                let tfNorm = (tf * (k1 + 1)) / (tf + k1 * (1 - b + b * docLen / avgDocLen))
                score += termIDF * tfNorm

                // Title match: 3× bonus (title is the most concentrated signal)
                if titleLower.contains(term) { score += termIDF * 2.0 }

                // Scenario/ID match: 1.8× bonus
                if scenarioLower.contains(term) || chunk.id.lowercased().contains(term) {
                    score += termIDF * 0.8
                }
            }
            scores[chunk.id] = score
        }
        return scores
    }

    private func bm25Tokenize(_ text: String) -> [String] {
        let stopwords: Set<String> = [
            "the","a","an","and","or","but","in","on","at","to","for","of","with","by","from",
            "is","are","was","were","be","been","being","have","has","had","do","does","did",
            "will","would","could","should","may","might","can","shall","not","no","nor",
            "what","how","when","where","who","which","that","this","these","those","it","its",
            "they","them","their","we","our","you","your","he","she","him","her","his",
            "about","into","through","during","before","after","above","below","between",
            "very","just","also","only","even","still","already","yet","both","each","more",
            "most","other","some","such","than","then","there","here","so","if","as","up","out",
            "get","got","use","used","need","like","make","take","give","come","go","see","know",
            "tell","ask","want","look","think","feel","say","said","one","two","three","four","five"
        ]
        return text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 && !stopwords.contains($0) }
    }

    private func bm25Haystack(_ chunk: KnowledgeChunk) -> String {
        "\(chunk.title) \(chunk.content)".lowercased()
    }

    private func bm25DocLen(_ chunk: KnowledgeChunk) -> Int {
        bm25Tokenize(bm25Haystack(chunk)).count
    }

    private func bm25TermFrequency(_ haystack: String, term: String) -> Int {
        var count = 0
        var searchRange = haystack.startIndex..<haystack.endIndex
        while let range = haystack.range(of: term, range: searchRange) {
            count += 1
            searchRange = range.upperBound..<haystack.endIndex
        }
        return count
    }

    // MARK: - UAE adjustment (kept for UAE-specific queries)

    private static func uaeOfficialSourcesAdjustment(lexicalSignal: String, chunk: KnowledgeChunk) -> Float {
        let q = lexicalSignal.lowercased()
        let asksUAE =
            q.contains("uae") || q.contains("emirates") || q.contains("emirate")
            || q.contains("abu dhabi") || q.contains("dubai") || q.contains("ncema")
            || (q.contains("official") && (q.contains("news") || q.contains("source") || q.contains("government")))
        guard asksUAE else { return 0 }

        let hay = "\(chunk.id) \(chunk.title) \(chunk.content)".lowercased()
        var adj: Float = 0
        if hay.contains("ncema") { adj += 0.07 }
        if hay.contains("uae") || hay.contains("emirates") { adj += 0.04 }
        if hay.contains("ministry") || hay.contains("modgov") { adj += 0.04 }
        if hay.contains("u.ae") || hay.contains("ncema.gov") { adj += 0.04 }
        if chunk.scenario.lowercased() == "general" { adj += 0.02 }

        let hasUAEContent = hay.contains("uae") || hay.contains("emirates") || hay.contains("ncema")
            || hay.contains("abu dhabi") || hay.contains("dubai")
        let tacticalScenarios: Set<String> = [
            "First Aid", "Fire", "Flood", "Earthquake", "Nuclear / Radiation", "War / Conflict",
            "Chemical Hazard", "Tsunami", "Wildfire", "Blizzard / Extreme Cold", "Power Outage", "Shelter"
        ]
        if tacticalScenarios.contains(chunk.scenario), !hasUAEContent { adj -= 0.06 }

        return max(-0.1, min(adj, 0.22))
    }

    // MARK: - Candidate filtering

    private func candidates(for scenario: EmergencyScenario?) -> [KnowledgeChunk] {
        if let sc = scenario {
            return allChunks.filter { $0.scenario == sc.rawValue || $0.scenario == "general" }
        }
        return allChunks
    }

    // MARK: - Format for prompt

    nonisolated func formatContext(_ chunks: [KnowledgeChunk]) -> String {
        guard !chunks.isEmpty else { return "" }
        var lines = [
            "[Reference knowledge — ranked by relevance: [1] is most relevant to the query, then [2], [3].]",
            "[Verbatim detail — copy codes, phone numbers, and proper nouns exactly as written.]"
        ]
        for (index, chunk) in chunks.enumerated() {
            lines.append("[\(index + 1)] \(chunk.title): \(chunk.content)")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Logging

    private func logSemanticResults(_ results: [KnowledgeChunk], scores: [(String, Float)], mode: String = "hybrid") {
        let scoreById = Dictionary(scores, uniquingKeysWith: { first, _ in first })
        if results.isEmpty {
            print("╚═ [RAG] ⚠️  No chunks retrieved")
            AppLog.rag.warning("Retrieval: 0 chunks")
            return
        }
        print("║  ┌─ Retrieved \(results.count) chunk(s) via \(mode)")
        for (i, chunk) in results.enumerated() {
            let s = String(format: "%.4f", scoreById[chunk.id] ?? 0)
            let prefix = i == results.count - 1 ? "└─" : "├─"
            print("║  \(prefix) [\(i + 1)] \(chunk.id)  score=\(s)  \(chunk.title)")
            AppLog.rag.notice("  chunk [\(i + 1)] id=\(chunk.id) score=\(s) title=\(chunk.title)")
        }
        print("╚═ [RAG] Done (\(mode))")
    }

    // MARK: - Load JSON

    private func loadKnowledgeBase() -> [KnowledgeChunk]? {
        guard let url = Bundle.main.url(forResource: "KnowledgeBase", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let chunks = try? JSONDecoder().decode([KnowledgeChunk].self, from: data)
        else { return nil }
        return chunks
    }
}

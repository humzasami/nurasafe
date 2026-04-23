// Core/VectorStore.swift
// In-memory vector store with cosine similarity search.
//
// Architecture:
//   • Stores (id, embedding) pairs in a flat array
//   • At query time: brute-force cosine similarity over all entries
//   • For 66–500 chunks this is fast (<1ms). For 1000+ chunks,
//     consider upgrading to ObjectBox with HNSW index.
//
// ObjectBox HNSW (optional): see KnowledgeVectorEntity+ObjectBox.swift.
// Runtime search uses brute-force cosine here; fine for hundreds of chunks.
//
// Uses Accelerate framework for fast dot-product computation on Apple Silicon.

import Foundation
import Accelerate

// MARK: - Vector Entry

struct VectorEntry {
    let id: String          // Matches KnowledgeChunk.id
    let embedding: [Float]  // L2-normalised embedding vector
}

// MARK: - Search Result

struct VectorSearchResult {
    let id: String
    let similarity: Float   // Cosine similarity: -1.0 to 1.0 (higher = more similar)
}

// MARK: - Vector Store

final class VectorStore {

    nonisolated(unsafe) static let shared = VectorStore()

    private var entries: [VectorEntry] = []
    private(set) var count: Int = 0

    private init() {}

    // MARK: - Insert

    /// Adds a single entry. Replaces existing entry with same id.
    func insert(id: String, embedding: [Float]) {
        // Remove existing entry with same id if present
        entries.removeAll { $0.id == id }
        entries.append(VectorEntry(id: id, embedding: embedding))
        count = entries.count
    }

    /// Bulk insert — more efficient than repeated single inserts.
    func insertAll(_ items: [(id: String, embedding: [Float])]) {
        let ids = Set(items.map { $0.id })
        entries.removeAll { ids.contains($0.id) }
        entries.append(contentsOf: items.map { VectorEntry(id: $0.id, embedding: $0.embedding) })
        count = entries.count
    }

    // MARK: - Search

    /// Returns the top-K most similar entries to the query vector.
    /// Assumes both query and stored vectors are L2-normalised
    /// (cosine similarity = dot product for normalised vectors).
    ///
    /// - Parameters:
    ///   - query: L2-normalised query embedding.
    ///   - topK: Maximum number of results to return.
    ///   - threshold: Minimum similarity score (0.0–1.0). Default: 0.3
    /// - Returns: Results sorted by similarity descending.
    func search(query: [Float], topK: Int, threshold: Float = 0.3) -> [VectorSearchResult] {
        guard !entries.isEmpty, !query.isEmpty else { return [] }

        let dim = query.count
        var allScored: [(id: String, similarity: Float)] = []

        let start = Date()
        for entry in entries {
            guard entry.embedding.count == dim else { continue }
            var similarity: Float = 0
            vDSP_dotpr(query, 1, entry.embedding, 1, &similarity, vDSP_Length(dim))
            allScored.append((id: entry.id, similarity: similarity))
        }
        let elapsed = Date().timeIntervalSince(start) * 1000

        // Sort all and take topK for logging, then filter by threshold for return
        let sorted = allScored.sorted { $0.similarity > $1.similarity }
        let passed = sorted.filter { $0.similarity >= threshold }
        let results = Array(passed.prefix(topK))

        // Log top-10 scores so you can see the full similarity distribution
        let top10 = sorted.prefix(10)
        let entryCount = self.entries.count
        print("║  [VectorStore] Searched \(entryCount) vectors in \(String(format: "%.2f", elapsed))ms (dim=\(dim), threshold=\(threshold))")
        AppLog.vector.info("Vector search: \(entryCount) vectors in \(String(format: "%.2f", elapsed))ms dim=\(dim) threshold=\(threshold) — returning \(results.count) above threshold")
        print("║  Top scores (all candidates):")
        for (i, r) in top10.enumerated() {
            let marker = results.contains(where: { $0.id == r.id }) ? "✓" : "✗"
            print("║    \(marker) [\(i+1)] \(r.id)  similarity: \(String(format: "%.4f", r.similarity))")
            if i < 5 {
                AppLog.vector.notice("  top[\(i + 1)] id=\(r.id, privacy: .public) similarity=\(String(format: "%.4f", r.similarity), privacy: .public) \(marker == "✓" ? "passes" : "below threshold/topK")")
            }
        }
        print("║  Passed threshold: \(passed.count)/\(entryCount)  →  returning top \(results.count)")

        return results.map { VectorSearchResult(id: $0.id, similarity: $0.similarity) }
    }

    // MARK: - Management

    /// Removes all entries. Call when knowledge base is updated.
    func clear() {
        entries.removeAll()
        count = 0
    }

    /// Returns true if an entry with the given id exists.
    func contains(id: String) -> Bool {
        entries.contains { $0.id == id }
    }
}

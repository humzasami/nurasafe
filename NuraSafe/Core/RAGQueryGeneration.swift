// Core/RAGQueryGeneration.swift
// Parses LLM output from the retrieval-query pass.
// The LLM outputs either:
//   <retrieval_query>search phrase</retrieval_query>  — run RAG with this phrase
//   <retrieval_skip/>                                 — skip RAG entirely (general conversation)

import Foundation

enum RAGQueryGeneration {
    /// Detected in prompts so MockLLMEngine can return a tagged query without loading Qwen.
    static let promptMarker = "[INTERNAL_RETRIEVAL_QUERY_V1]"

    /// Sentinel returned by parseTaggedQuery when the LLM outputs <retrieval_skip/>.
    /// ChatEngine checks for this value and skips ragEngine.retrieve entirely.
    static let skipSentinel = "__RAG_SKIP__"

    /// Small LLMs often echo "emergency + shelter + app name" even when the user asked about RAG/tests. If the
    /// candidate string drifts too far from the user's wording, E5 search should use the raw user message instead.
    static func fusedRetrievalQuery(userMessage: String, candidate: String) -> String {
        let u = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        let c = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        if c.isEmpty { return u }
        if c.caseInsensitiveCompare(u) == .orderedSame { return c }

        if shouldPreferRawUserMessage(u) { return u }

        let uTok = meaningfulTokens(u)
        let cTok = meaningfulTokens(c)
        guard !uTok.isEmpty else { return c }

        let uSet = Set(uTok)
        let cSet = Set(cTok)
        let inter = uSet.intersection(cSet)
        let union = uSet.union(cSet)
        let jaccard = union.isEmpty ? 0.0 : Double(inter.count) / Double(union.count)

        let lowerC = c.lowercased()
        var substringHits = 0
        for t in uTok {
            if lowerC.contains(t) { substringHits += 1 }
        }
        let coverage = Double(substringHits) / Double(uTok.count)

        if jaccard < 0.2 && coverage < 0.5 {
            return u
        }
        return c
    }

    /// App / QA about RAG verification token, diagnostic chunk, etc.
    private static func shouldPreferRawUserMessage(_ message: String) -> Bool {
        let lower = message.lowercased()
        if lower.contains("ns_obx") || lower.contains("ns-obx") { return true }
        if lower.contains("diag-objectbox") || lower.contains("diag objectbox") { return true }
        if lower.contains("verification token") || lower.contains("secret verification") { return true }

        let toks = Set(meaningfulTokens(message))
        let mentionsRAG = toks.contains("rag") || toks.contains("retrieval") || toks.contains("vector")
            || toks.contains("nurasafe") || toks.contains("objectbox")
        let mentionsTest = toks.contains("test") || toks.contains("code") || toks.contains("token")
            || toks.contains("diagnostic") || toks.contains("verify") || toks.contains("verification")
        if mentionsRAG && mentionsTest { return true }

        return false
    }

    private static let retrievalStopwords: Set<String> = [
        "the", "a", "an", "and", "or", "but", "if", "then", "else", "for", "with", "about", "into",
        "from", "that", "this", "these", "those", "what", "when", "where", "which", "who", "whom", "how", "why",
        "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "do", "does", "did", "can", "could",
        "would", "should", "may", "might", "must", "shall", "will",
        "you", "your", "yours", "me", "my", "mine", "i", "we", "our", "us", "they", "them", "their", "he", "she", "it",
        "its", "him", "her", "his",
        "please", "just", "tell", "give", "get", "got", "want", "need", "like", "some", "any", "all", "each", "very",
        "too", "also", "only", "not", "no", "yes", "here", "there", "now", "then", "out", "off", "over", "under"
    ]

    private static func meaningfulTokens(_ text: String) -> [String] {
        let lower = text.lowercased()
        let parts = lower.split { !$0.isLetter && !$0.isNumber }
        return parts.map(String.init).filter { $0.count > 2 && !retrievalStopwords.contains($0) }
    }

    /// Keywords used for lexical reranking over E5 hits (same rules as fusion).
    static func retrievalKeywordSet(_ text: String) -> Set<String> {
        Set(meaningfulTokens(text))
    }

    /// True when the KB diagnostic chunk should be guaranteed in top results if it exists.
    static func shouldEnsureDiagnosticChunk(_ query: String) -> Bool {
        shouldPreferRawUserMessage(query)
    }

    /// Parses the LLM output from the retrieval-query pass.
    ///
    /// Returns:
    /// - `skipSentinel` ("__RAG_SKIP__") when the LLM outputs `<retrieval_skip/>` — caller must skip RAG.
    /// - A non-empty search phrase when the LLM outputs `<retrieval_query>phrase</retrieval_query>`.
    /// - `fallback` (the raw user message) when the output cannot be parsed.
    static func parseTaggedQuery(_ raw: String, fallback: String) -> String {
        let trimmedAll = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAll.isEmpty else { return fallback }

        // Detect skip sentinel first — check before looking for retrieval_query
        if trimmedAll.lowercased().contains("<retrieval_skip") {
            return skipSentinel
        }

        let open = "<retrieval_query>"
        let close = "</retrieval_query>"
        guard let openRange = raw.range(of: open, options: .caseInsensitive),
              let closeRange = raw.range(of: close, options: .caseInsensitive, range: openRange.upperBound..<raw.endIndex)
        else {
            // No XML tags found — check if the first line looks like a plain skip signal
            let firstLine = trimmedAll.split(separator: "\n", omittingEmptySubsequences: false)
                .first
                .map(String.init)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let lowerFirst = firstLine.lowercased()
            if lowerFirst == "na" || lowerFirst == "skip" || lowerFirst == "none" {
                return skipSentinel
            }
            if firstLine.count >= 3, firstLine.count <= 500, !firstLine.contains("<") {
                return firstLine
            }
            return fallback
        }

        let inner = String(raw[openRange.upperBound..<closeRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if inner.isEmpty { return fallback }
        if inner.count > 800 { return String(inner.prefix(800)) }
        return inner
    }
}

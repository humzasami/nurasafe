// Storage/KnowledgeIndexStore.swift
// Persists knowledge chunk JSON + E5 embedding vectors on disk (Application Support).
// For ObjectBox HNSW on-device, run Tools/ObjectBoxModel generator (see KnowledgeVectorEntity+ObjectBox.swift).

import Foundation

private struct ChunkCache: Codable {
    let kbHash: String
    let entities: [KnowledgeChunkEntity]
}

final class KnowledgeIndexStore {

    nonisolated(unsafe) static let shared = KnowledgeIndexStore()

    private let cacheURL: URL
    private let kbHashKey = "ns_kb_hash"
    /// Bump this version string whenever the tokenizer or embedding pipeline changes.
    /// A mismatch forces a full re-embed so stale vectors are never used.
    private let tokenizerVersion = "unigram-v1"
    private let tokenizerVersionKey = "ns_tokenizer_version"

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("NuraSafe/KnowledgeIndex", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        cacheURL = dir.appendingPathComponent("chunks.json")
        print("[KnowledgeIndex] Cache path: \(cacheURL.path)")
        invalidateIfTokenizerChanged()
    }

    /// Clears the embedding cache if the tokenizer version has changed since last run.
    private func invalidateIfTokenizerChanged() {
        let stored = UserDefaults.standard.string(forKey: tokenizerVersionKey) ?? ""
        if stored != tokenizerVersion {
            print("[KnowledgeIndex] Tokenizer version changed (\(stored) → \(tokenizerVersion)) — clearing embedding cache.")
            try? FileManager.default.removeItem(at: cacheURL)
            UserDefaults.standard.removeObject(forKey: kbHashKey)
            UserDefaults.standard.set(tokenizerVersion, forKey: tokenizerVersionKey)
        }
    }

    static func knowledgeBaseHash() -> String {
        guard let url = Bundle.main.url(forResource: "KnowledgeBase", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return "" }
        let count = data.count
        let head = data.prefix(64).map { String($0) }.joined()
        let tail = data.suffix(64).map { String($0) }.joined()
        return "\(count)-\(head)-\(tail)"
    }

    func isUpToDate() -> Bool {
        let storedHash = UserDefaults.standard.string(forKey: kbHashKey) ?? ""
        let currentHash = Self.knowledgeBaseHash()
        return !storedHash.isEmpty && storedHash == currentHash
    }

    /// True if a non-empty embedding cache file exists.
    var hasEmbeddingCache: Bool {
        FileManager.default.fileExists(atPath: cacheURL.path) && storedChunkCount() > 0
    }

    func markUpToDate() {
        UserDefaults.standard.set(Self.knowledgeBaseHash(), forKey: kbHashKey)
    }

    func invalidate() {
        UserDefaults.standard.removeObject(forKey: kbHashKey)
        try? FileManager.default.removeItem(at: cacheURL)
        print("[KnowledgeIndex] Cache invalidated.")
    }

    func saveChunks(_ entities: [KnowledgeChunkEntity]) {
        let cache = ChunkCache(kbHash: Self.knowledgeBaseHash(), entities: entities)
        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: cacheURL, options: .atomic)
            print("[KnowledgeIndex] Saved \(entities.count) chunks + embeddings.")
        } catch {
            print("[KnowledgeIndex] ERROR saving: \(error)")
        }
    }

    func loadAllChunks() -> [KnowledgeChunkEntity] {
        guard let data = try? Data(contentsOf: cacheURL) else { return [] }
        do {
            let cache = try JSONDecoder().decode(ChunkCache.self, from: data)
            print("[KnowledgeIndex] Loaded \(cache.entities.count) chunks from disk.")
            return cache.entities
        } catch {
            print("[KnowledgeIndex] ERROR loading: \(error)")
            return []
        }
    }

    func storedChunkCount() -> Int {
        loadAllChunks().count
    }

    func clearAll() {
        try? FileManager.default.removeItem(at: cacheURL)
        invalidate()
        print("[KnowledgeIndex] Cleared stored chunks.")
    }

    var isAvailable: Bool { true }
}

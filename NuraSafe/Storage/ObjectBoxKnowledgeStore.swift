// Storage/ObjectBoxKnowledgeStore.swift
// Persists every knowledge chunk as a KnowledgeVectorEntity row for inspection and future ObjectBox queries.

import Foundation
import ObjectBox

@MainActor
enum ObjectBoxKnowledgeStore {
    private static var cachedStore: Store?

    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("NuraSafe/ObjectBox", isDirectory: true)
    }

    private static func openStore() throws -> Store {
        if let cachedStore { return cachedStore }
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let store = try Store(directoryPath: directoryURL.path)
        cachedStore = store
        return store
    }

    /// Replaces all rows with one entity per chunk (matches KnowledgeBase.json items).
    static func replaceAll(chunks: [KnowledgeChunk]) {
        do {
            let store = try openStore()
            let box: Box<KnowledgeVectorEntity> = store.box(for: KnowledgeVectorEntity.self)
            try box.removeAll()
            let rows: [KnowledgeVectorEntity] = chunks.map { chunk in
                KnowledgeVectorEntity(
                    chunkId: chunk.id,
                    scenario: chunk.scenario,
                    title: chunk.title,
                    content: chunk.content
                )
            }
            try box.put(rows)
            print("[RAG] ✓ ObjectBox: stored \(rows.count) knowledge chunk(s)")
            AppLog.rag.info("ObjectBox: \(rows.count) chunk rows")
        } catch {
            print("[RAG] ⚠️ ObjectBox sync failed: \(error)")
            AppLog.rag.error("ObjectBox replaceAll failed: \(error.localizedDescription)")
        }
    }
}

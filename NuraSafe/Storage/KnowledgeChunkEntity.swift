// Storage/KnowledgeChunkEntity.swift
// Plain Codable struct for persisting knowledge chunks + E5 embeddings.
// Written by KnowledgeIndexStore (JSON). ObjectBox migration: Docs/ObjectBox-setup.md.

import Foundation

struct KnowledgeChunkEntity: Codable {
    var id: String
    var scenario: String
    var title: String
    var content: String
    /// Flat float array — 384 dimensions for multilingual-e5-small.
    var embeddingData: [Float]
}

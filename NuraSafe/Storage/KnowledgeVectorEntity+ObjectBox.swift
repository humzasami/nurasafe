// Storage/KnowledgeVectorEntity+ObjectBox.swift
// One ObjectBox row per KnowledgeBase.json chunk (text fields). E5 vectors live in VectorStore.
// To regenerate with HNSW embeddings: run `swift package plugin … objectbox-generator` in Tools/ObjectBoxModel
// and replace EntityInfo-NuraSafe.generated.swift after merging the embedding property.
//
import Foundation
import ObjectBox

// objectbox: entity
final class KnowledgeVectorEntity {
    var id: Id = 0
    /// Stable id from KnowledgeBase.json (e.g. fa-001).
    var chunkId: String = ""
    var scenario: String = ""
    var title: String = ""
    var content: String = ""

    required init() {}

    init(chunkId: String, scenario: String, title: String, content: String) {
        self.chunkId = chunkId
        self.scenario = scenario
        self.title = title
        self.content = content
    }
}

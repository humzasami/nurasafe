// ObjectBox entity: one row per KnowledgeBase chunk (text). App target uses hand-written EntityInfo-NuraSafe.generated.swift.
// For HNSW vector search, add embedding back and run:
//   swift package plugin --allow-writing-to-package-directory --allow-network-connections all objectbox-generator --target ObjectBoxModel --no-statistics
import Foundation
import ObjectBox

// objectbox: entity
final class KnowledgeVectorEntity {
    var id: Id = 0
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

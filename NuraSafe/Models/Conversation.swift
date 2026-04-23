// Models/Conversation.swift

import Foundation
import SwiftData

@Model
final class Conversation {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    /// Non-nil when this conversation was created under an emergency mode.
    /// Stores the rawValue of the EmergencyScenario.
    var emergencyModeRaw: String?

    @Relationship(deleteRule: .cascade)
    var messages: [ChatMessage]

    var emergencyMode: EmergencyScenario? {
        get {
            guard let raw = emergencyModeRaw else { return nil }
            return EmergencyScenario(rawValue: raw)
        }
        set { emergencyModeRaw = newValue?.rawValue }
    }

    var isEmergencyChat: Bool { emergencyModeRaw != nil }

    init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPinned: Bool = false,
        messages: [ChatMessage] = [],
        emergencyMode: EmergencyScenario? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.messages = messages
        self.emergencyModeRaw = emergencyMode?.rawValue
    }
}

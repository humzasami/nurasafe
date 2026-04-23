// Models/ChatMessage.swift

import Foundation
import SwiftData

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

enum MessageStatus: String, Codable {
    case sending
    case streaming
    case complete
    case failed
}

@Model
final class ChatMessage {
    var id: UUID
    var role: MessageRole
    var content: String
    var timestamp: Date
    var status: MessageStatus
    var conversationID: UUID

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        status: MessageStatus = .complete,
        conversationID: UUID
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.status = status
        self.conversationID = conversationID
    }
}

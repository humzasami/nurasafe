// Storage/StorageService.swift
// SwiftData persistence layer.

import Foundation
import SwiftData

@MainActor
final class StorageService {

    @MainActor static let shared = StorageService()

    let container: ModelContainer

    private init() {
        let schema = Schema([Conversation.self, ChatMessage.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("NuraSafe: Failed to create SwiftData container — \(error)")
        }
    }

    var context: ModelContext {
        container.mainContext
    }

    // MARK: - Conversations

    func fetchConversations() throws -> [Conversation] {
        let descriptor = FetchDescriptor<Conversation>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func createConversation(title: String = "New Conversation") -> Conversation {
        let conv = Conversation(title: title)
        context.insert(conv)
        return conv
    }

    func deleteConversation(_ conversation: Conversation) throws {
        context.delete(conversation)
        try context.save()
    }

    func save() {
        try? context.save()
    }

    // MARK: - Messages

    func addMessage(_ message: ChatMessage, to conversation: Conversation) {
        context.insert(message)
        if !conversation.messages.contains(where: { $0.id == message.id }) {
            conversation.messages.append(message)
        }
        conversation.updatedAt = Date()
        save()
    }

    func clearHistory() throws {
        let conversations = try fetchConversations()
        for conv in conversations {
            context.delete(conv)
        }
        try context.save()
    }
}

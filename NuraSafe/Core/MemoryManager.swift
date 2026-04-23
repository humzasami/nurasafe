// Core/MemoryManager.swift
// LangChain ConversationBufferWindowMemory for NuraSafe.
//
// Strategy: Keep the last N user+assistant message pairs verbatim.
// When the window is full, oldest pairs are dropped (no summarisation —
// summaries confused the 3B model more than they helped).
// This guarantees the last 3 exchanges (3 user + 3 assistant) are always in the prompt.

import Foundation

// MARK: - Memory entry

struct MemoryEntry {
    enum Role: String { case user, assistant, summary }
    let role: Role
    let content: String
}

// MARK: - MemoryManager

final class MemoryManager {

    /// Maximum number of user+assistant PAIRS to keep (3 pairs = 6 entries: 3 user + 3 assistant).
    private let maxPairs: Int

    private(set) var entries: [MemoryEntry] = []
    private(set) var summary: String? = nil

    init(maxPairs: Int = 3) {
        self.maxPairs = maxPairs
    }

    // MARK: - Add turn

    func addUserMessage(_ text: String) {
        entries.append(MemoryEntry(role: .user, content: text))
        trim()
    }

    func addAssistantMessage(_ text: String) {
        entries.append(MemoryEntry(role: .assistant, content: text))
        trim()
    }

    // MARK: - Build context

    /// Plain-text dialogue for retrieval query generation.
    func buildPlainDialogueForRetrieval(maxChars: Int = 2400) -> String {
        var parts: [String] = []
        for entry in entries {
            switch entry.role {
            case .user:      parts.append("User: \(entry.content)")
            case .assistant: parts.append("Assistant: \(entry.content)")
            case .summary:   break
            }
        }
        var text = parts.joined(separator: "\n")
        if text.count > maxChars { text = String(text.suffix(maxChars)) }
        return text
    }

    // MARK: - Reset

    func reset() {
        entries.removeAll()
        summary = nil
    }

    /// Rebuild from persisted messages. Keeps last `maxPairs` pairs.
    func replaceFromPersisted(_ messages: [(role: MemoryEntry.Role, content: String)]) {
        reset()
        let filtered = messages.filter { $0.role == .user || $0.role == .assistant }
        let limited = Array(filtered.suffix(maxPairs * 2))
        for (role, content) in limited {
            entries.append(MemoryEntry(role: role, content: content))
        }
    }

    // MARK: - Trim

    private func trim() {
        // Simple window: drop oldest pair when we exceed maxPairs
        while entries.count > maxPairs * 2 {
            // Remove oldest user+assistant pair
            if entries.count >= 2 {
                entries.removeFirst(2)
            } else {
                entries.removeFirst()
            }
        }
    }
}

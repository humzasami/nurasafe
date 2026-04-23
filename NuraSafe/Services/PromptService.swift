// Services/PromptService.swift
// Builds the full ChatML prompt sent to the LLM.
//
// LangChain ConversationBufferWindowMemory pattern — simplified for 3B on-device models:
//
//   <|im_start|>system
//   {persona + instructions}
//   <|im_end|>
//   <|im_start|>system
//   [Conversation history — the N most recent exchange(s), oldest first.]
//   <|im_end|>
//   <|im_start|>user
//   {prior turn 1}
//   <|im_end|>
//   <|im_start|>assistant
//   {prior turn 1 reply}
//   <|im_end|>
//   ... (last 3 pairs: 3 user + 3 assistant)
//   <|im_start|>user
//   {RAG passages if relevant}
//   {current question}
//   <|im_end|>
//   <|im_start|>assistant
//
// Key design: history is explicitly labelled so the model knows those are prior turns,
// not the current question. Current user message is LAST — right before the assistant opener.
// Small models attend best to content near the end of the prompt.

import Foundation

@MainActor
final class PromptService {

    @MainActor static let shared = PromptService()
    private init() {}

    // MARK: - Retrieval query (first LLM pass)

    func buildRetrievalQueryPrompt(userMessage: String, memory: MemoryManager) -> String {
        let dialogue = memory.buildPlainDialogueForRetrieval()
        let userBlock: String
        if dialogue.isEmpty {
            userBlock = """
            \(RAGQueryGeneration.promptMarker)

            Current message:
            \(userMessage)
            """
        } else {
            userBlock = """
            \(RAGQueryGeneration.promptMarker)

            Recent conversation (oldest to newest):
            \(dialogue)

            Current message:
            \(userMessage)
            """
        }

        return """
        <|im_start|>system
        placeholder
        <|im_end|>
        <|im_start|>user
        \(userBlock)
        <|im_end|>
        <|im_start|>assistant
        """
    }

    // MARK: - Primary prompt builder

    func buildPrompt(
        userMessage: String,
        systemPrompt: String,
        memory: MemoryManager,
        ragChunks: [KnowledgeChunk] = []
    ) -> String {
        var parts: [String] = []

        // ── 1. System prompt ─────────────────────────────────────────────────
        parts.append("<|im_start|>system\n\(systemPrompt)<|im_end|>")

        // ── 2. Conversation history as proper ChatML turns ───────────────────
        // Last 3 pairs (3 user + 3 assistant) kept verbatim, oldest first.
        // A system block explicitly labels the section so the 3B model cannot
        // confuse prior turns with the current question or with RAG passages.
        if let summary = memory.summary, !summary.isEmpty {
            parts.append("<|im_start|>system\n[Earlier conversation summary]: \(summary)<|im_end|>")
        }

        if !memory.entries.isEmpty {
            parts.append("<|im_start|>system\n[Conversation history — the \(memory.entries.count / 2) most recent exchange(s), oldest first. Use this to answer follow-up questions.]<|im_end|>")
            for entry in memory.entries {
                switch entry.role {
                case .user:
                    parts.append("<|im_start|>user\n\(entry.content)<|im_end|>")
                case .assistant:
                    parts.append("<|im_start|>assistant\n\(entry.content)<|im_end|>")
                case .summary:
                    parts.append("<|im_start|>system\n[Context]: \(entry.content)<|im_end|>")
                }
            }
        }

        // ── 3. Current user message (with optional RAG) ──────────────────────
        // RAG passages go at the TOP of the user turn, current question at the BOTTOM.
        // Small models attend most to the last content before <|im_start|>assistant.
        let ragBlock: String? = ragChunks.isEmpty ? nil : RAGEngine.shared.formatContext(ragChunks)

        var userContent = ""

        if let block = ragBlock {
            userContent += """
            [Reference knowledge from NuraSafe database — use for safety/emergency facts only. \
            If this is a conversational follow-up (math, clarification), ignore these passages and use the conversation above.]

            \(block)

            ---
            """
            AppLog.rag.notice("PromptService: RAG \(ragChunks.count) chunk(s) in user turn")
        }

        userContent += userMessage

        parts.append("<|im_start|>user\n\(userContent)<|im_end|>")

        // ── 4. Assistant opener ───────────────────────────────────────────────
        parts.append("<|im_start|>assistant\n")

        let prompt = parts.joined(separator: "\n")
        print("── [Prompt] \(prompt.count) chars | history entries: \(memory.entries.count) | RAG: \(ragChunks.count)")
        return prompt
    }

    // MARK: - Legacy builder (triggerEmergency path)

    func buildPrompt(
        messages: [ChatMessage],
        systemPrompt: String
    ) -> String {
        let maxContextMessages = 14
        let maxCharsPerMessage = 800

        var parts: [String] = []
        parts.append("<|im_start|>system\n\(systemPrompt)<|im_end|>")

        let contextMessages = messages
            .filter { $0.role != .system }
            .suffix(maxContextMessages)

        for message in contextMessages {
            let role = message.role == .user ? "user" : "assistant"
            let content = message.content.count > maxCharsPerMessage
                ? String(message.content.prefix(maxCharsPerMessage)) + "…"
                : message.content
            parts.append("<|im_start|>\(role)\n\(content)<|im_end|>")
        }

        parts.append("<|im_start|>assistant\n")
        return parts.joined(separator: "\n")
    }

    func buildEmergencyPrompt(scenario: EmergencyScenario) -> String {
        let userMessage = SystemPrompts.injected(scenario: scenario)
        return buildPrompt(
            messages: [ChatMessage(role: .user, content: userMessage, conversationID: UUID())],
            systemPrompt: SystemPrompts.emergency
        )
    }
}

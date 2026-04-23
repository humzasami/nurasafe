// Services/ChatEngine.swift
// Orchestrates the full pipeline:
//   IntentRouter → LLM (retrieval query) → RAGEngine (BM25+E5 hybrid) → PromptService → LLM (answer)
//
// Memory: LangChain ConversationBufferWindowMemory — last 7 user+assistant pairs.
// Rebuilt from SwiftData transcript on every send to guarantee consistency.

import Foundation
import Combine

@MainActor
final class ChatEngine: ObservableObject {

    @MainActor static let shared = ChatEngine()

    private let llm: LLMEngineProtocol
    private let promptService: PromptService
    private let storage: StorageService
    private let settings: AppSettings
    private let ragEngine: RAGEngine
    private let intentRouter: IntentRouter

    @Published private(set) var inferenceState: InferenceState = .idle

    private var stateCancellable: AnyCancellable?

    // One MemoryManager per conversation
    private var memoryStore: [UUID: MemoryManager] = [:]

    init(
        llm: LLMEngineProtocol? = nil,
        promptService: PromptService? = nil,
        storage: StorageService? = nil,
        settings: AppSettings? = nil
    ) {
        let resolvedLLM: LLMEngineProtocol = llm ?? {
            #if os(iOS)
            LLMSwiftEngine()
            #else
            MockLLMEngine()
            #endif
        }()
        self.llm = resolvedLLM
        self.promptService = promptService ?? PromptService.shared
        self.storage = storage ?? StorageService.shared
        self.settings = settings ?? AppSettings.shared
        self.ragEngine = RAGEngine.shared
        self.intentRouter = IntentRouter.shared

        stateCancellable = resolvedLLM.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.inferenceState = state
            }
    }

    private func logRAGInjection(decisionLabel: String, urgency: Urgency?, chunks: [KnowledgeChunk]) {
        if let u = urgency {
            AppLog.chatEngine.info("Intent: \(decisionLabel, privacy: .public) urgency=\(String(describing: u), privacy: .public) — retrieved \(chunks.count) chunk(s)")
        } else {
            AppLog.chatEngine.info("Intent: \(decisionLabel, privacy: .public) — retrieved \(chunks.count) chunk(s)")
        }
        if chunks.isEmpty {
            AppLog.chatEngine.warning("RAG returned 0 chunks")
        } else {
            let summary = chunks.map { "\($0.id):\($0.title)" }.joined(separator: " | ")
            AppLog.chatEngine.notice("RAG chunks: \(summary, privacy: .public)")
            for (i, c) in chunks.enumerated() {
                AppLog.chatEngine.info("  [\(i + 1)/\(chunks.count)] id=\(c.id, privacy: .public) scenario=\(c.scenario, privacy: .public)")
            }
        }
    }

    // MARK: - Model Lifecycle

    func loadModel() async {
        await ragEngine.buildIndex()
        do {
            try await llm.loadModel()
        } catch {
            inferenceState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Memory Access

    func memory(for conversationID: UUID) -> MemoryManager {
        if let existing = memoryStore[conversationID] { return existing }
        let manager = MemoryManager(maxPairs: 3)
        memoryStore[conversationID] = manager
        return manager
    }

    /// Sync memory from SwiftData transcript (called on load and conversation switch).
    func syncMemory(with messages: [ChatMessage], conversationID: UUID) {
        let m = memory(for: conversationID)
        let turns = messages
            .filter { ($0.role == .user || $0.role == .assistant) && $0.status == .complete }
            .sorted { $0.timestamp < $1.timestamp }
            .map { msg -> (role: MemoryEntry.Role, content: String) in
                (msg.role == .user ? .user : .assistant, msg.content)
            }
        m.replaceFromPersisted(turns)
    }

    func resetMemory(for conversationID: UUID) {
        memoryStore[conversationID]?.reset()
        memoryStore.removeValue(forKey: conversationID)
    }

    /// Rebuild memory from the UI transcript before each send.
    /// Excludes the current user message (it goes in the prompt's user turn, not in history).
    private func rebuildMemoryFromTranscript(
        _ transcript: [ChatMessage],
        excludingUserText: String,
        conversationID: UUID
    ) {
        let m = memory(for: conversationID)
        let filtered = transcript
            .filter { ($0.role == .user || $0.role == .assistant) && $0.status == .complete }
            .sorted { $0.timestamp < $1.timestamp }

        // Remove the current user message from the end (it's passed separately to buildPrompt)
        let pending = excludingUserText.trimmingCharacters(in: .whitespacesAndNewlines)
        var prior = filtered
        if let last = prior.last, last.role == .user,
           last.content.trimmingCharacters(in: .whitespacesAndNewlines) == pending {
            prior = Array(prior.dropLast())
        }

        let turns = prior.map { msg -> (role: MemoryEntry.Role, content: String) in
            (msg.role == .user ? .user : .assistant, msg.content)
        }
        m.replaceFromPersisted(turns)

        // Debug log
        let count = m.entries.count
        if count > 0 {
            let lastEntry = m.entries.last!
            print("── [Memory] \(count) entries in buffer | last: \(lastEntry.role.rawValue): \(lastEntry.content.prefix(50))…")
        } else {
            print("── [Memory] 0 entries (first message in conversation)")
        }
    }

    // MARK: - Retrieval query

    /// Generates a retrieval query for the knowledge base, or returns nil to skip RAG entirely.
    ///
    /// - Returns: A search phrase to use with `ragEngine.retrieve`, or `nil` when the LLM
    ///   decides the message is general conversation that doesn't need KB grounding.
    ///   When `activeMode` is set, always returns a real query (never skips).
    private func generateRetrievalQuery(userMessage: String, memory: MemoryManager, activeMode: EmergencyScenario? = nil) async -> String? {
        let prompt = promptService.buildRetrievalQueryPrompt(userMessage: userMessage, memory: memory)
        let params = InferenceParameters(
            maxTokens: 96,
            temperature: 0.1,
            topP: 0.8,
            repeatPenalty: 1.08,
            systemPrompt: SystemPrompts.retrievalQueryGeneratorPrompt(activeMode: activeMode)
        )
        var raw = ""
        do {
            let stream = llm.generate(prompt: prompt, parameters: params)
            for try await token in stream {
                raw += token
            }
        } catch {
            AppLog.chatEngine.warning("Retrieval query generation failed: \(error.localizedDescription, privacy: .public)")
            // On error: skip RAG for general chat; use user message for emergency mode
            return activeMode != nil ? userMessage : nil
        }
        let parsed = RAGQueryGeneration.parseTaggedQuery(raw, fallback: userMessage)

        // LLM decided this is general conversation — skip RAG
        // Exception: if activeMode is set, override skip and use user message as query
        if parsed == RAGQueryGeneration.skipSentinel {
            if let mode = activeMode {
                let fallbackQuery = "\(mode.rawValue.lowercased()) \(userMessage)"
                print("── [ChatEngine] RAG query: skip overridden by activeMode (\(mode.rawValue)) → \"\(fallbackQuery)\"")
                return fallbackQuery
            }
            print("── [ChatEngine] RAG query: SKIP (general conversation — no KB lookup)")
            AppLog.chatEngine.info("RAG skipped — query generator classified as general conversation")
            return nil
        }

        let query = RAGQueryGeneration.fusedRetrievalQuery(userMessage: userMessage, candidate: parsed)
        if query != parsed {
            print("── [ChatEngine] RAG query: LLM proposed \"\(parsed)\" → fused: \"\(query)\"")
        } else if query == userMessage {
            print("── [ChatEngine] RAG query: using user message directly")
        } else {
            print("── [ChatEngine] RAG query (LLM): \(query)")
        }
        return query
    }

    // MARK: - Send Message

    func sendMessage(
        _ text: String,
        conversation: Conversation,
        transcriptMessages: [ChatMessage]? = nil,
        activeMode: EmergencyScenario? = nil,
        isEmergency: Bool = false,
        onToken: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void,
        onError: @escaping (String) -> Void
    ) {
        // Step 0: Rebuild memory from transcript (source of truth)
        if let transcript = transcriptMessages {
            rebuildMemoryFromTranscript(transcript, excludingUserText: text, conversationID: conversation.id)
        }
        let memory = memory(for: conversation.id)

        // Step 1: Route intent
        let decision = intentRouter.route(query: text, activeMode: activeMode)

        // Step 2: Select system prompt
        var systemPrompt: String
        var inferenceIsEmergency = isEmergency

        switch decision {
        case .emergencyAlert:
            systemPrompt = activeMode.map { SystemPrompts.activeMode($0) } ?? SystemPrompts.emergency
            inferenceIsEmergency = true
        case .searchKnowledge(let scenario, let urgency):
            if let mode = activeMode {
                systemPrompt = SystemPrompts.activeMode(mode)
            } else if urgency == .high || urgency == .critical {
                systemPrompt = scenario.map { SystemPrompts.activeMode($0) } ?? SystemPrompts.emergency
                inferenceIsEmergency = true
            } else {
                systemPrompt = SystemPrompts.base
            }
        case .directResponse:
            systemPrompt = activeMode.map { SystemPrompts.activeMode($0) } ?? SystemPrompts.base
        }

        systemPrompt = SystemPrompts.withLanguage(systemPrompt, language: settings.preferredLanguage)
        systemPrompt = SystemPrompts.withUserDisplayName(systemPrompt, displayName: UserProfileStore.shared.profile.displayName)

        // Step 3: RAG retrieval + LLM stream
        Task {
            let ragScenario: EmergencyScenario?
            switch decision {
            case .searchKnowledge(let scenario, _): ragScenario = activeMode ?? scenario
            case .emergencyAlert(let scenario):     ragScenario = activeMode ?? scenario
            case .directResponse:                   ragScenario = activeMode
            }

            let retrievalQuery = await generateRetrievalQuery(userMessage: text, memory: memory, activeMode: activeMode)

            // retrievalQuery == nil means the query generator classified this as general conversation.
            // Skip the knowledge base entirely — no BM25, no E5, no chunks in the prompt.
            let ragChunks: [KnowledgeChunk]
            if let query = retrievalQuery {
                ragChunks = await ragEngine.retrieve(
                    query: query,
                    userMessageForSignals: text,
                    scenario: ragScenario
                )
            } else {
                ragChunks = []
                print("── [ChatEngine] RAG skipped — no KB lookup for this turn")
            }

            switch decision {
            case .directResponse:
                let ragLabel = retrievalQuery == nil ? "skipped" : "\(ragChunks.count) chunk(s)"
                print("── [ChatEngine] Intent: directResponse — RAG: \(ragLabel)")
                logRAGInjection(decisionLabel: "directResponse", urgency: nil, chunks: ragChunks)
            case .searchKnowledge(_, let urgency):
                print("── [ChatEngine] Intent: searchKnowledge (urgency: \(urgency)) — RAG: \(ragChunks.count) chunk(s)")
                logRAGInjection(decisionLabel: "searchKnowledge", urgency: urgency, chunks: ragChunks)
            case .emergencyAlert:
                print("── [ChatEngine] Intent: emergencyAlert — RAG: \(ragChunks.count) chunk(s)")
                logRAGInjection(decisionLabel: "emergencyAlert", urgency: nil, chunks: ragChunks)
            }

            // Build prompt — memory has prior turns, text is the current question
            let prompt = promptService.buildPrompt(
                userMessage: text,
                systemPrompt: systemPrompt,
                memory: memory,
                ragChunks: ragChunks
            )

            let baseTemp = Float(settings.temperature)
            let ragGrounding = !ragChunks.isEmpty && !inferenceIsEmergency
            let temperature: Float
            let topP: Float
            if inferenceIsEmergency {
                temperature = 0.3; topP = 0.85
            } else if ragGrounding {
                temperature = min(baseTemp, 0.45); topP = 0.85
            } else {
                temperature = baseTemp; topP = 0.9
            }
            let params = InferenceParameters(
                maxTokens: settings.maxTokens,
                temperature: temperature,
                topP: topP,
                repeatPenalty: 1.1,
                systemPrompt: systemPrompt
            )

            // Add current user message to memory AFTER prompt is built
            // (prompt already has it in the user turn; memory stores it for next exchange)
            memory.addUserMessage(text)

            var fullResponse = ""
            let stream = llm.generate(prompt: prompt, parameters: params)
            do {
                for try await token in stream {
                    fullResponse += token
                    onToken(token)
                }
                memory.addAssistantMessage(fullResponse)
                onComplete(fullResponse)
            } catch {
                onError(error.localizedDescription)
            }
        }
    }

    // MARK: - Emergency Trigger

    func triggerEmergency(
        scenario: EmergencyScenario,
        conversation: Conversation,
        activeMode: EmergencyScenario? = nil,
        onToken: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void,
        onError: @escaping (String) -> Void
    ) {
        let injectedText = SystemPrompts.injected(scenario: scenario)
        sendMessage(
            injectedText,
            conversation: conversation,
            activeMode: activeMode ?? scenario,
            isEmergency: true,
            onToken: onToken,
            onComplete: onComplete,
            onError: onError
        )
    }

    func cancelGeneration() {
        llm.cancelGeneration()
    }
}

// ViewModels/ChatViewModel.swift

import Foundation
import SwiftUI
import Combine

@MainActor
final class ChatViewModel: ObservableObject {

    // MARK: - Published state

    @Published var messages: [ChatMessage] = []
    @Published var allConversations: [Conversation] = []
    @Published var inputText: String = ""
    @Published var isGenerating: Bool = false
    @Published var isModelLoading: Bool = false
    @Published var isModelReady: Bool = false
    @Published var streamingContent: String = ""
    @Published var errorMessage: String? = nil
    @Published var showEmergencyPanel: Bool = false
    @Published var scrollToBottom: Bool = false
    @Published var showModeSelector: Bool = false
    @Published var showHistory: Bool = false

    // MARK: - Active mode

    var activeMode: EmergencyScenario? {
        get { settings.activeMode }
        set { settings.activeMode = newValue }
    }

    // MARK: - Dependencies

    private let engine: ChatEngine
    private let storage: StorageService
    private let settings: AppSettings
    private(set) var conversation: Conversation
    private var cancellables = Set<AnyCancellable>()

    /// The general (non-emergency) conversation the user was on before activating a mode.
    /// Used to return them there when the mode is deactivated.
    private var preEmergencyConversationID: UUID?

    /// Ensures `loadModelIfNeeded()` runs exactly once. Without this, the LLM starts as `.idle`,
    /// which used to set `isModelReady = true` before `engine.loadModel()` → `RAGEngine.buildIndex()` ran,
    /// leaving `VectorStore` empty and forcing lexical RAG fallback.
    private var didRunInitialModelLoad = false

    // MARK: - Init

    init(
        engine: ChatEngine? = nil,
        storage: StorageService? = nil,
        settings: AppSettings? = nil
    ) {
        self.engine = engine ?? .shared
        self.storage = storage ?? .shared
        self.settings = settings ?? .shared

        let store = self.storage
        if let existing = try? store.fetchConversations().first {
            self.conversation = existing
        } else {
            self.conversation = store.createConversation(title: "Emergency Chat")
            store.save()
        }

        loadMessages()
        reloadAllConversations()
        observeEngineState()
    }

    // MARK: - Load

    private func loadMessages() {
        messages = conversation.messages
            .filter { $0.role != .system || $0.content.hasPrefix("🔴") || $0.content.hasPrefix("✅") }
            .sorted { $0.timestamp < $1.timestamp }
        engine.syncMemory(with: messages, conversationID: conversation.id)
    }

    func reloadAllConversations() {
        allConversations = (try? storage.fetchConversations()) ?? []
    }

    // MARK: - Engine state

    private func observeEngineState() {
        engine.$inferenceState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .generating:
                    self.isGenerating = true
                    self.isModelLoading = false
                case .idle:
                    self.isGenerating = false
                    self.isModelLoading = false
                    // Do not set isModelReady here — initial state is idle before loadModel() runs.
                    // Readiness is set when `loadModelIfNeeded()` finishes (after RAG index + LLM load).
                case .loading:
                    self.isModelLoading = true
                    self.isModelReady = false
                case .failed(let msg):
                    self.isGenerating = false
                    self.isModelLoading = false
                    self.isModelReady = false
                    self.errorMessage = "Model error: \(msg)"
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Model loading

    func loadModelIfNeeded() async {
        guard !didRunInitialModelLoad else { return }
        didRunInitialModelLoad = true
        isModelLoading = true
        isModelReady = false
        await engine.loadModel()
        isModelLoading = false
        switch engine.inferenceState {
        case .failed:
            isModelReady = false
        default:
            isModelReady = true
        }
    }

    // MARK: - Conversation management

    func startNewConversation() {
        conversation = storage.createConversation(title: "New Chat")
        storage.save()
        messages = []
        streamingContent = ""
        errorMessage = nil
        reloadAllConversations()
        // Fresh memory for the new conversation
        engine.resetMemory(for: conversation.id)
    }

    func switchConversation(to target: Conversation) {
        guard target.id != conversation.id else { return }
        conversation = target
        loadMessages()
        streamingContent = ""
        errorMessage = nil
        scrollToBottom = true
        // Memory for the target conversation is lazily created in ChatEngine
    }

    func deleteConversations(at offsets: IndexSet) {
        let toDelete = offsets.map { allConversations[$0] }
        for conv in toDelete {
            engine.resetMemory(for: conv.id)
            try? storage.deleteConversation(conv)
            if conv.id == conversation.id {
                if let next = allConversations.first(where: { $0.id != conv.id }) {
                    switchConversation(to: next)
                } else {
                    startNewConversation()
                }
            }
        }
        reloadAllConversations()
    }

    // Auto-title the conversation from the first user message
    private func autoTitleIfNeeded(with text: String) {
        guard conversation.title == "New Chat" || conversation.title == "Emergency Chat" else { return }
        let title = String(text.prefix(40)).trimmingCharacters(in: .whitespacesAndNewlines)
        conversation.title = title.isEmpty ? "Chat" : title
        storage.save()
        reloadAllConversations()
    }

    // MARK: - Active Mode management

    func activateMode(_ scenario: EmergencyScenario) {
        HapticService.notification(.warning)
        showModeSelector = false

        // Remember the current general chat so we can return to it later.
        // Only save if the current conversation is NOT already an emergency chat.
        if !conversation.isEmergencyChat {
            preEmergencyConversationID = conversation.id
        }

        settings.activeMode = scenario

        // Create a dedicated emergency conversation
        let emergencyConvo = storage.createConversation(title: scenario.rawValue)
        emergencyConvo.emergencyMode = scenario
        storage.save()

        conversation = emergencyConvo
        messages = []
        streamingContent = ""
        errorMessage = nil
        // No system chat line here — ActiveModeBanner + WelcomeView suggested questions
        // provide context; a line would block the empty state and hide suggestions.
        scrollToBottom = true
        reloadAllConversations()
    }

    func deactivateMode() {
        guard let current = settings.activeMode else { return }
        HapticService.impact(.medium)

        // Mark the end of this emergency session
        let notice = ChatMessage(
            role: .system,
            content: "✅ \(current.rawValue) Mode deactivated.",
            status: .complete,
            conversationID: conversation.id
        )
        storage.addMessage(notice, to: conversation)

        settings.activeMode = nil

        // Return to the general chat the user was on before the emergency mode,
        // or start a new general chat if there was none.
        if let savedID = preEmergencyConversationID,
           let target = (try? storage.fetchConversations())?.first(where: { $0.id == savedID }) {
            switchConversation(to: target)
        } else {
            startNewConversation()
        }
        preEmergencyConversationID = nil
        reloadAllConversations()
    }

    // MARK: - Send

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isGenerating, !isModelLoading, isModelReady else { return }

        inputText = ""
        HapticService.impact(.light)
        autoTitleIfNeeded(with: text)
        appendUserMessage(text)
        beginStreaming(userText: text)
    }

    func triggerEmergency(_ scenario: EmergencyScenario) {
        guard !isGenerating, !isModelLoading, isModelReady else { return }
        HapticService.notification(.warning)
        showEmergencyPanel = false

        let injectedText = SystemPrompts.injected(scenario: scenario)
        autoTitleIfNeeded(with: scenario.rawValue)
        appendUserMessage(injectedText)

        engine.triggerEmergency(
            scenario: scenario,
            conversation: conversation,
            activeMode: settings.activeMode ?? scenario,
            onToken: { [weak self] token in
                Task { @MainActor in
                    self?.streamingContent += token
                    self?.scrollToBottom = true
                }
            },
            onComplete: { [weak self] fullText in
                Task { @MainActor in
                    self?.finaliseAssistantMessage(fullText)
                }
            },
            onError: { [weak self] error in
                Task { @MainActor in
                    self?.handleError(error)
                }
            }
        )
    }

    func cancelGeneration() {
        engine.cancelGeneration()
        if !streamingContent.isEmpty {
            finaliseAssistantMessage(streamingContent)
        }
    }

    // MARK: - Private helpers

    private func appendUserMessage(_ text: String) {
        let msg = ChatMessage(role: .user, content: text, conversationID: conversation.id)
        storage.addMessage(msg, to: conversation)
        messages.append(msg)
        scrollToBottom = true
    }

    private func beginStreaming(userText: String) {
        streamingContent = ""
        isGenerating = true

        engine.sendMessage(
            userText,
            conversation: conversation,
            transcriptMessages: messages,
            activeMode: settings.activeMode,
            isEmergency: settings.activeMode != nil,
            onToken: { [weak self] token in
                Task { @MainActor in
                    self?.streamingContent += token
                    self?.scrollToBottom = true
                }
            },
            onComplete: { [weak self] fullText in
                Task { @MainActor in
                    self?.finaliseAssistantMessage(fullText)
                }
            },
            onError: { [weak self] error in
                Task { @MainActor in
                    self?.handleError(error)
                }
            }
        )
    }

    private func finaliseAssistantMessage(_ text: String) {
        let msg = ChatMessage(
            role: .assistant,
            content: text,
            status: .complete,
            conversationID: conversation.id
        )
        storage.addMessage(msg, to: conversation)
        messages.append(msg)
        streamingContent = ""
        isGenerating = false
        scrollToBottom = true
        reloadAllConversations()
        HapticService.notification(.success)
    }

    private func handleError(_ error: String) {
        streamingContent = ""
        isGenerating = false
        errorMessage = error
        HapticService.notification(.error)
    }
}

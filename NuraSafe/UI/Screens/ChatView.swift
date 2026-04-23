// UI/Screens/ChatView.swift

import SwiftUI
import UIKit
import Combine

#if os(iOS)

struct ChatView: View {

    @StateObject private var viewModel = ChatViewModel()
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var userProfile = UserProfileStore.shared
    @EnvironmentObject private var termsAcceptance: TermsAcceptanceManager
    @State private var showSettings = false
    @State private var showProfile = false
    @State private var showSideMenu = false
    @State private var showTermsDocument = false
    @State private var showPinnedMessages = false
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AnimatedMeshBackground()

                VStack(spacing: 0) {
                    // Keep chrome in the main column (not only safeAreaInset) so the scroll view cannot draw under the bar.
                    chatTopChrome

                    if let activeMode = settings.activeMode {
                        ActiveModeBanner(
                            scenario: activeMode,
                            onTap: {
                                HapticService.impact(.light)
                                viewModel.showModeSelector = true
                            },
                            onDeactivate: { viewModel.deactivateMode() }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.12),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)

                    if viewModel.isModelLoading {
                        ModelLoadingBanner()
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    messageList

                    if let error = viewModel.errorMessage {
                        StatusBanner(message: error, style: .error)
                            .padding(.bottom, 4)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    ChatInputBar(
                        text: $viewModel.inputText,
                        isGenerating: viewModel.isGenerating,
                        isModelLoading: viewModel.isModelLoading,
                        activeMode: settings.activeMode,
                        textSize: settings.textSize,
                        onSend: { viewModel.sendMessage() },
                        onCancel: { viewModel.cancelGeneration() },
                        onEmergency: {
                            HapticService.impact(.medium)
                            viewModel.showModeSelector = true
                        }
                    )
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: settings.activeMode?.id)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isModelLoading)

                ChatSideMenu(
                    isPresented: $showSideMenu,
                    conversationCount: viewModel.allConversations.count,
                    hasActiveMode: settings.activeMode != nil,
                    activeModeTitle: settings.activeMode?.rawValue,
                    onHistory: {
                        viewModel.showHistory = true
                    },
                    onModes: {
                        viewModel.showModeSelector = true
                    },
                    onSettings: {
                        showSettings = true
                    },
                    profileSubtitle: sideMenuProfileSubtitle,
                    onProfile: {
                        showProfile = true
                    },
                    onTerms: {
                        showTermsDocument = true
                    },
                    onPinned: {
                        showPinnedMessages = true
                    }
                )
                .zIndex(100)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showProfile) { ProfileView() }
            .sheet(isPresented: $showTermsDocument) {
                TermsDocumentView()
                    .environmentObject(termsAcceptance)
            }
            .sheet(isPresented: $showPinnedMessages) {
                PinnedMessagesView(textSize: settings.textSize)
            }
            .sheet(isPresented: $viewModel.showModeSelector) {
                ModeSelectionView(viewModel: viewModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $viewModel.showHistory) {
                ConversationHistoryView(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: showSideMenu) { _, isOpen in
            if isOpen {
                dismissKeyboard()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
        ) { notification in
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
            keyboardHeight = frame.height
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
        ) { _ in
            keyboardHeight = 0
        }
        .task {
            await viewModel.loadModelIfNeeded()
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private var sideMenuProfileSubtitle: String {
        let p = userProfile.profile
        if !p.displayName.isEmpty { return p.displayName }
        if !p.countryRegionCode.isEmpty {
            return CountriesCatalog.displayName(for: p.countryRegionCode)
        }
        let n = p.emergencyContacts.count
        if n > 0 { return "\(n) emergency contact\(n == 1 ? "" : "s")" }
        return "Name, country & contacts"
    }

    /// True when there is no real chat yet — show welcome / suggested prompts (mode on or off).
    private var showWelcomePanel: Bool {
        !viewModel.isGenerating &&
        !viewModel.messages.contains(where: { $0.role == .user || $0.role == .assistant })
    }

    /// While the welcome panel is up, hide orphan system-only rows so suggested questions aren’t pushed away.
    private var displayedMessages: [ChatMessage] {
        if showWelcomePanel {
            return viewModel.messages.filter { $0.role != .system }
        }
        return viewModel.messages
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    if showWelcomePanel {
                        WelcomeView(
                            activeMode: settings.activeMode,
                            inputText: $viewModel.inputText,
                            onSelectMode: { viewModel.showModeSelector = true }
                        )
                        .padding(.top, 40)
                        .transition(.opacity)
                    }

                    ForEach(displayedMessages, id: \.id) { message in
                        if message.role == .system {
                            SystemMessageRow(content: message.content)
                                .id(message.id)
                                .padding(.vertical, 6)
                        } else {
                            MessageBubble(message: message, textSize: settings.textSize)
                                .id(message.id)
                                .padding(.vertical, 3)
                        }
                    }

                    if viewModel.isGenerating {
                        StreamingBubble(content: viewModel.streamingContent, textSize: settings.textSize)
                            .id("streaming")
                            .padding(.vertical, 3)
                    }

                    Color.clear.frame(height: 8).id("bottom")
                }
                .padding(.vertical, 8)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.messages.count)
            }
            .contentMargins(.horizontal, 0, for: .scrollContent)
            .contentMargins(.top, 12, for: .scrollContent)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.scrollToBottom) { _, newValue in
                if newValue {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                    viewModel.scrollToBottom = false
                }
            }
            .onChange(of: viewModel.streamingContent) { _, _ in
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            // Scroll to bottom whenever the keyboard raises so the last message
            // is not hidden behind the keyboard after the user sends a message.
            .onChange(of: keyboardHeight) { _, height in
                if height > 0 {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                // Small delay so the new bubble has been laid out before we scroll.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
    }

    /// Minimal top bar: menu · title · new chat (history / modes / settings live in the side menu).
    private var chatTopChrome: some View {
        NuraSafeChromeBar {
            ZStack {
                HStack(alignment: .center) {
                    Button {
                        HapticService.impact(.light)
                        showSideMenu.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 40, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(showSideMenu ? "Close menu" : "Open menu")

                    Spacer(minLength: 0)

                    Button {
                        HapticService.impact(.light)
                        viewModel.startNewConversation()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 40, alignment: .trailing)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("New chat")
                }

                Image("top-menu")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(maxWidth: min(UIScreen.main.bounds.width * 0.42, 200), maxHeight: 34)
                    .accessibilityLabel("NuraSafe")
                    .allowsHitTesting(false)
                    .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1)
            }
        }
    }
}

// MARK: - System message row

struct SystemMessageRow: View {
    let content: String

    var body: some View {
        HStack {
            Spacer()
            Text(content)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(NuraSafePalette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(Capsule().fill(Color.white.opacity(0.05)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1))
                )
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Welcome / Empty state

struct WelcomeView: View {
    let activeMode: EmergencyScenario?
    @Binding var inputText: String
    let onSelectMode: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            if let mode = activeMode {
                activeModeContent(mode)
            } else {
                noModeContent
            }
        }
        .padding(.horizontal, 20)
    }

    private var noModeContent: some View {
        VStack(spacing: 28) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(NuraSafePalette.magenta.opacity(0.18))
                        .frame(width: 110, height: 110)
                        .blur(radius: 22)
                    Image("BrandLogoMain")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .shadow(color: NuraSafePalette.magenta.opacity(0.45), radius: 14, x: 0, y: 4)
                }
                VStack(spacing: 8) {
                    Text("Hi, how can we help?")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(NuraSafePalette.textPrimary)
                    Text("Offline AI emergency assistant — always ready, no internet needed.")
                        .font(.system(size: 14))
                        .foregroundColor(NuraSafePalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }

            Button(action: {
                HapticService.impact(.medium)
                onSelectMode()
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(NuraSafePalette.accentGradientSoft)
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Select Emergency Mode")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(NuraSafePalette.textPrimary)
                        Text("Lock AI responses to your situation")
                            .font(.system(size: 12))
                            .foregroundColor(NuraSafePalette.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(NuraSafePalette.textTertiary)
                }
                .padding(16)
                .glassCard(cornerRadius: 20, borderOpacity: 0.22, fillOpacity: 0.06)
            }
            .buttonStyle(.plain)

            Text("Or describe your situation below")
                .font(.system(size: 13))
                .foregroundColor(NuraSafePalette.textTertiary)
        }
    }

    private func activeModeContent(_ mode: EmergencyScenario) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(mode.color.opacity(0.15))
                        .frame(width: 72, height: 72)
                    Image(systemName: mode.icon)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(mode.color)
                }
                VStack(spacing: 5) {
                    HStack(spacing: 6) {
                        Circle().fill(mode.color).frame(width: 7, height: 7)
                        Text("\(mode.rawValue) Mode Active")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(mode.color)
                            .textCase(.uppercase)
                            .kerning(0.4)
                    }
                    Text(mode.modeDescription)
                        .font(.system(size: 14))
                        .foregroundColor(NuraSafePalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 8)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Suggested questions")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(NuraSafePalette.textTertiary)
                    .textCase(.uppercase)
                    .kerning(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(mode.suggestedPrompts, id: \.self) { prompt in
                    Button(action: {
                        HapticService.impact(.light)
                        inputText = prompt
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(mode.color)
                                .frame(width: 20)

                            Text(prompt)
                                .font(.system(size: 14))
                                .foregroundColor(NuraSafePalette.textPrimary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)

                            Spacer()

                            Image(systemName: "arrow.up.circle")
                                .font(.system(size: 16))
                                .foregroundColor(mode.color.opacity(0.6))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .glassCard(cornerRadius: 14, borderOpacity: 0.18, fillOpacity: 0.05)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(mode.color.opacity(0.35), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Model loading banner

struct ModelLoadingBanner: View {
    @State private var dots = ""
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.85)
                .tint(NuraSafePalette.magenta)

            VStack(alignment: .leading, spacing: 2) {
                Text("Loading AI model\(dots)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(NuraSafePalette.textPrimary)
                Text("First launch takes 15–20 seconds")
                    .font(.system(size: 11))
                    .foregroundColor(NuraSafePalette.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                LinearGradient(
                    colors: [NuraSafePalette.magenta.opacity(0.12), NuraSafePalette.violet.opacity(0.06)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [NuraSafePalette.magenta.opacity(0.5), NuraSafePalette.violet.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1),
            alignment: .bottom
        )
        .onReceive(timer) { _ in
            dots = dots.count >= 3 ? "" : dots + "."
        }
    }
}

#endif // os(iOS)

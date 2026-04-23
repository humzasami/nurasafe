// UI/Components/MessageBubble.swift

import SwiftUI

#if os(iOS)

// MARK: - Assistant avatar (brand image)

/// Round avatar beside AI / assistant bubbles (Picture 4). Reused in the side menu header.
struct AssistantMessageAvatar: View {
    private let size: CGFloat

    init(size: CGFloat = 32) {
        self.size = size
    }

    var body: some View {
        Image("AssistantAvatar")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.28), lineWidth: 1))
            .shadow(color: NuraSafePalette.magenta.opacity(0.25), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Formatted text helper

struct FormattedMessageText: View {
    let content: String
    let isUser: Bool
    let textSize: Double

    var body: some View {
        formattedText
            .font(.system(size: textSize))
            .foregroundColor(isUser ? .white : NuraSafePalette.textPrimary.opacity(0.92))
    }

    private var formattedText: Text {
        let lines = content.components(separatedBy: "\n")
        var result = Text("")

        for (index, rawLine) in lines.enumerated() {
            let line = rawLine.trimmingCharacters(in: .init(charactersIn: "\r"))
            if index > 0 { result = result + Text("\n") }

            if line.hasPrefix("### ") {
                result = result + Text(String(line.dropFirst(4)))
                    .font(.system(size: textSize, weight: .bold))
            } else if line.hasPrefix("## ") {
                result = result + Text(String(line.dropFirst(3)))
                    .font(.system(size: textSize + 1, weight: .bold))
            } else if line.starts(with: "⚠️") {
                result = result + Text(line)
                    .font(.system(size: textSize - 2, weight: .medium))
                    .foregroundColor(isUser ? .white.opacity(0.65) : NuraSafePalette.textSecondary)
            } else {
                result = result + parseBold(line, isUser: isUser)
            }
        }
        return result
    }

    private func parseBold(_ line: String, isUser: Bool) -> Text {
        let pattern = "\\*\\*(.+?)\\*\\*"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return Text(line) }
        let nsLine = line as NSString
        let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
        guard !matches.isEmpty else { return styledLine(line, isUser: isUser) }

        var result = Text("")
        var lastEnd = 0
        for match in matches {
            let before = nsLine.substring(with: NSRange(location: lastEnd, length: match.range.location - lastEnd))
            if !before.isEmpty { result = result + Text(before) }
            let bold = nsLine.substring(with: match.range(at: 1))
            result = result + Text(bold).bold()
            lastEnd = match.range.location + match.range.length
        }
        let remaining = nsLine.substring(from: lastEnd)
        if !remaining.isEmpty { result = result + Text(remaining) }
        return result
    }

    private func styledLine(_ line: String, isUser: Bool) -> Text {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let numberPattern = "^(\\d+)\\.\\s"
        if let regex = try? NSRegularExpression(pattern: numberPattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(location: 0, length: (trimmed as NSString).length)) {
            let num = (trimmed as NSString).substring(with: match.range(at: 1))
            let rest = String(trimmed.dropFirst(match.range.length))
            return Text("\(num). ").bold() + parseBold(rest, isUser: isUser)
        }
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("• ") {
            let rest = String(trimmed.dropFirst(2))
            return Text("  • ").foregroundColor(isUser ? .white.opacity(0.7) : NuraSafePalette.magenta.opacity(0.95)).bold()
                + parseBold(rest, isUser: isUser)
        }
        return Text(line)
    }
}

// MARK: - Pinned Message Store

final class PinnedMessagesStore: ObservableObject {
    static let shared = PinnedMessagesStore()
    private let key = "ns_pinned_messages_v1"

    @Published private(set) var pinned: [PinnedEntry] = []

    struct PinnedEntry: Codable, Identifiable {
        let id: UUID
        let content: String
        let role: String
        let pinnedAt: Date
    }

    private init() { load() }

    func pin(message: ChatMessage) {
        guard !pinned.contains(where: { $0.id == message.id }) else { return }
        let entry = PinnedEntry(id: message.id, content: message.content, role: message.role.rawValue, pinnedAt: Date())
        pinned.insert(entry, at: 0)
        save()
    }

    func unpin(id: UUID) {
        pinned.removeAll { $0.id == id }
        save()
    }

    func isPinned(_ id: UUID) -> Bool { pinned.contains { $0.id == id } }

    private func save() {
        if let data = try? JSONEncoder().encode(pinned) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([PinnedEntry].self, from: data) else { return }
        pinned = decoded
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {

    let message: ChatMessage
    var isStreaming: Bool = false
    var textSize: Double = 15.0

    @ObservedObject private var pinnedStore = PinnedMessagesStore.shared

    private var isUser: Bool { message.role == .user }
    private var isPinned: Bool { pinnedStore.isPinned(message.id) }

    private var userBubbleGradient: LinearGradient {
        NuraSafePalette.accentGradient
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 52) }
            if !isUser { assistantAvatar }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                bubbleContent
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message.content
                            HapticService.notification(.success)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        Button {
                            if isPinned {
                                pinnedStore.unpin(id: message.id)
                            } else {
                                pinnedStore.pin(message: message)
                            }
                            HapticService.impact(.medium)
                        } label: {
                            Label(isPinned ? "Unpin" : "Pin Message", systemImage: isPinned ? "pin.slash" : "pin")
                        }
                    }

                // Inline action bar — shown only under assistant messages
                if !isUser {
                    inlineActionBar
                }

                if isPinned {
                    HStack(spacing: 3) {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9, weight: .semibold))
                        Text("Pinned")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(NuraSafePalette.magenta.opacity(0.85))
                    .padding(.horizontal, 4)
                }
                timestamp
            }

            if isUser { userAvatar }
            if !isUser { Spacer(minLength: 52) }
        }
        .padding(.horizontal, 12)
        .transition(.asymmetric(
            insertion: .move(edge: isUser ? .trailing : .leading).combined(with: .opacity),
            removal: .opacity
        ))
    }

    // MARK: - Inline action bar (copy / pin) under assistant bubbles

    @State private var copiedFeedback = false

    private var inlineActionBar: some View {
        HStack(spacing: 6) {
            // Copy button
            Button {
                UIPasteboard.general.string = message.content
                HapticService.notification(.success)
                withAnimation(.easeInOut(duration: 0.15)) { copiedFeedback = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.2)) { copiedFeedback = false }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: copiedFeedback ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11, weight: .medium))
                    Text(copiedFeedback ? "Copied" : "Copy")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(copiedFeedback ? Color.green.opacity(0.9) : NuraSafePalette.textTertiary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.07))
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                )
            }
            .buttonStyle(.plain)

            // Pin / Unpin button
            Button {
                if isPinned {
                    pinnedStore.unpin(id: message.id)
                } else {
                    pinnedStore.pin(message: message)
                }
                HapticService.impact(.medium)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isPinned ? "pin.slash" : "pin")
                        .font(.system(size: 11, weight: .medium))
                    Text(isPinned ? "Unpin" : "Pin")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(isPinned ? NuraSafePalette.magenta.opacity(0.9) : NuraSafePalette.textTertiary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isPinned ? NuraSafePalette.magenta.opacity(0.12) : Color.white.opacity(0.07))
                        .overlay(Capsule().stroke(
                            isPinned ? NuraSafePalette.magenta.opacity(0.35) : Color.white.opacity(0.12),
                            lineWidth: 1
                        ))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 4)
    }

    // MARK: - Bubble

    private var bubbleContent: some View {
        Group {
            if isUser {
                Text(message.content)
                    .font(.system(size: textSize))
                    .foregroundColor(.white)
            } else {
                FormattedMessageText(content: message.content, isUser: false, textSize: textSize)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 11)
        .background(bubbleBackground)
        .shadow(
            color: isUser ? NuraSafePalette.magenta.opacity(0.35) : Color.black.opacity(0.35),
            radius: isUser ? 12 : 8,
            x: 0,
            y: isUser ? 4 : 3
        )
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if isUser {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(userBubbleGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.28),
                                    NuraSafePalette.violet.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
    }

    // MARK: - Timestamp

    private var timestamp: some View {
        Text(message.timestamp.formatted(.dateTime.hour().minute()))
            .font(.system(size: 10, weight: .regular))
            .foregroundColor(isUser ? Color.white.opacity(0.55) : NuraSafePalette.textTertiary)
            .padding(.horizontal, 4)
    }

    // MARK: - Avatars

    private var assistantAvatar: some View {
        AssistantMessageAvatar()
            .accessibilityHidden(true)
    }

    private var userAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
            Image(systemName: "person.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
        }
    }
}

// MARK: - Streaming bubble

struct StreamingBubble: View {
    let content: String
    var textSize: Double = 15.0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            assistantAvatar

            Group {
                if content.isEmpty {
                    TypingDotsView()
                } else {
                    FormattedMessageText(content: content, isUser: false, textSize: textSize)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 3)

            Spacer(minLength: 52)
        }
        .padding(.horizontal, 12)
        .transition(.move(edge: .leading).combined(with: .opacity))
    }

    private var assistantAvatar: some View {
        AssistantMessageAvatar()
            .accessibilityHidden(true)
    }
}

// MARK: - Pinned Messages Sheet

struct PinnedMessagesView: View {
    @ObservedObject private var store = PinnedMessagesStore.shared
    @Environment(\.dismiss) private var dismiss
    var textSize: Double = 15.0

    @State private var selectedEntry: PinnedMessagesStore.PinnedEntry? = nil

    var body: some View {
        ZStack {
            AnimatedMeshBackground()
            VStack(spacing: 0) {
                NuraSafeChromeBar {
                    HStack {
                        Text("Pinned Messages")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Button("Done") { dismiss() }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .buttonStyle(.plain)
                    }
                }

                if store.pinned.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "pin.slash")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(NuraSafePalette.textTertiary)
                        Text("No pinned messages")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(NuraSafePalette.textSecondary)
                        Text("Long-press any message and tap Pin to save it here.")
                            .font(.system(size: 13))
                            .foregroundStyle(NuraSafePalette.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(store.pinned) { entry in
                                pinnedRow(entry)
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $selectedEntry) { entry in
            PinnedMessageDetailView(entry: entry, textSize: textSize)
        }
    }

    @ViewBuilder
    private func pinnedRow(_ entry: PinnedMessagesStore.PinnedEntry) -> some View {
        let isAssistant = entry.role != "user"

        Button {
            HapticService.impact(.light)
            selectedEntry = entry
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Header row: sender label + date + unpin
                HStack(alignment: .center) {
                    HStack(spacing: 5) {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text(isAssistant ? "Nura" : "You")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(NuraSafePalette.magenta.opacity(0.9))

                    Spacer()

                    Text(entry.pinnedAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                        .font(.system(size: 11))
                        .foregroundStyle(NuraSafePalette.textTertiary)

                    Button {
                        store.unpin(id: entry.id)
                        HapticService.impact(.light)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(NuraSafePalette.textTertiary)
                    }
                    .buttonStyle(.plain)
                }

                // 3-line preview — uses FormattedMessageText for AI messages so bold/bullets render
                if isAssistant {
                    FormattedMessageText(content: entry.content, isUser: false, textSize: textSize - 1)
                        .lineLimit(3)
                } else {
                    Text(entry.content)
                        .font(.system(size: textSize - 1))
                        .foregroundStyle(NuraSafePalette.textPrimary.opacity(0.92))
                        .lineLimit(3)
                }

                // "Tap to read more" hint when content is long enough to be truncated
                if entry.content.count > 120 {
                    HStack(spacing: 3) {
                        Text("Tap to read full message")
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(NuraSafePalette.violet.opacity(0.75))
                }
            }
            .padding(14)
            .glassCard(cornerRadius: 16, borderOpacity: 0.18, fillOpacity: 0.06)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.unpin(id: entry.id)
            } label: {
                Label("Unpin", systemImage: "pin.slash")
            }
        }
    }
}

// MARK: - Pinned Message Detail (full message with formatting)

struct PinnedMessageDetailView: View {
    let entry: PinnedMessagesStore.PinnedEntry
    var textSize: Double = 15.0

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = PinnedMessagesStore.shared
    @State private var copiedFeedback = false

    private var isAssistant: Bool { entry.role != "user" }

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            VStack(spacing: 0) {
                NuraSafeChromeBar {
                    HStack {
                        // Sender + date
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 5) {
                                Image(systemName: "pin.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                Text(isAssistant ? "Nura" : "You")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(NuraSafePalette.magenta.opacity(0.9))
                            Text(entry.pinnedAt.formatted(.dateTime.month(.abbreviated).day().year().hour().minute()))
                                .font(.system(size: 11))
                                .foregroundStyle(NuraSafePalette.textTertiary)
                        }

                        Spacer()

                        // Copy button
                        Button {
                            UIPasteboard.general.string = entry.content
                            HapticService.notification(.success)
                            withAnimation(.easeInOut(duration: 0.15)) { copiedFeedback = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeInOut(duration: 0.2)) { copiedFeedback = false }
                            }
                        } label: {
                            Image(systemName: copiedFeedback ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(copiedFeedback ? .green : NuraSafePalette.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 6)

                        Button("Done") { dismiss() }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .buttonStyle(.plain)
                    }
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Full message using the same FormattedMessageText used in chat
                        if isAssistant {
                            FormattedMessageText(content: entry.content, isUser: false, textSize: textSize)
                                .padding(20)
                        } else {
                            Text(entry.content)
                                .font(.system(size: textSize))
                                .foregroundStyle(NuraSafePalette.textPrimary.opacity(0.92))
                                .lineSpacing(5)
                                .padding(20)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Unpin button at bottom
                Button {
                    store.unpin(id: entry.id)
                    HapticService.impact(.medium)
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pin.slash")
                            .font(.system(size: 14, weight: .medium))
                        Text("Unpin Message")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(NuraSafePalette.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 1),
                        alignment: .top
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Typing dots

struct TypingDotsView: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(
                        i == phase
                            ? NuraSafePalette.magenta
                            : Color.white.opacity(0.28)
                    )
                    .frame(width: 7, height: 7)
                    .scaleEffect(phase == i ? 1.2 : 0.9)
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15),
                        value: phase
                    )
            }
        }
        .onAppear { phase = 2 }
    }
}

#endif // os(iOS)

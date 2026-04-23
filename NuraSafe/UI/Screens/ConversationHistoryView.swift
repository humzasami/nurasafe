// UI/Screens/ConversationHistoryView.swift

import SwiftUI

#if os(iOS)

struct ConversationHistoryView: View {

    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    /// Hides empty threads still titled "New Chat" / "Emergency Chat" (starters with no messages yet).
    private var visibleConversations: [Conversation] {
        viewModel.allConversations.filter { conv in
            let hasChatContent = conv.messages.contains { $0.role == .user || $0.role == .assistant }
            let isBlankStarter = (conv.title == "New Chat" || conv.title == "Emergency Chat") && !hasChatContent
            return !isBlankStarter
        }
    }

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            VStack(spacing: 0) {
                NuraSafeChromeBar {
                    ZStack {
                        HStack {
                            Spacer(minLength: 0)

                            Button("Done") { dismiss() }
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .buttonStyle(.plain)
                                .frame(minHeight: 38, alignment: .center)
                        }

                        Text("Chat History")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .allowsHitTesting(false)
                    }
                }

                Group {
                    if visibleConversations.isEmpty {
                        emptyState
                    } else {
                        conversationList
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Conversation list

    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(visibleConversations, id: \.id) { conversation in
                    ConversationRow(
                        conversation: conversation,
                        isActive: conversation.id == viewModel.conversation.id
                    ) {
                        viewModel.switchConversation(to: conversation)
                        dismiss()
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(NuraSafePalette.magenta.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(NuraSafePalette.accentGradientSoft)
            }
            Text("No conversations yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(NuraSafePalette.textPrimary)
            Text("Start a chat or tap an emergency scenario")
                .font(.system(size: 14))
                .foregroundColor(NuraSafePalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Conversation row

struct ConversationRow: View {

    let conversation: Conversation
    let isActive: Bool
    let onTap: () -> Void

    private var emergencyMode: EmergencyScenario? { conversation.emergencyMode }

    private var iconColor: Color {
        if let mode = emergencyMode { return mode.color }
        return isActive ? NuraSafePalette.magenta : NuraSafePalette.textTertiary
    }

    private var iconName: String {
        if let mode = emergencyMode { return mode.icon }
        return isActive ? "bubble.left.fill" : "bubble.left"
    }

    private var preview: String {
        let msgs = conversation.messages
            .filter { $0.role != .system }
            .sorted { $0.timestamp < $1.timestamp }
        return msgs.last?.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? "No messages yet"
    }

    private var dateLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(conversation.updatedAt) {
            return conversation.updatedAt.formatted(.dateTime.hour().minute())
        } else if cal.isDateInYesterday(conversation.updatedAt) {
            return "Yesterday"
        } else {
            return conversation.updatedAt.formatted(.dateTime.month(.abbreviated).day())
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(iconColor.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: isActive ? iconColor.opacity(0.3) : Color.clear, radius: 6)
                    Image(systemName: iconName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(conversation.title)
                            .font(.system(size: 16, weight: isActive ? .semibold : .medium))
                            .foregroundColor(NuraSafePalette.textPrimary)
                            .lineLimit(1)

                        if let mode = emergencyMode {
                            Text(mode.shortLabel)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(mode.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(mode.color.opacity(0.2))
                                        .overlay(Capsule().stroke(mode.color.opacity(0.4), lineWidth: 1))
                                )
                        }

                        Spacer()

                        Text(dateLabel)
                            .font(.system(size: 12))
                            .foregroundColor(NuraSafePalette.textTertiary)
                    }

                    Text(preview)
                        .font(.system(size: 14))
                        .foregroundColor(NuraSafePalette.textSecondary.opacity(0.95))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .glassCard(
                cornerRadius: 16,
                borderOpacity: isActive ? 0.3 : 0.12,
                fillOpacity: isActive ? 0.1 : 0.05
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isActive ? NuraSafePalette.magenta.opacity(0.5) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .shadow(color: isActive ? NuraSafePalette.magenta.opacity(0.2) : Color.clear, radius: 10)
        }
        .buttonStyle(.plain)
    }
}

#endif // os(iOS)

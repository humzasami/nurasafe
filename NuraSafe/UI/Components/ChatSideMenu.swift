// UI/Components/ChatSideMenu.swift
// Left slide-out menu: history, modes, settings — keeps main chrome minimal.

import SwiftUI

#if os(iOS)

struct ChatSideMenu: View {

    @Binding var isPresented: Bool
    var conversationCount: Int
    var hasActiveMode: Bool
    /// Non-nil when an emergency mode is selected (shown in menu subtitle).
    var activeModeTitle: String?
    var onHistory: () -> Void
    var onModes: () -> Void
    var onSettings: () -> Void
    /// Short line under "Profile" (e.g. name or "Your details").
    var profileSubtitle: String
    var onProfile: () -> Void
    var onTerms: () -> Void
    var onPinned: () -> Void

    private let menuWidth: CGFloat = min(UIScreen.main.bounds.width * 0.82, 320)

    /// Single tint for all row SF Symbols (matches Settings / neutral chrome).
    private let menuRowIconTint: Color = Color.white.opacity(0.88)

    var body: some View {
        ZStack(alignment: .leading) {
            if isPresented {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                            isPresented = false
                        }
                    }
                    .transition(.opacity)

                menuPanel
                    .frame(width: menuWidth, alignment: .leading)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: isPresented)
        .allowsHitTesting(isPresented)
    }

    private var menuPanel: some View {
        ZStack(alignment: .leading) {
            NuraSafePalette.backgroundGradient
                .opacity(0.98)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                    sectionTitle("Navigate")

                    menuRow(
                        icon: "clock.arrow.circlepath",
                        title: "Chat history",
                        subtitle: conversationCount > 1 ? "\(conversationCount) conversations" : "Past threads",
                        badge: conversationCount > 1 ? min(conversationCount, 99) : nil
                    ) {
                        onHistory()
                        closeMenu()
                    }

                    menuRow(
                        icon: "slider.horizontal.3",
                        title: "Emergency modes",
                        subtitle: hasActiveMode ? (activeModeTitle ?? "Mode active") : "Choose a scenario",
                        showDot: hasActiveMode
                    ) {
                        onModes()
                        closeMenu()
                    }

                    menuRow(
                        icon: "person.crop.circle",
                        title: "Profile",
                        subtitle: profileSubtitle
                    ) {
                        onProfile()
                        closeMenu()
                    }

                    menuRow(
                        icon: "gearshape.fill",
                        title: "Settings",
                        subtitle: "Model, language, display"
                    ) {
                        onSettings()
                        closeMenu()
                    }

                    menuRow(
                        icon: "pin.fill",
                        title: "Pinned Messages",
                        subtitle: "Saved for quick reference"
                    ) {
                        onPinned()
                        closeMenu()
                    }

                    menuRow(
                        icon: "doc.text",
                        title: "Terms & Conditions",
                        subtitle: "Agreement & privacy summary"
                    ) {
                        onTerms()
                        closeMenu()
                    }

                    Spacer(minLength: 32)
                }
            }
        }
        .frame(width: menuWidth)
        .overlay(alignment: .trailing) {
            LinearGradient(
                colors: [Color.black.opacity(0.35), Color.clear],
                startPoint: .trailing,
                endPoint: .leading
            )
            .frame(width: 14)
            .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .shadow(color: Color.black.opacity(0.45), radius: 24, x: 8, y: 0)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 0) {
                    Image("top-menu")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(height: 46)
                        .frame(maxWidth: menuWidth - 72, alignment: .leading)
                        .accessibilityLabel("NuraSafe")
                    Spacer(minLength: 0)
                }
                Text("Offline · Private")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(NuraSafePalette.textSecondary)
            }

            Spacer(minLength: 0)

            Button {
                closeMenu()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white.opacity(0.45), .white.opacity(0.2))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close menu")
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(NuraSafePalette.textTertiary)
            .tracking(0.8)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
    }

    private func menuRow(
        icon: String,
        title: String,
        subtitle: String,
        badge: Int? = nil,
        showDot: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            HapticService.impact(.light)
            action()
        }) {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(menuRowIconTint)
                        .frame(width: 44, height: 44)

                    if let n = badge {
                        Text("\(n)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(Capsule().fill(NuraSafePalette.violet.opacity(0.92)))
                            .offset(x: 10, y: -8)
                    } else if showDot {
                        Circle()
                            .fill(NuraSafePalette.magenta.opacity(0.95))
                            .frame(width: 8, height: 8)
                            .offset(x: 12, y: -6)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(NuraSafePalette.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(NuraSafePalette.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(NuraSafePalette.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func closeMenu() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            isPresented = false
        }
    }
}

#endif

// UI/Components/ChatInputBar.swift

import SwiftUI

#if os(iOS)

struct ChatInputBar: View {

    @Binding var text: String
    var isGenerating: Bool
    var isModelLoading: Bool = false
    var activeMode: EmergencyScenario? = nil
    var textSize: Double = 15.0
    var onSend: () -> Void
    var onCancel: () -> Void
    var onEmergency: () -> Void

    @FocusState private var isFocused: Bool
    @State private var inputHeight: CGFloat = 36

    private let minHeight: CGFloat = 36
    private let maxHeight: CGFloat = 160
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating && !isModelLoading
    }

    private var accentColor: Color {
        activeMode?.color ?? NuraSafePalette.magenta
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            NuraSafePalette.magenta.opacity(isFocused ? 0.55 : 0.28),
                            NuraSafePalette.violet.opacity(isFocused ? 0.35 : 0.15),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1.5)

            HStack(alignment: .bottom, spacing: 10) {
                emergencyButton

                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholderText)
                            .font(.system(size: textSize))
                            .foregroundColor(NuraSafePalette.textSecondary.opacity(0.9))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .allowsHitTesting(false)
                    }

                    Text(text.isEmpty ? " " : text)
                        .font(.system(size: textSize))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.clear)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        let h = min(max(geo.size.height, minHeight), maxHeight)
                                        if abs(h - inputHeight) > 1 { inputHeight = h }
                                    }
                                    .onChange(of: text) { _, _ in
                                        let h = min(max(geo.size.height, minHeight), maxHeight)
                                        withAnimation(.easeInOut(duration: 0.15)) { inputHeight = h }
                                    }
                            }
                        )

                    TextEditor(text: $text)
                        .font(.system(size: textSize))
                        .foregroundColor(NuraSafePalette.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .frame(height: inputHeight)
                        .focused($isFocused)
                }
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(isFocused ? 0.35 : 0.18),
                                            accentColor.opacity(isFocused ? 0.45 : 0.15)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: isFocused ? 1.5 : 1
                                )
                        )
                        .shadow(
                            color: isFocused ? accentColor.opacity(0.28) : Color.clear,
                            radius: 12, x: 0, y: 0
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: isFocused)

                actionButton
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .background {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                LinearGradient(
                    colors: [
                        NuraSafePalette.deepPurple.opacity(0.35),
                        Color.black.opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private var emergencyButton: some View {
        Button(action: onEmergency) {
            ZStack {
                Circle()
                    .fill(
                        activeMode != nil
                            ? activeMode!.color.opacity(0.22)
                            : Color.white.opacity(0.08)
                    )
                    .frame(width: 42, height: 42)
                    .overlay(
                        Circle().stroke(
                            activeMode != nil
                                ? activeMode!.color.opacity(0.55)
                                : Color.white.opacity(0.2),
                            lineWidth: 1.5
                        )
                    )
                    .shadow(
                        color: activeMode != nil ? activeMode!.color.opacity(0.35) : NuraSafePalette.magenta.opacity(0.15),
                        radius: 8
                    )

                if let mode = activeMode {
                    Image(systemName: mode.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(mode.color)
                } else {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(NuraSafePalette.accentGradientSoft)
                }

                if activeMode != nil {
                    Circle()
                        .fill(activeMode!.color)
                        .frame(width: 9, height: 9)
                        .shadow(color: activeMode!.color, radius: 4)
                        .offset(x: 13, y: -13)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: activeMode?.id)
    }

    @ViewBuilder
    private var actionButton: some View {
        if isModelLoading {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 42, height: 42)
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.75)
                    .tint(NuraSafePalette.magenta)
            }
            .transition(.scale.combined(with: .opacity))
        } else if isGenerating {
            Button(action: onCancel) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.22))
                        .frame(width: 42, height: 42)
                        .overlay(Circle().stroke(Color.red.opacity(0.45), lineWidth: 1.5))
                        .shadow(color: Color.red.opacity(0.35), radius: 8)
                    Image(systemName: "stop.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.red)
                }
            }
            .buttonStyle(.plain)
            .transition(.scale.combined(with: .opacity))
        } else {
            Button(action: {
                guard canSend else { return }
                onSend()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            canSend
                                ? AnyShapeStyle(NuraSafePalette.accentGradient)
                                : AnyShapeStyle(Color.white.opacity(0.1))
                        )
                        .frame(width: 42, height: 42)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(canSend ? 0.3 : 0.12), lineWidth: 1)
                        )
                        .neonGlow(color: canSend ? NuraSafePalette.magenta : .clear, radius: canSend ? 10 : 0)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(canSend ? .white : NuraSafePalette.textTertiary)
                }
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: canSend)
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var placeholderText: String {
        if let mode = activeMode {
            return "Ask about \(mode.shortLabel.lowercased())…"
        }
        return "Message NuraSafe…"
    }
}

#endif // os(iOS)

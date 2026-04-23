// UI/Screens/ModeSelectionView.swift

import SwiftUI

#if os(iOS)

struct ModeSelectionView: View {

    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            VStack(spacing: 0) {
                NuraSafeChromeBar {
                    HStack {
                        Spacer(minLength: 0)
                        Button("Done") { dismiss() }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .buttonStyle(.plain)
                            .frame(minHeight: 38, alignment: .center)
                    }
                }

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(NuraSafePalette.magenta.opacity(0.2))
                                    .frame(width: 76, height: 76)
                                    .blur(radius: 10)
                                Circle()
                                    .fill(NuraSafePalette.accentGradientSoft)
                                    .frame(width: 60, height: 60)
                                    .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                                    .shadow(color: NuraSafePalette.magenta.opacity(0.35), radius: 12, x: 0, y: 2)
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            Text("Emergency Modes")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(NuraSafePalette.textPrimary)

                            Text("Focus every AI response on your specific situation.\nTap again to deactivate.")
                                .font(.system(size: 14))
                                .foregroundColor(NuraSafePalette.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                                .padding(.horizontal, 16)
                        }
                        .padding(.top, 12)

                        // Active mode card
                        if let active = viewModel.activeMode {
                            ActiveModeCard(scenario: active) {
                                viewModel.deactivateMode()
                                dismiss()
                            }
                            .padding(.horizontal, 16)
                        }

                        // Mode grid
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(EmergencyScenario.allCases) { scenario in
                                ModeTile(
                                    scenario: scenario,
                                    isActive: viewModel.activeMode == scenario
                                ) {
                                    if viewModel.activeMode == scenario {
                                        viewModel.deactivateMode()
                                    } else {
                                        viewModel.activateMode(scenario)
                                    }
                                    dismiss()
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Deactivate all
                        if viewModel.activeMode != nil {
                            Button {
                                viewModel.deactivateMode()
                                dismiss()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Deactivate All Modes")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .glassCard(cornerRadius: 14, borderOpacity: 0.1)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.red.opacity(0.35), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 16)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Mode tile

struct ModeTile: View {

    let scenario: EmergencyScenario
    let isActive: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            isPressed = true
            HapticService.impact(.medium)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isPressed = false }
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(scenario.color.opacity(isActive ? 0.3 : 0.15))
                            .frame(width: 46, height: 46)
                            .shadow(color: isActive ? scenario.color.opacity(0.4) : Color.clear, radius: 8)
                        Image(systemName: scenario.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(scenario.color)
                    }
                    Spacer()
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(scenario.color)
                            .shadow(color: scenario.color.opacity(0.5), radius: 4)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(scenario.rawValue)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(NuraSafePalette.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text(isActive ? "Active — tap to deactivate" : "Tap to activate")
                        .font(.system(size: 11))
                        .foregroundColor(isActive ? scenario.color : NuraSafePalette.textSecondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(
                cornerRadius: 18,
                borderOpacity: isActive ? 0.3 : 0.15,
                fillOpacity: isActive ? 0.12 : 0.06
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isActive ? scenario.color.opacity(0.6) : scenario.color.opacity(0.2),
                        lineWidth: isActive ? 1.5 : 1
                    )
            )
            .shadow(color: isActive ? scenario.color.opacity(0.25) : Color.clear, radius: 10)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isActive)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Active mode card

struct ActiveModeCard: View {
    let scenario: EmergencyScenario
    let onDeactivate: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(scenario.color.opacity(0.2))
                    .frame(width: 52, height: 52)
                    .shadow(color: scenario.color.opacity(0.4), radius: 10)
                Image(systemName: scenario.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(scenario.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle().fill(scenario.color).frame(width: 7, height: 7)
                        .shadow(color: scenario.color, radius: 3)
                    Text("Active Mode")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(scenario.color)
                        .textCase(.uppercase)
                        .kerning(0.5)
                }
                Text(scenario.rawValue)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(NuraSafePalette.textPrimary)
                Text(scenario.modeDescription)
                    .font(.system(size: 12))
                    .foregroundColor(NuraSafePalette.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Button(action: onDeactivate) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.3))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .glassCard(cornerRadius: 18, borderOpacity: 0.2)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(scenario.color.opacity(0.4), lineWidth: 1.5)
        )
        .shadow(color: scenario.color.opacity(0.2), radius: 12)
    }
}

#endif // os(iOS)

// UI/Components/ActiveModeBanner.swift

import SwiftUI

#if os(iOS)

struct ActiveModeBanner: View {

    let scenario: EmergencyScenario
    let onTap: () -> Void
    let onDeactivate: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Pulsing live indicator
                ZStack {
                    Circle()
                        .fill(scenario.color.opacity(0.3))
                        .frame(width: 26, height: 26)
                        .scaleEffect(pulse ? 1.5 : 1.0)
                        .opacity(pulse ? 0.0 : 0.6)
                        .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulse)
                    Circle()
                        .fill(scenario.color)
                        .frame(width: 10, height: 10)
                        .shadow(color: scenario.color, radius: 4)
                }

                HStack(spacing: 6) {
                    Image(systemName: scenario.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(scenario.color)
                    Text("\(scenario.rawValue) Mode")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(NuraSafePalette.textPrimary)
                    Text("ACTIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(scenario.color)
                        .kerning(0.5)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(scenario.color.opacity(0.2))
                                .overlay(Capsule().stroke(scenario.color.opacity(0.4), lineWidth: 1))
                        )
                }

                Spacer()

                Button(action: onDeactivate) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                        Text("Off")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(NuraSafePalette.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    LinearGradient(
                        colors: [
                            scenario.color.opacity(0.14),
                            NuraSafePalette.midnight.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [scenario.color.opacity(0.85), scenario.color.opacity(0.15)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1.5),
                    alignment: .bottom
                )
            }
        }
        .buttonStyle(.plain)
        .onAppear { pulse = true }
    }
}

#endif // os(iOS)

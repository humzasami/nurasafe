// UI/Components/EmergencyPanel.swift

import SwiftUI

#if os(iOS)

struct EmergencyPanel: View {

    let onSelect: (EmergencyScenario) -> Void
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.3).background(.ultraThinMaterial)

            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 18)

                // Header
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .shadow(color: .orange.opacity(0.4), radius: 8)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Emergency Mode")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text("Tap your situation for instant guidance")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3)) { isPresented = false }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // Grid
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 12
                ) {
                    ForEach(EmergencyScenario.allCases) { scenario in
                        EmergencyButton(scenario: scenario) {
                            HapticService.notification(.warning)
                            withAnimation(.spring(response: 0.3)) { isPresented = false }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onSelect(scenario)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 36)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: -8)
    }
}

// MARK: - Emergency button

struct EmergencyButton: View {

    let scenario: EmergencyScenario
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isPressed = false }
            action()
        }) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(scenario.color.opacity(0.2))
                        .frame(width: 54, height: 54)
                        .shadow(color: scenario.color.opacity(0.35), radius: 8)
                    Image(systemName: scenario.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(scenario.color)
                }

                Text(scenario.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .glassCard(cornerRadius: 16, borderOpacity: 0.15)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(scenario.color.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Emergency strip

struct EmergencyStrip: View {

    let onTap: (EmergencyScenario) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(EmergencyScenario.allCases) { scenario in
                    Button {
                        HapticService.notification(.warning)
                        onTap(scenario)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: scenario.icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(scenario.color)
                            Text(scenario.shortLabel)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(scenario.color.opacity(0.15))
                                .overlay(Capsule().stroke(scenario.color.opacity(0.35), lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

#endif // os(iOS)

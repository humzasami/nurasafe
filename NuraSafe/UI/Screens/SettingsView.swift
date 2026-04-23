// UI/Screens/SettingsView.swift

import SwiftUI

#if os(iOS)

struct SettingsView: View {

    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    /// Row icons: neutral white on dark glass (avoids busy pink gradients).
    private var settingsRowIconColor: Color { Color.white.opacity(0.88) }

    private let settingsRowIconPointSize: CGFloat = 16

    @ViewBuilder
    private func settingsIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: settingsRowIconPointSize, weight: .regular))
            .foregroundStyle(settingsRowIconColor)
    }

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            VStack(spacing: 0) {
                NuraSafeChromeBar {
                    HStack {
                        Spacer(minLength: 0)
                        Button("Done") {
                            viewModel.applyChanges()
                            dismiss()
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .buttonStyle(.plain)
                        .frame(minHeight: 38, alignment: .center)
                    }
                }

            // Use List (inset grouped) instead of Form to avoid iOS 18+ “variant selector cell index” Form bugs.
            List {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.08))
                                    .frame(width: 72, height: 72)
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.22),
                                                NuraSafePalette.violet.opacity(0.35)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                    .overlay(Circle().stroke(Color.white.opacity(0.28), lineWidth: 1))
                                    .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 4)
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            Text("Settings")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(NuraSafePalette.textPrimary)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("AI Model") {
                    sliderRow(
                        label: "Max Response Length",
                        icon: "text.alignleft",
                        value: $viewModel.maxTokens,
                        range: 128...1024,
                        step: 64,
                        displayValue: "\(Int(viewModel.maxTokens)) tokens"
                    )
                    sliderRow(
                        label: "Response Creativity",
                        icon: "dial.medium",
                        value: $viewModel.temperature,
                        range: 0.1...1.0,
                        step: 0.05,
                        displayValue: String(format: "%.2f", viewModel.temperature),
                        minLabel: "Precise",
                        maxLabel: "Creative"
                    )
                }

                Section("Preferences") {
                    pickerRow(
                        label: "Response Language",
                        icon: "globe",
                        selection: $viewModel.preferredLanguage,
                        options: AppSettings.supportedLanguages
                    )
                    sliderRow(
                        label: "Text Size",
                        icon: "textformat.size",
                        value: $viewModel.textSize,
                        range: 12...24,
                        step: 1,
                        displayValue: "\(Int(viewModel.textSize)) pt",
                        minLabel: "Small",
                        maxLabel: "Large"
                    )
                    toggleRow(
                        label: "Haptic Feedback",
                        icon: "hand.tap",
                        isOn: $viewModel.hapticFeedback
                    )
                }

                Section("Storage") {
                    HStack {
                        Label {
                            Text("Storage Used")
                                .font(.system(size: 15, weight: .medium))
                        } icon: {
                            settingsIcon("internaldrive")
                        }
                        Spacer()
                        Text(viewModel.storageInfo)
                            .font(.system(size: 13))
                            .foregroundColor(NuraSafePalette.textSecondary)
                    }
                    Button {
                        viewModel.showClearConfirmation = true
                    } label: {
                        HStack {
                            Label {
                                Text("Clear Chat History")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(NuraSafePalette.textPrimary)
                            } icon: {
                                settingsIcon("trash")
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog(
                        "Clear all chat history?",
                        isPresented: $viewModel.showClearConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Clear History", role: .destructive) { viewModel.clearHistory() }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This cannot be undone.")
                    }
                }

                Section("About") {
                    aboutRow(label: "Version", icon: "info.circle", value: "1.0.0")
                    aboutRow(label: "AI Model", icon: "cpu", value: "Qwen 2.5 3B Instruct")
                    HStack {
                        Label {
                            Text("Connectivity")
                                .font(.system(size: 15, weight: .medium))
                        } icon: {
                            settingsIcon("wifi.slash")
                        }
                        Spacer()
                        Text("Fully Offline")
                            .font(.system(size: 13))
                            .foregroundColor(.green)
                    }
                }

                Section("Privacy") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            settingsIcon("lock.shield")
                            Text("No Data Collected")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(NuraSafePalette.textPrimary)
                        }
                        Text(TermsOfServiceContent.privacyPolicySummary)
                            .font(.system(size: 13))
                            .foregroundColor(NuraSafePalette.textSecondary)
                            .lineSpacing(3)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Text("NuraSafe provides general emergency guidance only. It is not a substitute for professional emergency services. Always call emergency services (112/999 or your local equivalent) in any life-threatening situation.")
                        .font(.system(size: 12))
                        .foregroundColor(NuraSafePalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .tint(NuraSafePalette.violet.opacity(0.85))
            .alert("History Cleared", isPresented: $viewModel.storageCleared) {
                Button("OK", role: .cancel) {}
            }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Row helpers

    @ViewBuilder
    private func sliderRow(
        label: String,
        icon: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        displayValue: String,
        minLabel: String? = nil,
        maxLabel: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label {
                    Text(label)
                        .font(.system(size: 15, weight: .medium))
                } icon: {
                    settingsIcon(icon)
                }
                Spacer()
                Text(displayValue)
                    .font(.system(size: 13))
                    .foregroundColor(NuraSafePalette.textSecondary)
            }

            NuraSafeGradientSlider(value: value, range: range, step: step)

            if let min = minLabel, let max = maxLabel {
                HStack {
                    Text(min).font(.system(size: 11)).foregroundColor(Color(.tertiaryLabel))
                    Spacer()
                    Text(max).font(.system(size: 11)).foregroundColor(Color(.tertiaryLabel))
                }
            }
        }
    }

    @ViewBuilder
    private func toggleRow(label: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
            } icon: {
                settingsIcon(icon)
            }
        }
        .tint(NuraSafePalette.violet.opacity(0.92))
    }

    @ViewBuilder
    private func pickerRow(
        label: String,
        icon: String,
        selection: Binding<String>,
        options: [String]
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Label {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
            } icon: {
                settingsIcon(icon)
            }

            Spacer(minLength: 8)

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection.wrappedValue = option
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selection.wrappedValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(NuraSafePalette.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(NuraSafePalette.textTertiary)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
                .fixedSize(horizontal: true, vertical: false)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Choose response language")
    }

    @ViewBuilder
    private func aboutRow(
        label: String,
        icon: String,
        value: String,
        valueColor: Color = NuraSafePalette.textSecondary
    ) -> some View {
        HStack {
            Label {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
            } icon: {
                settingsIcon(icon)
            }
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(valueColor)
        }
    }
}

#endif // os(iOS)

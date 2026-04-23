// UI/Screens/ProfileView.swift

import SwiftUI

#if os(iOS)

struct ProfileView: View {

    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showCountryPicker = false

    private var settingsRowIconColor: Color { Color.white.opacity(0.88) }

    private let iconSize: CGFloat = 16

    @ViewBuilder
    private func rowIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: iconSize, weight: .regular))
            .foregroundStyle(settingsRowIconColor)
    }

    private var countrySummary: String {
        if viewModel.countryRegionCode.isEmpty {
            return "Select country"
        }
        return CountriesCatalog.displayName(for: viewModel.countryRegionCode)
    }

    private var countrySummaryStyle: Color {
        viewModel.countryRegionCode.isEmpty ? NuraSafePalette.textTertiary : NuraSafePalette.textPrimary
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
                                                    NuraSafePalette.magenta.opacity(0.35)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 56, height: 56)
                                        .overlay(Circle().stroke(Color.white.opacity(0.28), lineWidth: 1))
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                Text("Profile")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(NuraSafePalette.textPrimary)
                            }
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        HStack(spacing: 12) {
                            rowIcon("person.fill")
                            TextField("Your name", text: $viewModel.displayName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(NuraSafePalette.textPrimary)
                                .textContentType(.name)
                        }

                        Button {
                            HapticService.impact(.light)
                            showCountryPicker = true
                        } label: {
                            HStack(spacing: 12) {
                                rowIcon("globe.americas.fill")
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Country of residence")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(NuraSafePalette.textTertiary)
                                        .textCase(.uppercase)
                                        .tracking(0.3)
                                    HStack(spacing: 8) {
                                        if !viewModel.countryRegionCode.isEmpty {
                                            Text(CountriesCatalog.flagEmoji(for: viewModel.countryRegionCode))
                                                .font(.system(size: 20))
                                        }
                                        Text(countrySummary)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(countrySummaryStyle)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(NuraSafePalette.textTertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    } header: {
                        Text("About you")
                            .foregroundStyle(NuraSafePalette.textTertiary)
                    }

                    Section {
                        ForEach($viewModel.emergencyContacts) { $contact in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    rowIcon("person.badge.shield.checkmark.fill")
                                    TextField("Name", text: $contact.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(NuraSafePalette.textPrimary)
                                        .textContentType(.name)
                                }
                                HStack(spacing: 12) {
                                    rowIcon("phone.fill")
                                    TextField("Phone number", text: $contact.phoneNumber)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(NuraSafePalette.textPrimary)
                                        .keyboardType(.phonePad)
                                        .textContentType(.telephoneNumber)
                                }
                                HStack(spacing: 12) {
                                    rowIcon("tag.fill")
                                    TextField("Label (optional)", text: $contact.relationship)
                                        .font(.system(size: 14))
                                        .foregroundStyle(NuraSafePalette.textSecondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: viewModel.removeContact)

                        Button {
                            HapticService.impact(.light)
                            viewModel.addContact()
                        } label: {
                            Label("Add emergency contact", systemImage: "plus.circle.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(NuraSafePalette.magenta)
                        }
                    } header: {
                        Text("Emergency contacts")
                            .foregroundStyle(NuraSafePalette.textTertiary)
                    } footer: {
                        Text("Stored only on this device. Use for your own reference during emergencies — calling still uses the Phone app.")
                            .font(.system(size: 12))
                            .foregroundStyle(NuraSafePalette.textTertiary)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .tint(NuraSafePalette.violet.opacity(0.85))
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerSheet(selectedRegionCode: $viewModel.countryRegionCode)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

#endif

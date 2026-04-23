// UI/Screens/CountryPickerSheet.swift
// Searchable ISO country list — matches NuraSafe glass / gradient aesthetic.

import SwiftUI

#if os(iOS)

struct CountryPickerSheet: View {

    @Binding var selectedRegionCode: String
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    private var selectedUpper: String {
        selectedRegionCode.uppercased()
    }

    private var filtered: [(code: String, name: String)] {
        let all = CountriesCatalog.sortedRegions
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return all }
        let lower = q.lowercased()
        return all.filter {
            $0.name.lowercased().contains(lower) || $0.code.lowercased().contains(lower)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedMeshBackground()

                ScrollView {
                    LazyVStack(spacing: 10) {
                        if !selectedUpper.isEmpty {
                            clearSelectionButton
                        }

                        ForEach(filtered, id: \.code) { item in
                            countryCard(
                                code: item.code,
                                name: item.name,
                                isSelected: item.code == selectedUpper
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Country of residence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search countries"
            )
            .tint(NuraSafePalette.magenta)
        }
        .preferredColorScheme(.dark)
    }

    private var clearSelectionButton: some View {
        Button {
            HapticService.impact(.light)
            selectedRegionCode = ""
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(NuraSafePalette.textSecondary)
                Text("Clear selection")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(NuraSafePalette.textSecondary)
                Spacer()
            }
            .padding(14)
            .glassCard(cornerRadius: 14, borderOpacity: 0.16, fillOpacity: 0.06)
        }
        .buttonStyle(.plain)
    }

    private func countryCard(code: String, name: String, isSelected: Bool) -> some View {
        Button {
            HapticService.impact(.light)
            selectedRegionCode = code
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Text(CountriesCatalog.flagEmoji(for: code))
                    .font(.system(size: 30))
                    .frame(width: 44, alignment: .center)

                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(NuraSafePalette.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(code)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(NuraSafePalette.textTertiary)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(NuraSafePalette.magenta)
                        .shadow(color: NuraSafePalette.magenta.opacity(0.4), radius: 6)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(NuraSafePalette.textTertiary)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: isSelected
                                ? [NuraSafePalette.magenta.opacity(0.55), NuraSafePalette.violet.opacity(0.35)]
                                : [Color.white.opacity(0.14), Color.white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(color: isSelected ? NuraSafePalette.magenta.opacity(0.12) : Color.clear, radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#endif

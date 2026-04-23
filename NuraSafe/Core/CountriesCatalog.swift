// Core/CountriesCatalog.swift
// Full ISO region list with localized display names (follows system locale).

import Foundation

enum CountriesCatalog {

    /// Sorted by localized country name for the current locale.
    static let sortedRegions: [(code: String, name: String)] = {
        Locale.isoRegionCodes.compactMap { code -> (String, String)? in
            guard let name = Locale.current.localizedString(forRegionCode: code), !name.isEmpty else {
                return nil
            }
            return (code, name)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }()

    static func displayName(for regionCode: String) -> String {
        let c = regionCode.uppercased()
        guard c.count == 2 else { return regionCode }
        return Locale.current.localizedString(forRegionCode: c) ?? c
    }

    /// Regional indicator flag emoji from ISO 3166-1 alpha-2 (e.g. AE → 🇦🇪).
    static func flagEmoji(for regionCode: String) -> String {
        let upper = regionCode.uppercased()
        guard upper.count == 2 else { return "🌐" }
        let base: UInt32 = 127397
        var scalars = String.UnicodeScalarView()
        for scalar in upper.unicodeScalars {
            guard let regional = UnicodeScalar(base + scalar.value) else { return "🌐" }
            scalars.append(regional)
        }
        return String(scalars)
    }
}

// Models/UserProfile.swift

import Foundation

struct EmergencyContact: Identifiable, Codable, Equatable {
    var id: UUID
    /// Contact name (e.g. family member).
    var name: String
    /// Phone number as the user prefers to dial (include country code if needed).
    var phoneNumber: String
    /// Optional label: Partner, Parent, Neighbor, etc.
    var relationship: String

    init(
        id: UUID = UUID(),
        name: String = "",
        phoneNumber: String = "",
        relationship: String = ""
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.relationship = relationship
    }
}

struct UserProfile: Codable, Equatable {
    var displayName: String
    /// ISO 3166-1 alpha-2 region code (e.g. "AE"). Empty if unset.
    var countryRegionCode: String
    var emergencyContacts: [EmergencyContact]

    static let empty = UserProfile(displayName: "", countryRegionCode: "", emergencyContacts: [])

    init(displayName: String, countryRegionCode: String, emergencyContacts: [EmergencyContact]) {
        self.displayName = displayName
        self.countryRegionCode = Self.normalizeRegionCode(countryRegionCode)
        self.emergencyContacts = emergencyContacts
    }

    enum CodingKeys: String, CodingKey {
        case displayName
        case country
        case countryRegionCode
        case emergencyContacts
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try c.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        emergencyContacts = try c.decodeIfPresent([EmergencyContact].self, forKey: .emergencyContacts) ?? []

        if let code = try c.decodeIfPresent(String.self, forKey: .countryRegionCode) {
            countryRegionCode = Self.normalizeRegionCode(code)
        } else if let legacy = try c.decodeIfPresent(String.self, forKey: .country) {
            countryRegionCode = Self.normalizeRegionCode(legacy)
        } else {
            countryRegionCode = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(displayName, forKey: .displayName)
        try c.encode(countryRegionCode, forKey: .countryRegionCode)
        try c.encode(emergencyContacts, forKey: .emergencyContacts)
    }

    private static func normalizeRegionCode(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard trimmed.count == 2, Locale.isoRegionCodes.contains(trimmed) else { return "" }
        return trimmed
    }
}

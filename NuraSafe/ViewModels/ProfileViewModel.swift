// ViewModels/ProfileViewModel.swift

import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var displayName: String
    @Published var countryRegionCode: String
    @Published var emergencyContacts: [EmergencyContact]

    private let store: UserProfileStore

    init(store: UserProfileStore = .shared) {
        self.store = store
        let p = store.profile
        displayName = p.displayName
        countryRegionCode = p.countryRegionCode
        emergencyContacts = p.emergencyContacts.isEmpty
            ? [EmergencyContact()]
            : p.emergencyContacts
    }

    func applyChanges() {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = countryRegionCode.uppercased()
        let normalizedCode: String = (code.count == 2 && Locale.isoRegionCodes.contains(code)) ? code : ""
        let contacts = emergencyContacts.compactMap { c -> EmergencyContact? in
            let n = c.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let ph = c.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            let rel = c.relationship.trimmingCharacters(in: .whitespacesAndNewlines)
            if n.isEmpty && ph.isEmpty && rel.isEmpty { return nil }
            return EmergencyContact(id: c.id, name: n, phoneNumber: ph, relationship: rel)
        }
        store.replace(with: UserProfile(
            displayName: trimmedName,
            countryRegionCode: normalizedCode,
            emergencyContacts: contacts
        ))
    }

    func addContact() {
        emergencyContacts.append(EmergencyContact())
    }

    func removeContact(at offsets: IndexSet) {
        for index in offsets.sorted().reversed() where emergencyContacts.indices.contains(index) {
            emergencyContacts.remove(at: index)
        }
        if emergencyContacts.isEmpty {
            emergencyContacts = [EmergencyContact()]
        }
    }
}

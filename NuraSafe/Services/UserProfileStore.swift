// Services/UserProfileStore.swift
// Persists profile locally (UserDefaults JSON). No network.

import Foundation
import Combine

@MainActor
final class UserProfileStore: ObservableObject {

    static let shared = UserProfileStore()

    @Published private(set) var profile: UserProfile

    private enum Keys {
        static let profile = "ns_userProfile_v1"
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: Keys.profile),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = decoded
        } else {
            profile = .empty
        }
    }

    func replace(with newProfile: UserProfile) {
        profile = newProfile
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: Keys.profile)
        }
    }
}

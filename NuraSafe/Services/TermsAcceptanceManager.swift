// Services/TermsAcceptanceManager.swift

import Foundation
import Combine

@MainActor
final class TermsAcceptanceManager: ObservableObject {

    static let shared = TermsAcceptanceManager()

    /// True when the user has accepted the current `TermsOfServiceContent.version`.
    @Published private(set) var hasAcceptedCurrentTerms: Bool

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let acceptedVersion = "ns_termsAcceptedVersion"
        static let agreedSnapshot = "ns_termsAgreedSnapshot"
        static let agreedAt = "ns_termsAgreedAt"
    }

    private init() {
        hasAcceptedCurrentTerms = Self.computeHasAccepted(defaults: UserDefaults.standard)
    }

    private static func computeHasAccepted(defaults: UserDefaults) -> Bool {
        let v = defaults.string(forKey: Keys.acceptedVersion)
        let snapshot = defaults.string(forKey: Keys.agreedSnapshot) ?? ""
        return v == TermsOfServiceContent.version && !snapshot.isEmpty
    }

    /// Full text the user agreed to (snapshot at acceptance). Nil if none stored.
    var agreedSnapshotText: String? {
        let s = defaults.string(forKey: Keys.agreedSnapshot) ?? ""
        return s.isEmpty ? nil : s
    }

    /// When the user last accepted, if recorded.
    var agreedAt: Date? {
        let t = defaults.double(forKey: Keys.agreedAt)
        return t > 0 ? Date(timeIntervalSince1970: t) : nil
    }

    /// Version string stored at acceptance (matches `TermsOfServiceContent.version` for current terms).
    var agreedVersionString: String? {
        defaults.string(forKey: Keys.acceptedVersion)
    }

    func accept() {
        defaults.set(TermsOfServiceContent.version, forKey: Keys.acceptedVersion)
        defaults.set(TermsOfServiceContent.fullText, forKey: Keys.agreedSnapshot)
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.agreedAt)
        hasAcceptedCurrentTerms = Self.computeHasAccepted(defaults: defaults)
    }
}

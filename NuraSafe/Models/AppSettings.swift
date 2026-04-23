// Models/AppSettings.swift

import Foundation
import Combine

@MainActor
final class AppSettings: ObservableObject {

    @MainActor static let shared = AppSettings()

    static let supportedLanguages = [
        "English",
        "Arabic",
        "Chinese (Simplified)",
        "Chinese (Traditional)",
        "French",
        "German",
        "Hindi",
        "Japanese",
        "Korean",
        "Persian (Farsi)",
        "Portuguese",
        "Russian",
        "Spanish",
        "Turkish",
        "Urdu"
    ]

    @Published var maxTokens: Int {
        didSet { UserDefaults.standard.set(maxTokens, forKey: Keys.maxTokens) }
    }

    @Published var temperature: Double {
        didSet { UserDefaults.standard.set(temperature, forKey: Keys.temperature) }
    }

    @Published var hapticFeedback: Bool {
        didSet { UserDefaults.standard.set(hapticFeedback, forKey: Keys.hapticFeedback) }
    }

    @Published var streamingEnabled: Bool {
        didSet { UserDefaults.standard.set(streamingEnabled, forKey: Keys.streamingEnabled) }
    }

    /// The currently active emergency mode. nil = general mode (no filter).
    @Published var activeMode: EmergencyScenario? {
        didSet {
            UserDefaults.standard.set(activeMode?.rawValue, forKey: Keys.activeMode)
        }
    }

    @Published var preferredLanguage: String {
        didSet {
            UserDefaults.standard.set(preferredLanguage, forKey: Keys.preferredLanguage)
        }
    }

    @Published var textSize: Double {
        didSet {
            UserDefaults.standard.set(textSize, forKey: Keys.textSize)
        }
    }

    private enum Keys {
        static let maxTokens        = "ns_maxTokens"
        static let temperature      = "ns_temperature"
        static let hapticFeedback   = "ns_hapticFeedback"
        static let streamingEnabled = "ns_streamingEnabled"
        static let activeMode       = "ns_activeMode"
        static let preferredLanguage = "ns_preferredLanguage"
        static let textSize         = "ns_textSize"
    }

    private init() {
        let defaults = UserDefaults.standard
        self.maxTokens        = defaults.integer(forKey: Keys.maxTokens).nonZero ?? 512
        self.temperature      = defaults.double(forKey: Keys.temperature).nonZero ?? 0.7
        self.hapticFeedback   = defaults.object(forKey: Keys.hapticFeedback) as? Bool ?? true
        self.streamingEnabled = defaults.object(forKey: Keys.streamingEnabled) as? Bool ?? true
        self.preferredLanguage = defaults.string(forKey: Keys.preferredLanguage) ?? "English"
        self.textSize         = defaults.double(forKey: Keys.textSize).nonZero ?? 15.0

        if let raw = defaults.string(forKey: Keys.activeMode) {
            self.activeMode = EmergencyScenario(rawValue: raw)
        } else {
            self.activeMode = nil
        }
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}

private extension Double {
    var nonZero: Double? { self == 0.0 ? nil : self }
}

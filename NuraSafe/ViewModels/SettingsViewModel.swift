// ViewModels/SettingsViewModel.swift

import Foundation
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {

    @Published var maxTokens: Double
    @Published var temperature: Double
    @Published var hapticFeedback: Bool
    @Published var streamingEnabled: Bool
    @Published var preferredLanguage: String
    @Published var textSize: Double
    @Published var showClearConfirmation: Bool = false
    @Published var storageCleared: Bool = false

    private let settings: AppSettings
    private let storage: StorageService

    init(settings: AppSettings? = nil, storage: StorageService? = nil) {
        self.settings = settings ?? .shared
        self.storage = storage ?? .shared
        let s = self.settings
        self.maxTokens       = Double(s.maxTokens)
        self.temperature     = s.temperature
        self.hapticFeedback  = s.hapticFeedback
        self.streamingEnabled = s.streamingEnabled
        self.preferredLanguage = s.preferredLanguage
        self.textSize        = s.textSize
    }

    func applyChanges() {
        settings.maxTokens        = Int(maxTokens)
        settings.temperature      = temperature
        settings.hapticFeedback   = hapticFeedback
        settings.streamingEnabled = streamingEnabled
        settings.preferredLanguage = preferredLanguage
        settings.textSize         = textSize
    }

    func clearHistory() {
        try? storage.clearHistory()
        storageCleared = true
    }

    var storageInfo: String {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let url = urls.first else { return "Unknown" }
        let size = directorySize(url)
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    private func directorySize(_ url: URL) -> Int {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total = 0
        for case let fileURL as URL in enumerator {
            total += (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        }
        return total
    }
}

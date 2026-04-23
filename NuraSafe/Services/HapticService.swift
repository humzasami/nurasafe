// Services/HapticService.swift
// Haptic feedback — iOS only. All calls are no-ops on macOS.

import Foundation

enum HapticService {

    enum ImpactStyle { case light, medium, heavy }
    enum NotificationType { case success, warning, error }

    @MainActor
    static func impact(_ style: ImpactStyle = .medium) {
        guard AppSettings.shared.hapticFeedback else { return }
        #if canImport(UIKit) && !os(macOS)
        _impact(style)
        #endif
    }

    @MainActor
    static func notification(_ type: NotificationType) {
        guard AppSettings.shared.hapticFeedback else { return }
        #if canImport(UIKit) && !os(macOS)
        _notification(type)
        #endif
    }

    @MainActor
    static func selection() {
        guard AppSettings.shared.hapticFeedback else { return }
        #if canImport(UIKit) && !os(macOS)
        _selection()
        #endif
    }
}

#if canImport(UIKit) && !os(macOS)
import UIKit

private extension HapticService {

    static func _impact(_ style: ImpactStyle) {
        let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case .light:  uiStyle = .light
        case .medium: uiStyle = .medium
        case .heavy:  uiStyle = .heavy
        }
        UIImpactFeedbackGenerator(style: uiStyle).impactOccurred()
    }

    static func _notification(_ type: NotificationType) {
        let uiType: UINotificationFeedbackGenerator.FeedbackType
        switch type {
        case .success: uiType = .success
        case .warning: uiType = .warning
        case .error:   uiType = .error
        }
        UINotificationFeedbackGenerator().notificationOccurred(uiType)
    }

    static func _selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
#endif

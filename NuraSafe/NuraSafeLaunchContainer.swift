// NuraSafeLaunchContainer.swift
// First launch: brand splash → terms (once) → chat. Later launches skip splash.

import SwiftUI
import SwiftData

#if os(iOS)

private enum LaunchStorage {
    static let hasSeenBrandSplash = "ns_hasSeenBrandSplash"
}

struct NuraSafeLaunchContainer: View {

    @StateObject private var settings = AppSettings.shared
    @ObservedObject private var termsAcceptance = TermsAcceptanceManager.shared

    @AppStorage(LaunchStorage.hasSeenBrandSplash) private var hasSeenBrandSplash = false

    var body: some View {
        Group {
            if !hasSeenBrandSplash {
                BrandSplashView {
                    hasSeenBrandSplash = true
                }
            } else if !termsAcceptance.hasAcceptedCurrentTerms {
                TermsAcceptanceGateView()
                    .environmentObject(termsAcceptance)
                    .preferredColorScheme(.dark)
            } else {
                ChatView()
                    .environmentObject(settings)
                    .environmentObject(termsAcceptance)
                    .modelContainer(StorageService.shared.container)
                    .preferredColorScheme(.dark)
            }
        }
    }
}

#endif

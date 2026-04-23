// UI/Components/NuraSafeNavigationChrome.swift
// Custom top bars avoid iOS 26+ UIBarButtonItem “liquid glass” circular chrome on toolbar items.

import SwiftUI

#if os(iOS)

/// Frosted strip matching the old nav bar; buttons are plain SwiftUI (no bar button bubbles).
struct NuraSafeChromeBar<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    LinearGradient(
                        colors: [NuraSafePalette.deepPurple.opacity(0.35), Color.black.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
            }
    }
}

#endif

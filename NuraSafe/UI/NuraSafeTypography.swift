// UI/NuraSafeTypography.swift
// Brand wordmark: Eurostile Bold when bundled; otherwise bold rounded system UI.

import SwiftUI
import UIKit

#if os(iOS)

enum NuraSafeTypography {

    /// Primary title “NuraSafe” — Eurostile Bold at 48pt when a matching font is in the app target.
    /// Add `Eurostile` / `Eurostile-Bold` `.otf` or `.ttf` to the target and list under “Fonts provided by application” in Info if needed.
    static func wordmarkBold(size: CGFloat = 48) -> Font {
        for name in eurostileBoldPostScriptNames {
            if UIFont(name: name, size: size) != nil {
                return Font.custom(name, size: size)
            }
        }
        return Font.system(size: size, weight: .bold, design: .rounded)
    }

    /// PostScript names to try (depends on which Eurostile files you embed).
    private static let eurostileBoldPostScriptNames: [String] = [
        "Eurostile-Bold",
        "EurostileBold",
        "Eurostile-BoldExtended",
        "EurostileBoldExtended",
        "Eurostile-ExtendedBold"
    ]
}

#endif

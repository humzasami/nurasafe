// UI/NuraSafeTheme.swift
// Glassmorphism + magenta / violet palette (inspired by modern AI chat UIs).

import SwiftUI

// MARK: - Palette

enum NuraSafePalette {
    /// Deep purple at top of screen
    static let deepPurple = Color(red: 0.14, green: 0.06, blue: 0.26)
    /// Near-black base
    static let midnight = Color(red: 0.04, green: 0.03, blue: 0.09)
    /// Bright magenta (highlights, glows)
    static let magenta = Color(red: 1.0, green: 0.28, blue: 0.62)
    /// Electric violet
    static let violet = Color(red: 0.55, green: 0.28, blue: 1.0)
    /// Deep violet for gradient stops
    static let deepViolet = Color(red: 0.22, green: 0.08, blue: 0.42)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                deepPurple,
                Color(red: 0.08, green: 0.04, blue: 0.14),
                midnight,
                Color.black
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Soft radial glow (pink / violet) behind content
    static func radialGlow(opacity: Double = 0.35) -> some View {
        RadialGradient(
            colors: [
                magenta.opacity(opacity * 0.55),
                violet.opacity(opacity * 0.25),
                Color.clear
            ],
            center: .init(x: 0.5, y: 0.12),
            startRadius: 20,
            endRadius: 420
        )
        .allowsHitTesting(false)
    }

    /// Primary CTA / user bubble — magenta → violet
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [magenta, violet, deepViolet],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Smaller controls (icons, chips)
    static var accentGradientSoft: LinearGradient {
        LinearGradient(
            colors: [magenta.opacity(0.95), violet.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var glassBorder: Color { Color.white.opacity(0.18) }
    static var glassBorderStrong: Color { Color.white.opacity(0.28) }
    static var glassFill: Color { Color.white.opacity(0.06) }
    static var textPrimary: Color { Color.white }
    static var textSecondary: Color { Color.white.opacity(0.62) }
    static var textTertiary: Color { Color.white.opacity(0.38) }
}

// MARK: - Background

/// Full-screen mesh-style backdrop: purple-black gradient + soft magenta glow.
struct AnimatedMeshBackground: View {
    var body: some View {
        ZStack {
            NuraSafePalette.backgroundGradient
            NuraSafePalette.radialGlow(opacity: 0.42)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Glass card

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    /// Extra blur strength (material already blurs)
    var borderOpacity: Double = 0.2
    var fillOpacity: Double = 0.08

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(fillOpacity))
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35),
                                    Color.white.opacity(borderOpacity),
                                    NuraSafePalette.violet.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 10)
                .shadow(color: NuraSafePalette.magenta.opacity(0.08), radius: 24, x: 0, y: 0)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, borderOpacity: Double = 0.2, fillOpacity: Double = 0.08) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, borderOpacity: borderOpacity, fillOpacity: fillOpacity))
    }

    func neonGlow(color: Color = NuraSafePalette.magenta, radius: CGFloat = 12) -> some View {
        self
            .shadow(color: color.opacity(0.45), radius: radius * 0.6, x: 0, y: 0)
            .shadow(color: NuraSafePalette.violet.opacity(0.25), radius: radius, x: 0, y: 4)
    }

    /// Compact glass surface for bubbles & input (no heavy outer shadow).
    func glassSurface(cornerRadius: CGFloat, borderOpacity: Double = 0.22) -> some View {
        background(
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(borderOpacity), lineWidth: 1)
            }
        )
    }
}

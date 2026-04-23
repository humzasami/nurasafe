// UI/Screens/BrandSplashView.swift
// Full-screen brand splash (Picture 2) — shown once after install; Continue leads to terms if needed.

import SwiftUI
import UIKit

#if os(iOS)

struct BrandSplashView: View {

    /// Called when the user taps Continue (terms are shown next if not yet accepted).
    var onFinished: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            AnimatedMeshBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 28)

                // Logo shifted slightly right so it lines up with the Continue button column.
                HStack(alignment: .center, spacing: 0) {
                    Spacer(minLength: 20)
                    Image("BrandSplash")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(maxWidth: min(UIScreen.main.bounds.width - 56, 340))
                        .shadow(color: Color.black.opacity(0.35), radius: 24, y: 12)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                        .accessibilityLabel("NuraSafe, Your Private, Offline AI")
                    Spacer(minLength: 12)
                }
                .padding(.leading, 8)

                Spacer()

                Button {
                    HapticService.impact(.light)
                    onFinished()
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(NuraSafePalette.violet.opacity(0.92))
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)
                .padding(.bottom, 36)
                .opacity(appeared ? 1 : 0)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) {
                appeared = true
            }
        }
    }
}

#endif

// UI/Screens/TermsAcceptanceGateView.swift
// Shown on launch until the user accepts the current terms version.

import SwiftUI

#if os(iOS)

struct TermsAcceptanceGateView: View {

    @EnvironmentObject private var termsAcceptance: TermsAcceptanceManager
    @State private var showDeclineNotice = false

    var body: some View {
        ZStack {
            AnimatedMeshBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.shield")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(NuraSafePalette.accentGradientSoft)
                        .padding(.top, 8)
                    Text("Terms & Conditions")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(NuraSafePalette.textPrimary)
                    Text("Please read and accept to continue")
                        .font(.system(size: 14))
                        .foregroundStyle(NuraSafePalette.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                ScrollView {
                    Text(TermsOfServiceContent.fullText)
                        .font(.system(size: 14))
                        .foregroundStyle(NuraSafePalette.textPrimary.opacity(0.92))
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 16)
                }

                VStack(spacing: 12) {
                    Button {
                        HapticService.impact(.medium)
                        termsAcceptance.accept()
                    } label: {
                        Text("I Agree")
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

                    Button {
                        showDeclineNotice = true
                    } label: {
                        Text("I do not agree")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(NuraSafePalette.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.5), Color.black.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .alert("Agreement required", isPresented: $showDeclineNotice) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You need to accept the Terms & Conditions to use NuraSafe. If you do not agree, please close the app.")
        }
    }
}

#endif

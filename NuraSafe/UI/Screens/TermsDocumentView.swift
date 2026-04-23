// UI/Screens/TermsDocumentView.swift
// Read-only copy of the terms the user agreed to (from storage).

import SwiftUI

#if os(iOS)

struct TermsDocumentView: View {

    @EnvironmentObject private var termsAcceptance: TermsAcceptanceManager
    @Environment(\.dismiss) private var dismiss

    private var bodyText: String {
        termsAcceptance.agreedSnapshotText ?? TermsOfServiceContent.fullText
    }

    private var dateSubtitle: String? {
        guard let d = termsAcceptance.agreedAt else { return nil }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return "Accepted \(f.string(from: d))"
    }

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            VStack(spacing: 0) {
                NuraSafeChromeBar {
                    HStack {
                        Text("Terms & Conditions")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Button("Done") { dismiss() }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .buttonStyle(.plain)
                            .frame(minHeight: 38, alignment: .center)
                    }
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if let sub = dateSubtitle {
                            Text(sub)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(NuraSafePalette.textSecondary)
                        }
                        Text("Version \(termsAcceptance.agreedVersionString ?? TermsOfServiceContent.version)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(NuraSafePalette.textTertiary)

                        Text(bodyText)
                            .font(.system(size: 14))
                            .foregroundStyle(NuraSafePalette.textPrimary.opacity(0.92))
                            .lineSpacing(5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#endif

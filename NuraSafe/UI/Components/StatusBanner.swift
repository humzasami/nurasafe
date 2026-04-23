// UI/Components/StatusBanner.swift

import SwiftUI

#if os(iOS)

struct StatusBanner: View {
    let message: String
    let style: BannerStyle

    enum BannerStyle {
        case error, warning, info, success

        var color: Color {
            switch self {
            case .error:   return .red
            case .warning: return .orange
            case .info:    return NuraSafePalette.magenta
            case .success: return .green
            }
        }

        var icon: String {
            switch self {
            case .error:   return "exclamationmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info:    return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: style.icon)
                .foregroundColor(style.color)
                .font(.system(size: 15, weight: .semibold))
                .shadow(color: style.color.opacity(0.55), radius: 6)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(NuraSafePalette.textPrimary.opacity(0.95))
                .lineLimit(3)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .glassCard(cornerRadius: 16, borderOpacity: 0.25, fillOpacity: 0.06)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(style.color.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: style.color.opacity(0.22), radius: 10)
    }
}

#endif // os(iOS)

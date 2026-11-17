import SwiftUI

// MARK: - Formatters

enum Formatters {
    static func fileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    static func expiryRemainingText(expiresAt: Date) -> String {
        let seconds = expiresAt.timeIntervalSinceNow
        if seconds <= 0 {
            return "Expired"
        }
        let totalHours = Int(seconds) / 3600
        let days = totalHours / 24
        let remainingHours = totalHours % 24

        if days >= 2 {
            return "in \(days) days"
        } else if days == 1 {
            if remainingHours > 0 {
                return "in 1 day \(remainingHours) h"
            } else {
                return "in 1 day"
            }
        } else {
            return "in \(max(1, totalHours)) h"
        }
    }

    static func expiryRowText(expiresAt: Date) -> String {
        let remaining = expiryRemainingText(expiresAt: expiresAt)
        if remaining == "Expired" {
            return "Expired"
        }
        return "Expires \(remaining)"
    }

    static func urgencyColor(expiresAt: Date) -> Color {
        let days = expiresAt.timeIntervalSinceNow / 86400.0
        if days <= 1.0 {
            return .red
        } else if days <= 3.0 {
            return .orange
        } else {
            return .secondary
        }
    }
}

// MARK: - AppIconView

struct AppIconView: View {
    let tint: Color
    let symbol: String
    var iconURL: URL? = nil
    var size: CGFloat = 62

    private var cornerRadius: CGFloat {
        size * 0.225
    }

    var body: some View {
        Group {
            if let iconURL {
                AsyncImage(url: iconURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        fallbackIcon
                    }
                }
            } else {
                fallbackIcon
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color(.separator), lineWidth: 0.5)
        )
        .accessibilityHidden(true)
    }

    private var fallbackIcon: some View {
        ZStack {
            tint
            Image(systemName: symbol)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.45, height: size * 0.45)
                .fontWeight(.bold)
                .foregroundStyle(.background)
        }
    }
}

// MARK: - InstallButton

struct InstallButton: View {
    let state: InstallState
    var minHeight: CGFloat = 34
    var fontSize: CGFloat = 15
    var action: () -> Void

    private var controlSize: ControlSize {
        minHeight < 40 ? .small : .large
    }

    var body: some View {
        switch state {
        case .idle:
            Button("Get", action: action)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(controlSize)
                .bold()
        case .updateAvailable:
            Button("Update", action: action)
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(controlSize)
                .bold()
        case .installed:
            Button("Open", action: action)
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(controlSize)
                .bold()
        case .installing(let progress):
            Button(action: action) {
                HStack(spacing: Spacing.xs) {
                    ProgressView(value: progress)
                        .progressViewStyle(.circular)
                    Text("\(Int(progress * 100)) %")
                        .monospacedDigit()
                }
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(controlSize)
        case .failed:
            Button("Retry", action: action)
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .buttonBorderShape(.capsule)
                .controlSize(controlSize)
                .bold()
        }
    }
}

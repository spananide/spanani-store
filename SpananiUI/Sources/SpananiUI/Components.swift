import SwiftUI

// MARK: - Formatters

enum Formatters {
    static func fileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useGB]
        formatter.countStyle = .file
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(fromByteCount: bytes)
    }

    static func germanDate(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM"
        return formatter.string(from: date)
    }

    static func expiryRemainingText(expiresAt: Date) -> String {
        let seconds = expiresAt.timeIntervalSinceNow
        if seconds <= 0 {
            return "Abgelaufen"
        }
        let totalHours = Int(seconds) / 3600
        let days = totalHours / 24
        let remainingHours = totalHours % 24

        if days >= 2 {
            return "in \(days) Tagen"
        } else if days == 1 {
            if remainingHours > 0 {
                return "in 1 Tag \(remainingHours) Std"
            } else {
                return "in 1 Tag"
            }
        } else {
            return "in \(max(1, totalHours)) Std"
        }
    }

    static func expiryRowText(expiresAt: Date) -> String {
        let remaining = expiryRemainingText(expiresAt: expiresAt)
        if remaining == "Abgelaufen" {
            return "Abgelaufen"
        }
        return "läuft \(remaining) ab"
    }

    static func urgencyColor(expiresAt: Date) -> Color {
        let days = expiresAt.timeIntervalSinceNow / 86400.0
        if days <= 1.0 {
            return .danger
        } else if days <= 3.0 {
            return .warning
        } else {
            return .inkSoft
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
            if let iconURL = iconURL {
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
        .overlay(strokeOverlay)
        .shadow(color: tint.opacity(0.35), radius: size * 0.16, x: 0, y: size * 0.08)
    }

    private var fallbackIcon: some View {
        ZStack {
            LinearGradient(
                colors: [tint.opacity(0.95), tint.opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [Color.white.opacity(0.24), Color.clear, Color.black.opacity(0.28)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: symbol)
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1.5)
        }
    }

    private var strokeOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(Color.white.opacity(0.12), lineWidth: 1)
    }
}

// MARK: - InstallButton

struct InstallButton: View {
    let state: InstallState
    var minHeight: CGFloat = 34
    var fontSize: CGFloat = 15
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            content
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: state)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle:
            Text("Laden")
                .font(.brand(fontSize, .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(minHeight: minHeight)
                .background(Color.brand)
                .clipShape(Capsule())
        case .updateAvailable:
            Text("Update")
                .font(.brand(fontSize, .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(minHeight: minHeight)
                .background(Color.accent)
                .clipShape(Capsule())
        case .installed:
            Text("Öffnen")
                .font(.brand(fontSize, .semibold))
                .foregroundColor(.brand)
                .padding(.horizontal, 16)
                .frame(minHeight: minHeight)
                .background(Color.brand.opacity(0.16))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.brand.opacity(0.25), lineWidth: 1)
                )
        case .installing(let progress):
            installingView(progress: progress)
        case .failed:
            Text("Erneut")
                .font(.brand(fontSize, .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(minHeight: minHeight)
                .background(Color.danger)
                .clipShape(Capsule())
        }
    }

    private func installingView(progress: Double) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.brand.opacity(0.25), lineWidth: 2.5)
                Circle()
                    .trim(from: 0, to: CGFloat(min(max(progress, 0.05), 1.0)))
                    .stroke(Color.brand, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.35), value: progress)
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.brand)
                    .frame(width: 5, height: 5)
            }
            .frame(width: 18, height: 18)

            Text("\(Int(progress * 100)) %")
                .font(.brand(max(11, fontSize - 2), .semibold))
                .foregroundColor(.brand)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 14)
        .frame(minHeight: minHeight)
        .background(Color.paperSunk)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.brand.opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - ExpiryRing

struct ExpiryRing: View {
    let daysLeft: Double
    var size: CGFloat = 44

    private var ringColor: Color {
        if daysLeft > 3.0 {
            return .success
        } else if daysLeft > 1.0 {
            return .warning
        } else {
            return .danger
        }
    }

    private var trimValue: CGFloat {
        CGFloat(min(max(daysLeft / 7.0, 0.03), 1.0))
    }

    private var lineWidth: CGFloat {
        size >= 80 ? 6.0 : 3.5
    }

    private var labelText: String {
        if daysLeft >= 1.0 {
            return "\(Int(ceil(daysLeft)))T"
        } else {
            let hours = max(1, Int(daysLeft * 24))
            return "\(hours)Std"
        }
    }

    private var labelFontSize: CGFloat {
        if size >= 80 {
            return daysLeft >= 1.0 ? 24 : 18
        } else {
            return daysLeft >= 1.0 ? 13 : 9
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.paperSunk, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: trimValue)
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(labelText)
                .font(.brand(labelFontSize, .extrabold))
                .foregroundColor(.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - CategoryChip

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.brand(14, .semibold))
                .foregroundColor(isSelected ? .white : .inkSoft)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.brand : Color.paperRaised)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SectionHeader

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.brand(22, .extrabold))
                .foregroundColor(.ink)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - SlotDots

struct SlotDots: View {
    let active: Int
    let limit: Int

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                ForEach(0..<limit, id: \.self) { index in
                    Capsule()
                        .fill(index < active ? Color.brand : Color.paperSunk)
                        .frame(width: index < active ? 18 : 8, height: 7)
                        .animation(.spring(response: 0.3), value: active)
                }
            }
            Text("\(active) von \(limit) Plätzen")
                .font(.brand(13, .semibold))
                .foregroundColor(.inkSoft)
        }
    }
}

// MARK: - GlassTabBar

struct GlassTabBar: View {
    @Binding var selection: Int
    @Namespace private var animationNamespace

    private let tabs: [(title: String, symbol: String)] = [
        ("Entdecken", "sparkles"),
        ("Meine Apps", "square.grid.2x2.fill"),
        ("Quellen", "tray.full.fill"),
        ("Einstellungen", "gearshape.fill")
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<tabs.count, id: \.self) { index in
                tabButton(index: index)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func tabButton(index: Int) -> some View {
        let isSelected = selection == index
        let tab = tabs[index]

        Button {
            if selection != index {
                Haptics.selection()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    selection = index
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 16, weight: .semibold))
                if isSelected {
                    Text(tab.title)
                        .font(.brand(14, .semibold))
                        .lineLimit(1)
                }
            }
            .foregroundColor(isSelected ? .white : .inkSoft)
            .padding(.horizontal, isSelected ? 16 : 12)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.brand)
                        .matchedGeometryEffect(id: "activeTabCapsule", in: animationNamespace)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - GradientBackdrop

struct GradientBackdrop: View {
    let tint: Color

    var body: some View {
        RadialGradient(
            colors: [
                tint.opacity(0.48),
                tint.opacity(0.18),
                Color.paper.opacity(0.0)
            ],
            center: .top,
            startRadius: 20,
            endRadius: 280
        )
        .frame(height: 320)
        .blur(radius: 20)
        .allowsHitTesting(false)
    }
}

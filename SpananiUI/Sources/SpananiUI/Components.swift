import SwiftUI
import UIKit

// MARK: - Formatters

enum Formatters {
    static func fileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    static func englishDate(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: date)
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
        let seconds = expiresAt.timeIntervalSinceNow
        if seconds <= 0 {
            return "Expired"
        }
        let totalHours = Int(seconds) / 3600
        let days = totalHours / 24
        let remainingHours = totalHours % 24

        if days >= 2 {
            return "Expires in \(days) days"
        } else if days == 1 {
            if remainingHours > 0 {
                return "Expires in 1 day \(remainingHours) h"
            } else {
                return "Expires in 1 day"
            }
        } else {
            return "Expires in \(max(1, totalHours)) h"
        }
    }

    static func countdownText(expiresAt: Date) -> String {
        let seconds = expiresAt.timeIntervalSinceNow
        if seconds <= 0 {
            return "Expired"
        }
        let totalHours = Int(seconds) / 3600
        let days = totalHours / 24
        let remainingHours = totalHours % 24

        if days >= 1 {
            if remainingHours > 0 {
                return "\(days)d \(remainingHours)h"
            } else {
                return "\(days)d"
            }
        } else {
            return "\(max(1, totalHours))h"
        }
    }

    static func urgencyColor(expiresAt: Date) -> Color {
        let seconds = expiresAt.timeIntervalSinceNow
        if seconds <= 0 {
            return .danger
        }
        let days = seconds / 86400.0
        if days <= 1.0 {
            return .danger
        } else if days <= 3.0 {
            return .warning
        } else {
            return .ink
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
        ZStack {
            if size >= 96 {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .frame(width: size, height: size)
                    .offset(x: 5, y: 5)
            }

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
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1.5)
            )
        }
        .frame(width: size, height: size)
    }

    private var fallbackIcon: some View {
        ZStack {
            tint
            Image(systemName: symbol)
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Mark3DTile

public struct Mark3DTile: View {
    public let size: CGFloat

    public init(size: CGFloat) {
        self.size = size
    }

    private var cornerRadius: CGFloat {
        size * 0.225
    }

    public var body: some View {
        markContent
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1)
            )
    }

    @ViewBuilder
    private var markContent: some View {
        if let path = Bundle.module.path(forResource: "Mark3D", ofType: "png"),
           let uiImage = UIImage(contentsOfFile: path) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if let url = Bundle.module.url(forResource: "Mark3D", withExtension: "png"),
                  let data = try? Data(contentsOf: url),
                  let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            ZStack {
                Color.brand
                SpananiMark()
                    .foregroundColor(.white)
                    .frame(width: size * 0.5, height: size * 0.5)
            }
        }
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
            Text("Get")
                .font(.brand(fontSize, .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(minHeight: minHeight)
                .background(Color.brand)
                .clipShape(Capsule())
        case .updateAvailable:
            Text("Update")
                .font(.brand(fontSize, .semibold))
                .foregroundColor(.paperSunk)
                .padding(.horizontal, 16)
                .frame(minHeight: minHeight)
                .background(Color.accent)
                .clipShape(Capsule())
        case .installed:
            Text("Open")
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
            Text("Retry")
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
                        .stroke(isSelected ? Color.clear : Color.paperSunk, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SectionHeader

struct SectionHeader: View {
    let title: String
    var count: Int? = nil

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.brand(22, .extrabold))
                .foregroundColor(.ink)

            if let count = count {
                Text("\(count)")
                    .font(.brand(12, .semibold))
                    .foregroundColor(.inkSoft)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.paperSunk)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - ShelfHeader

struct ShelfHeader: View {
    let title: String
    var seeAll: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.brand(22, .extrabold))
                .foregroundColor(.ink)

            Spacer()

            if let seeAll = seeAll {
                Button(action: seeAll) {
                    Text("See all")
                        .font(.brand(14, .semibold))
                        .foregroundColor(.brand)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - CommunityBadge

struct CommunityBadge: View {
    var body: some View {
        Text("COMMUNITY")
            .font(.brand(10, .semibold))
            .foregroundColor(.brand)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.brand.opacity(0.16))
            .clipShape(Capsule())
    }
}

// MARK: - SegmentSwitch

public struct SegmentSwitch: View {
    public let options: [String]
    @Binding public var selection: Int
    @Namespace private var segmentNamespace

    public init(options: [String], selection: Binding<Int>) {
        self.options = options
        self._selection = selection
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<options.count, id: \.self) { index in
                let isSelected = selection == index
                Button {
                    if selection != index {
                        Haptics.selection()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selection = index
                        }
                    }
                } label: {
                    Text(options[index])
                        .font(.brand(14, .semibold))
                        .foregroundColor(isSelected ? .white : .inkSoft)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Color.brand)
                                    .matchedGeometryEffect(id: "activeSegment", in: segmentNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .frame(height: 40)
        .background(Color.paperSunk)
        .clipShape(Capsule())
    }
}

// MARK: - SpananiTabBar

struct SpananiTabBar: View {
    @Binding var selection: Int
    @Namespace private var tabNamespace

    private struct TabItem {
        let title: String
        let symbol: String
        let isMark: Bool
    }

    private let tabs: [TabItem] = [
        TabItem(title: "Discover", symbol: "", isMark: true),
        TabItem(title: "My Apps", symbol: "square.grid.2x2.fill", isMark: false),
        TabItem(title: "Sources", symbol: "tray.full.fill", isMark: false),
        TabItem(title: "Settings", symbol: "gearshape.fill", isMark: false)
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<tabs.count, id: \.self) { index in
                tabButton(index: index)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.paperRaised)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.paperSunk, lineWidth: 1)
        )
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
                if tab.isMark {
                    SpananiMark()
                        .foregroundColor(isSelected ? .white : .inkSoft)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: tab.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .inkSoft)
                }

                if isSelected {
                    Text(tab.title)
                        .font(.brand(14, .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, isSelected ? 16 : 12)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.brand)
                        .matchedGeometryEffect(id: "activeTabCapsule", in: tabNamespace)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
    }
}

import CoreText
import SwiftUI
import UIKit

// MARK: - Color Palette

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

    static func adaptive(darkHex: UInt32, lightHex: UInt32) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: darkHex)
                : UIColor(hex: lightHex)
        }
    }
}

extension Color {
    public static let paper = Color(uiColor: .adaptive(darkHex: 0x16121d, lightHex: 0xf4f2f7))
    public static let paperRaised = Color(uiColor: .adaptive(darkHex: 0x201a2a, lightHex: 0xffffff))
    public static let paperSunk = Color(uiColor: .adaptive(darkHex: 0x110e17, lightHex: 0xeae6f0))
    public static let ink = Color(uiColor: .adaptive(darkHex: 0xece8f3, lightHex: 0x1a1622))
    public static let inkSoft = Color(uiColor: .adaptive(darkHex: 0xa69fb4, lightHex: 0x5b536a))
    public static let inkFaint = Color(uiColor: .adaptive(darkHex: 0x8c849c, lightHex: 0x665e77))
    public static let brand = Color(uiColor: .adaptive(darkHex: 0x9955e7, lightHex: 0x9955e7))
    public static let accent = Color(uiColor: .adaptive(darkHex: 0xb892f2, lightHex: 0x661bbb))
    public static let success = Color(uiColor: .adaptive(darkHex: 0x4fd69c, lightHex: 0x0b6b4a))
    public static let danger = Color(uiColor: .adaptive(darkHex: 0xff7a88, lightHex: 0xc42b3a))
    public static let warning = Color(uiColor: .adaptive(darkHex: 0xffc65a, lightHex: 0x9a6200))
}

// MARK: - Typography

public enum SpananiFont {
    private static var didRegister = false

    public static func register() {
        guard !didRegister else { return }
        didRegister = true

        let fontNames = [
            "BricolageGrotesque-Regular",
            "BricolageGrotesque-SemiBold",
            "BricolageGrotesque-ExtraBold"
        ]

        for name in fontNames {
            if let url = Bundle.module.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
}

public enum BrandWeight {
    case regular
    case semibold
    case extrabold

    public var fontSuffix: String {
        switch self {
        case .regular:
            return "Regular"
        case .semibold:
            return "SemiBold"
        case .extrabold:
            return "ExtraBold"
        }
    }
}

extension Font {
    public static func brand(_ size: CGFloat, _ weight: BrandWeight = .regular) -> Font {
        .custom("BricolageGrotesque-\(weight.fontSuffix)", size: size)
    }
}

// MARK: - Dimensions

public enum SpananiRadius {
    public static let card: CGFloat = 28
    public static let tile: CGFloat = 20
    public static let chip: CGFloat = 100
}

// MARK: - Haptics

enum Haptics {
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

// MARK: - Shadows

struct SoftShadowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat
    var x: CGFloat
    var y: CGFloat

    func body(content: Content) -> some View {
        content.shadow(color: color, radius: radius, x: x, y: y)
    }
}

extension View {
    func softShadow(
        color: Color = Color.black.opacity(0.12),
        radius: CGFloat = 16,
        x: CGFloat = 0,
        y: CGFloat = 6
    ) -> some View {
        modifier(SoftShadowModifier(color: color, radius: radius, x: x, y: y))
    }
}

// MARK: - Logo Resource Helper

public enum SpananiLogo {
    public static func markImage() -> Image {
        if let path = Bundle.module.path(forResource: "Mark", ofType: "png"),
           let uiImage = UIImage(contentsOfFile: path) {
            return Image(uiImage: uiImage).renderingMode(.template)
        }
        if let url = Bundle.module.url(forResource: "Mark", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage).renderingMode(.template)
        }
        return Image("Mark", bundle: .module).renderingMode(.template)
    }
}

public struct SpananiMark: View {
    public init() {}

    public var body: some View {
        SpananiLogo.markImage()
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

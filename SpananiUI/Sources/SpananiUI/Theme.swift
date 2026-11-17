import SwiftUI
import UIKit

// MARK: - Spacing

public enum Spacing {
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 16
    public static let l: CGFloat = 24
}

// MARK: - Accent Color

public extension Color {
    static var spananiAccent: Color {
        Color("SpananiAccent", bundle: .module)
    }
}

// MARK: - Typography

public enum SpananiFont {
    public static func register() {}
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

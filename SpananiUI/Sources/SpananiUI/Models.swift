import Foundation
import SwiftUI

public struct StoreItem: Identifiable, Hashable {
    public let id: String
    public var name: String
    public var subtitle: String
    public var developer: String
    public var description: String
    public var category: String
    public var versionString: String
    public var sizeBytes: Int64
    public var sourceName: String
    public var tint: Color
    public var symbol: String
    public var iconURL: URL?
    public var screenshotURLs: [URL]
    public var whatsNew: String
    public var permissions: [String]
    public var isFeatured: Bool
    public var heroTagline: String

    public init(
        id: String,
        name: String,
        subtitle: String,
        developer: String,
        description: String,
        category: String,
        versionString: String,
        sizeBytes: Int64,
        sourceName: String,
        tint: Color,
        symbol: String,
        iconURL: URL? = nil,
        screenshotURLs: [URL] = [],
        whatsNew: String = "",
        permissions: [String] = [],
        isFeatured: Bool = false,
        heroTagline: String = ""
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.developer = developer
        self.description = description
        self.category = category
        self.versionString = versionString
        self.sizeBytes = sizeBytes
        self.sourceName = sourceName
        self.tint = tint
        self.symbol = symbol
        self.iconURL = iconURL
        self.screenshotURLs = screenshotURLs
        self.whatsNew = whatsNew
        self.permissions = permissions
        self.isFeatured = isFeatured
        self.heroTagline = heroTagline
    }

    public static func == (lhs: StoreItem, rhs: StoreItem) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct InstalledItem: Identifiable, Hashable {
    public let id: String
    public var name: String
    public var versionString: String
    public var tint: Color
    public var symbol: String
    public var iconURL: URL?
    public var expiresAt: Date
    public var isActive: Bool
    public var hasUpdate: Bool
    public var latestVersion: String?

    public init(
        id: String,
        name: String,
        versionString: String,
        tint: Color,
        symbol: String,
        iconURL: URL? = nil,
        expiresAt: Date,
        isActive: Bool = true,
        hasUpdate: Bool = false,
        latestVersion: String? = nil
    ) {
        self.id = id
        self.name = name
        self.versionString = versionString
        self.tint = tint
        self.symbol = symbol
        self.iconURL = iconURL
        self.expiresAt = expiresAt
        self.isActive = isActive
        self.hasUpdate = hasUpdate
        self.latestVersion = latestVersion
    }

    public static func == (lhs: InstalledItem, rhs: InstalledItem) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public enum InstallState: Equatable {
    case idle
    case installing(progress: Double)
    case installed
    case updateAvailable
    case failed(String)
}

public struct SourceItem: Identifiable, Hashable {
    public let id: String
    public var name: String
    public var url: String
    public var appCount: Int
    public var tint: Color

    public init(
        id: String = UUID().uuidString,
        name: String,
        url: String,
        appCount: Int,
        tint: Color = .brand
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.appCount = appCount
        self.tint = tint
    }

    public static func == (lhs: SourceItem, rhs: SourceItem) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct AccountInfo: Equatable {
    public var appleID: String?
    public var isPaired: Bool
    public var vpnOn: Bool

    public init(
        appleID: String? = nil,
        isPaired: Bool = false,
        vpnOn: Bool = false
    ) {
        self.appleID = appleID
        self.isPaired = isPaired
        self.vpnOn = vpnOn
    }
}

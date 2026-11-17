import Foundation
import SwiftUI

public enum DemoData {
    @MainActor
    public static func makeModel() -> StoreModel {
        let apps: [StoreItem] = [
            StoreItem(
                id: "de.spanani.fmhy",
                name: "FMHY",
                subtitle: "Wiki & link checker for free knowledge",
                developer: "Free Software Collective",
                description: "The most comprehensive directory of useful tools, educational resources, and media on the web. Features integrated security checks for external links and offline bookmarks. Fast full-text search and curated recommendations.",
                category: "Utilities",
                versionString: "1.6.0",
                sizeBytes: 19_400_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.60, green: 0.33, blue: 0.91),
                symbol: "link.badge.plus",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Version 1.6.0 introduces an improved link filter, dark mode optimizations, and faster loading times for offline articles.",
                permissions: ["Network Access", "Local Storage"],
                isFeatured: true,
                heroTagline: "Developer Favorite"
            ),
            StoreItem(
                id: "de.spanani.kippe",
                name: "Tilt",
                subtitle: "Minimalist physics and balance game",
                developer: "Studio Incline",
                description: "Keep the floating platform balanced with delicate device tilting. Physics-based puzzles with subtle haptic feedback and a soothing soundtrack. Every level tests your dexterity.",
                category: "Games",
                versionString: "1.0.4",
                sizeBytes: 42_800_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.95, green: 0.45, blue: 0.25),
                symbol: "circle.grid.cross.fill",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "10 new levels, support for enhanced haptics, and finer gyroscope sensitivity.",
                permissions: ["Motion Sensors"],
                isFeatured: true,
                heroTagline: "New in Store"
            ),
            StoreItem(
                id: "de.spanani.pausenklau",
                name: "Break Puzzles",
                subtitle: "Quick mini-puzzles for short breaks",
                developer: "Lukas Bergmann",
                description: "Bite-sized brain teasers designed to take exactly three minutes, perfect for your coffee break. No ads, no in-app purchases, just pure puzzle fun. Daily challenges shareable with friends.",
                category: "Games",
                versionString: "2.3.1",
                sizeBytes: 15_200_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.25, green: 0.75, blue: 0.85),
                symbol: "gamecontroller.fill",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "New category for number puzzles and synchronized high scores.",
                permissions: ["Local Storage"],
                isFeatured: false,
                heroTagline: ""
            ),
            StoreItem(
                id: "de.spanani.tagesspiele",
                name: "Daily Puzzles",
                subtitle: "Word and logic puzzles every morning",
                developer: "Puzzle Workshop",
                description: "A fresh handcrafted crossword and number puzzle delivered to your device each day. Sharpen your memory and vocabulary with elegant design. Keep track of your daily streak.",
                category: "Games",
                versionString: "1.4.0",
                sizeBytes: 28_100_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.92, green: 0.70, blue: 0.20),
                symbol: "calendar.badge.clock",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Added weekend special puzzles with double word length.",
                permissions: ["Notifications"],
                isFeatured: false,
                heroTagline: ""
            ),
            StoreItem(
                id: "de.spanani.lyricshud",
                name: "Lyrics HUD",
                subtitle: "Synchronized lyrics over any music app",
                developer: "Klangwerk",
                description: "Displays synchronized, line-by-line lyrics in a floating window over your music. Supports popular streaming services and local audio files. Customize typography and opacity to your liking.",
                category: "Media",
                versionString: "3.0.2",
                sizeBytes: 24_600_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.88, green: 0.28, blue: 0.55),
                symbol: "music.note.tv.fill",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Support for real-time multilingual translations.",
                permissions: ["Media Library", "Background Audio"],
                isFeatured: true,
                heroTagline: "Recently Updated"
            ),
            StoreItem(
                id: "de.spanani.strullermod",
                name: "Server Companion",
                subtitle: "Real-time telemetry and save-game management",
                developer: "Modding Central",
                description: "Connect your device to your local game server for live statistics and inventory management. Receive notifications on server events and manage mods with a single tap. Full end-to-end encryption.",
                category: "Utilities",
                versionString: "0.9.8",
                sizeBytes: 31_500_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.35, green: 0.80, blue: 0.45),
                symbol: "antenna.radiowaves.left.and.right",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Optimized server ping display and automatic connection recovery.",
                permissions: ["Network Access", "Local Network"],
                isFeatured: false,
                heroTagline: ""
            ),
            StoreItem(
                id: "de.spanani.kistensortierer",
                name: "Box Organizer",
                subtitle: "Household inventory with barcode scanner",
                developer: "Orderly Living",
                description: "Organize basements, moving boxes, and pantries effortlessly with QR codes. Find any item in seconds via full-text search and photo recognition. Export inventory lists in convenient PDF format.",
                category: "Utilities",
                versionString: "2.0.1",
                sizeBytes: 21_700_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.72, green: 0.48, blue: 0.34),
                symbol: "shippingbox.fill",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Batch scanning mode to quickly capture contents of entire boxes.",
                permissions: ["Camera", "Local Storage"],
                isFeatured: false,
                heroTagline: ""
            ),
            StoreItem(
                id: "de.spanani.lautstaerkebooster",
                name: "Volume Booster",
                subtitle: "Precise equalizer and dynamic range compression",
                developer: "AudioDSP Labs",
                description: "Get the best audio quality from quiet podcasts, older recordings, and videos. Features a 10-band parametric equalizer and a hearing protection limiter. Save custom profiles for headphones and speakers.",
                category: "Media",
                versionString: "1.2.0",
                sizeBytes: 12_900_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.95, green: 0.30, blue: 0.35),
                symbol: "speaker.wave.3.fill",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "New speech enhancement mode for extra-clear vocals.",
                permissions: ["Microphone", "Audio Output"],
                isFeatured: false,
                heroTagline: ""
            ),
            StoreItem(
                id: "de.spanani.wetterfrosch",
                name: "Weather Frog",
                subtitle: "Open-source weather forecast without trackers",
                developer: "Open Meteorology",
                description: "High-precision forecasts directly from European meteorological services without ad trackers. Minute-by-minute radar images and detailed wind and pressure graphs. Efficient background polling saves battery.",
                category: "Utilities",
                versionString: "4.1.2",
                sizeBytes: 17_800_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.20, green: 0.60, blue: 0.95),
                symbol: "cloud.sun.rain.fill",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Minute-by-minute widget updates when severe rain is imminent.",
                permissions: ["Location Services (While In Use)"],
                isFeatured: true,
                heroTagline: "Featured Here"
            ),
            StoreItem(
                id: "de.spanani.notizzettel",
                name: "Notes",
                subtitle: "Clean Markdown notes with Git sync",
                developer: "Plaintext Software",
                description: "Your thoughts in plain text, stored locally and optionally synchronized with Git. Fast keyboard shortcuts, wiki links, and tag organization. Full control over your personal notes.",
                category: "Utilities",
                versionString: "1.8.4",
                sizeBytes: 14_300_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.85, green: 0.75, blue: 0.30),
                symbol: "note.text",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Added support for mathematical formulas and Mermaid diagrams.",
                permissions: ["File Access", "Local Storage"],
                isFeatured: false,
                heroTagline: ""
            ),
            StoreItem(
                id: "de.spanani.pomodoropur",
                name: "Focus Timer",
                subtitle: "Distraction-free work intervals with ambient sound",
                developer: "Deep Work Studio",
                description: "Boost productivity with classic 25-minute focus sessions and gentle transition chimes. Ambient background sounds like forest rain or fireplace help you concentrate. Detailed weekly stats with no cloud requirement.",
                category: "Utilities",
                versionString: "2.0.0",
                sizeBytes: 36_200_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.90, green: 0.35, blue: 0.40),
                symbol: "timer",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "New 'Nordic Forest' sound set and customizable break intervals.",
                permissions: ["Notifications", "Background Audio"],
                isFeatured: false,
                heroTagline: ""
            ),
            StoreItem(
                id: "de.spanani.sternenkarte",
                name: "Star Chart",
                subtitle: "Interactive planetarium for the night sky",
                developer: "Cosmos Society",
                description: "Point your device at the night sky to discover stars, planets, and the International Space Station. Computes satellite passes and moon phases offline in your pocket. Perfect for stargazers and night hikes.",
                category: "Lifestyle",
                versionString: "3.5.0",
                sizeBytes: 68_400_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.45, green: 0.35, blue: 0.85),
                symbol: "sparkles",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Updated comet catalog and refined AR position accuracy.",
                permissions: ["Camera", "Compass & Sensors"],
                isFeatured: false,
                heroTagline: ""
            )
        ]

        let installed: [InstalledItem] = [
            InstalledItem(
                id: "de.spanani.fmhy",
                name: "FMHY",
                versionString: "1.5.1",
                tint: Color(red: 0.60, green: 0.33, blue: 0.91),
                symbol: "link.badge.plus",
                iconURL: nil,
                expiresAt: Date().addingTimeInterval(1 * 86400 + 3 * 3600),
                isActive: true,
                hasUpdate: true,
                latestVersion: "1.6.0"
            ),
            InstalledItem(
                id: "de.spanani.kippe",
                name: "Tilt",
                versionString: "1.0.4",
                tint: Color(red: 0.95, green: 0.45, blue: 0.25),
                symbol: "circle.grid.cross.fill",
                iconURL: nil,
                expiresAt: Date().addingTimeInterval(5 * 86400 + 14 * 3600),
                isActive: true,
                hasUpdate: false,
                latestVersion: nil
            )
        ]

        let sources: [SourceItem] = [
            SourceItem(
                id: "source-spanani",
                name: "spanani.de",
                url: "https://apps.spanani.de/source.json",
                appCount: 12,
                tint: .accentColor
            ),
            SourceItem(
                id: "source-community",
                name: "Community Source",
                url: "https://community.spanani.de/apps.json",
                appCount: 8,
                tint: .accentColor
            )
        ]

        let account = AccountInfo(
            appleID: "user@icloud.com",
            isPaired: true,
            vpnOn: true
        )

        let now = Date()
        let changes: [ChangeItem] = [
            ChangeItem(
                id: "de.spanani.fmhy@1.6.0",
                appID: "de.spanani.fmhy",
                appName: "FMHY",
                tint: Color(red: 0.60, green: 0.33, blue: 0.91),
                symbol: "link.badge.plus",
                version: "1.6.0",
                date: now.addingTimeInterval(-2 * 3600),
                notes: "Version 1.6.0 introduces an improved link filter, dark mode optimizations, and faster loading times for offline articles."
            ),
            ChangeItem(
                id: "de.spanani.kippe@1.0.4",
                appID: "de.spanani.kippe",
                appName: "Tilt",
                tint: Color(red: 0.95, green: 0.45, blue: 0.25),
                symbol: "circle.grid.cross.fill",
                version: "1.0.4",
                date: now.addingTimeInterval(-5 * 3600),
                notes: "10 new levels, support for enhanced haptics, and finer gyroscope sensitivity."
            ),
            ChangeItem(
                id: "de.spanani.wetterfrosch@4.1.2",
                appID: "de.spanani.wetterfrosch",
                appName: "Weather Frog",
                tint: Color(red: 0.20, green: 0.60, blue: 0.95),
                symbol: "cloud.sun.rain.fill",
                version: "4.1.2",
                date: now.addingTimeInterval(-26 * 3600),
                notes: "Minute-by-minute widget updates when severe rain is imminent."
            ),
            ChangeItem(
                id: "de.spanani.pausenklau@2.3.1",
                appID: "de.spanani.pausenklau",
                appName: "Break Puzzles",
                tint: Color(red: 0.25, green: 0.75, blue: 0.85),
                symbol: "gamecontroller.fill",
                version: "2.3.1",
                date: now.addingTimeInterval(-30 * 3600),
                notes: "New category for number puzzles and synchronized high scores."
            ),
            ChangeItem(
                id: "de.spanani.notizzettel@1.8.4",
                appID: "de.spanani.notizzettel",
                appName: "Notes",
                tint: Color(red: 0.85, green: 0.75, blue: 0.30),
                symbol: "note.text",
                version: "1.8.4",
                date: now.addingTimeInterval(-72 * 3600),
                notes: "Added support for mathematical formulas and Mermaid diagrams."
            )
        ]

        let model = StoreModel(
            apps: apps,
            installed: installed,
            sources: sources,
            changes: changes,
            account: account,
            activeLimit: 3,
            favorites: ["de.spanani.fmhy"],
            autoRefreshEnabled: true,
            remindersEnabled: true,
            actions: nil
        )

        return model
    }
}

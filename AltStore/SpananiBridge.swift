//
//  SpananiBridge.swift
//  AltStore
//
//  Created for spanani Store.
//

import CoreData
import Foundation
import Minimuxer
import SideSign
import SpananiUI
import SwiftUI
import UIKit
import UserNotifications

private final class ProgressBox: @unchecked Sendable {
    var observation: NSKeyValueObservation?
}

@MainActor
final class SpananiBridge: StoreActions {
    static let shared = SpananiBridge()

    let model = StoreModel()

    private var didStart = false
    private var debounceTask: Task<Void, Never>?
    private var notificationObservers: [NSObjectProtocol] = []
    private var lastReminderSignature: String?

    private init() {
        model.actions = self
    }

    // MARK: - Lifecycle

    func start() {
        guard !didStart else { return }
        didStart = true

        Task { @MainActor in
            var elapsed: Double = 0
            while !DatabaseManager.shared.isStarted && elapsed < 60.0 {
                try? await Task.sleep(nanoseconds: 500_000_000)
                elapsed += 0.5
            }

            guard DatabaseManager.shared.isStarted else {
                debugLog("[SpananiBridge] Database failed to start within 60s timeout.")
                return
            }

            self.reloadData()
            self.setupContextObservers()

            let activeObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task {
                    _ = await AppBootManager.shared.ensureMinimuxerStarted()
                }
            }
            self.notificationObservers.append(activeObserver)
        }
    }

    private func setupContextObservers() {
        let context = DatabaseManager.shared.viewContext

        let observer1 = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextObjectsDidChange,
            object: context,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleReload()
        }

        let observer2 = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: context,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleReload()
        }

        self.notificationObservers = [observer1, observer2]
    }

    private func scheduleReload() {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            self.reloadData()
        }
    }

    // MARK: - Data Reload

    @MainActor
    func reloadData() {
        let context = DatabaseManager.shared.viewContext

        let storeApps = StoreApp.all(in: context)
        let installedApps = InstalledApp.all(in: context)
        let sources = Source.all(in: context)

        // Filter out AltStore itself and sort featured / newest sensibly
        let filteredApps = storeApps.filter { $0.bundleIdentifier != StoreApp.altstoreAppID }
        let sortedApps = filteredApps.sorted { app1, app2 in
            let date1 = app1.latestSupportedVersion?.date ?? app1.versionDate ?? Date.distantPast
            let date2 = app2.latestSupportedVersion?.date ?? app2.versionDate ?? Date.distantPast
            if date1 != date2 {
                return date1 > date2
            }
            return app1.name.localizedCaseInsensitiveCompare(app2.name) == .orderedAscending
        }

        let defaultTint = UIColor(red: 0.6, green: 0.33, blue: 0.91, alpha: 1)

        let mappedApps: [StoreItem] = sortedApps.enumerated().map { index, app in
            let isFeatured = index < 4
            let heroTagline = isFeatured ? (index % 2 == 0 ? "New" : "Popular") : ""
            let tintColor = app.tintColor ?? defaultTint
            let versionString = app.latestSupportedVersion?.version ?? app.version ?? "—"
            let size = app.latestSupportedVersion?.size ?? app._size
            let whatsNew = app.latestSupportedVersion?.localizedDescription ?? app.versionDescription ?? ""
            let permissions = Array(app.permissions).map { $0.localizedDisplayName }.sorted()

            return StoreItem(
                id: app.bundleIdentifier,
                name: app.name,
                subtitle: app.subtitle ?? "",
                developer: app.developerName,
                description: app.localizedDescription,
                category: mapCategory(app),
                versionString: versionString,
                sizeBytes: size,
                sourceName: app.source?.name ?? "SideStore",
                tint: Color(uiColor: tintColor),
                symbol: "app.fill",
                iconURL: app.iconURL,
                screenshotURLs: app.screenshotURLs,
                whatsNew: whatsNew,
                permissions: permissions,
                isFeatured: isFeatured,
                heroTagline: heroTagline
            )
        }

        let sortedInstalled = installedApps.sorted {
            $0.expirationDate < $1.expirationDate
        }

        let mappedInstalled: [InstalledItem] = sortedInstalled.map { app in
            let tintColor = app.storeApp?.tintColor ?? defaultTint
            let iconURL = app.storeApp?.iconURL

            return InstalledItem(
                id: app.bundleIdentifier,
                name: app.name,
                versionString: app.version,
                tint: Color(uiColor: tintColor),
                symbol: "app.fill",
                iconURL: iconURL,
                expiresAt: app.expirationDate,
                isActive: app.isActive,
                hasUpdate: app.hasUpdate,
                latestVersion: app.storeApp?.latestSupportedVersion?.version
            )
        }

        let sortedSources = sources.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        let mappedSources: [SourceItem] = sortedSources.map { source in
            let tintColor = source.effectiveTintColor ?? defaultTint
            return SourceItem(
                id: source.identifier,
                name: source.name,
                url: source.sourceURL.absoluteString,
                appCount: source.apps.count,
                tint: Color(uiColor: tintColor)
            )
        }

        let changes: [ChangeItem] = filteredApps.flatMap { app in
            app.versions.prefix(3).map { version in
                ChangeItem(
                    id: "\(app.bundleIdentifier)@\(version.version)",
                    appID: app.bundleIdentifier,
                    appName: app.name,
                    tint: Color(uiColor: app.tintColor ?? defaultTint),
                    symbol: "app.fill",
                    iconURL: app.iconURL,
                    version: version.version,
                    date: version.date,
                    notes: version.localizedDescription ?? ""
                )
            }
        }
        let sortedChanges = changes.sorted { $0.date > $1.date }

        model.apps = mappedApps
        model.installed = mappedInstalled
        model.sources = mappedSources
        model.changes = Array(sortedChanges.prefix(40))
        model.activeLimit = InstalledApp.freeAccountActiveAppsLimit
        model.autoRefreshEnabled = UserDefaults.standard.isBackgroundRefreshEnabled
        model.remindersEnabled = UserDefaults.standard.bool(forKey: "spanani.reminders")

        let appleID = Keychain.shared.appleIDEmailAddress
        let isPaired = PairingFileManager.shared.hasPairingFile()
        let vpnOn = minimuxer.network.isUTunAvailable
        let widgetsReady = Bundle.main.altstoreAppGroup != nil

        model.account = AccountInfo(
            appleID: appleID,
            isPaired: isPaired,
            vpnOn: vpnOn,
            widgetsReady: widgetsReady
        )

        Task {
            await self.rescheduleReminders()
        }
    }

    private func mapCategory(_ app: StoreApp) -> String {
        if let cat = app.category {
            switch cat {
            case .developer: return "Developer"
            case .entertainment: return "Media"
            case .games: return "Games"
            case .lifestyle: return "Lifestyle"
            case .other: return "Other"
            case .photoAndVideo: return "Photo & Video"
            case .social: return "Social"
            case .utilities: return "Utilities"
            }
        }
        if let raw = app._category?.lowercased() {
            switch raw {
            case "developer": return "Developer"
            case "entertainment": return "Media"
            case "games": return "Games"
            case "lifestyle": return "Lifestyle"
            case "other": return "Other"
            case "photo-video", "photovideo", "photo & video": return "Photo & Video"
            case "social": return "Social"
            case "utilities": return "Utilities"
            case "education": return "Education"
            default: return "Other"
            }
        }
        return "Other"
    }

    // MARK: - Navigation Helper

    static var topViewController: UIViewController? {
        UIApplication.shared.topViewController()
    }

    // MARK: - StoreActions Implementation

    func install(_ app: StoreItem, progress: @escaping (Double) -> Void) async throws {
        if let startError = await AppBootManager.shared.ensureMinimuxerStarted() { throw startError }
        // needs proper testing on device
        debugLog("[SpananiBridge] install() requested for: \(app.id)")
        let context = DatabaseManager.shared.viewContext

        let installedApp = InstalledApp.first(
            satisfying: NSPredicate(format: "%K == %@", #keyPath(InstalledApp.bundleIdentifier), app.id),
            in: context
        )

        if let installedApp = installedApp, installedApp.hasUpdate {
            debugLog("[SpananiBridge] Existing app has update available: \(app.id)")
            let box = ProgressBox()

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let progressObj = AppManager.shared.update(
                    installedApp,
                    presentingViewController: Self.topViewController
                ) { result in
                    box.observation?.invalidate()
                    box.observation = nil

                    switch result {
                    case .success:
                        debugLog("[SpananiBridge] Update succeeded for: \(app.id)")
                        continuation.resume()
                    case .failure(let error):
                        debugLog("[SpananiBridge] Update failed for: \(app.id), error: \(error)")
                        continuation.resume(throwing: error)
                    }
                }

                box.observation = progressObj.observe(\.fractionCompleted, options: [.initial, .new]) { p, _ in
                    let frac = p.fractionCompleted
                    Task { @MainActor in
                        progress(frac)
                    }
                }
            }
            return
        }

        guard let storeApp = StoreApp.first(
            satisfying: NSPredicate(format: "%K == %@", #keyPath(StoreApp.bundleIdentifier), app.id),
            in: context
        ) else {
            let error = NSError(
                domain: "SpananiBridge",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "App “\(app.name)” could not be found in the store."]
            )
            debugLog("[SpananiBridge] StoreApp not found: \(app.id)")
            throw error
        }

        let box = ProgressBox()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let group = AppManager.shared.install(
                .app(storeApp),
                presentingViewController: Self.topViewController
            ) { result in
                box.observation?.invalidate()
                box.observation = nil

                switch result {
                case .success:
                    debugLog("[SpananiBridge] Install succeeded for: \(app.id)")
                    continuation.resume()
                case .failure(let error):
                    debugLog("[SpananiBridge] Install failed for: \(app.id), error: \(error)")
                    continuation.resume(throwing: error)
                }
            }

            box.observation = group.progress.observe(\.fractionCompleted, options: [.initial, .new]) { p, _ in
                let frac = p.fractionCompleted
                Task { @MainActor in
                    progress(frac)
                }
            }
        }
    }

    func refresh(_ app: InstalledItem) async throws {
        if let startError = await AppBootManager.shared.ensureMinimuxerStarted() { throw startError }
        // needs proper testing on device
        debugLog("[SpananiBridge] refresh() requested for: \(app.id)")
        let context = DatabaseManager.shared.viewContext

        guard let installedApp = InstalledApp.first(
            satisfying: NSPredicate(format: "%K == %@", #keyPath(InstalledApp.bundleIdentifier), app.id),
            in: context
        ) else {
            let error = NSError(
                domain: "SpananiBridge",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Installed app “\(app.name)” was not found."]
            )
            debugLog("[SpananiBridge] InstalledApp not found for refresh: \(app.id)")
            throw error
        }

        let group = AppManager.shared.refresh([installedApp], presentingViewController: Self.topViewController)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            group.completionHandler = { results in
                if let result = results[installedApp.bundleIdentifier] {
                    switch result {
                    case .success:
                        debugLog("[SpananiBridge] Refresh succeeded for: \(app.id)")
                        continuation.resume()
                    case .failure(let error):
                        debugLog("[SpananiBridge] Refresh failed for: \(app.id), error: \(error)")
                        continuation.resume(throwing: error)
                    }
                } else if let groupError = group.error {
                    debugLog("[SpananiBridge] Refresh group error: \(groupError)")
                    continuation.resume(throwing: groupError)
                } else {
                    debugLog("[SpananiBridge] Refresh completed with empty result for: \(app.id)")
                    continuation.resume()
                }
            }
        }
    }

    func refreshAll(progress: @escaping (Double) -> Void) async throws {
        if let startError = await AppBootManager.shared.ensureMinimuxerStarted() { throw startError }
        // needs proper testing on device
        debugLog("[SpananiBridge] refreshAll() requested")
        let context = DatabaseManager.shared.viewContext
        let activeApps = InstalledApp.all(in: context).filter { $0.isActive }

        guard !activeApps.isEmpty else {
            debugLog("[SpananiBridge] No active apps to refresh.")
            progress(1.0)
            return
        }

        let group = AppManager.shared.refresh(activeApps, presentingViewController: Self.topViewController)
        let box = ProgressBox()

        box.observation = group.progress.observe(\.fractionCompleted, options: [.initial, .new]) { p, _ in
            let frac = p.fractionCompleted
            Task { @MainActor in
                progress(frac)
            }
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            group.completionHandler = { results in
                box.observation?.invalidate()
                box.observation = nil

                let failures = results.compactMapValues { result -> Error? in
                    switch result {
                    case .failure(let error): return error
                    case .success: return nil
                    }
                }

                if let firstError = failures.values.first {
                    debugLog("[SpananiBridge] refreshAll() encountered error: \(firstError)")
                    continuation.resume(throwing: firstError)
                } else if let groupError = group.error {
                    debugLog("[SpananiBridge] refreshAll() group error: \(groupError)")
                    continuation.resume(throwing: groupError)
                } else {
                    debugLog("[SpananiBridge] refreshAll() succeeded for \(activeApps.count) apps")
                    continuation.resume()
                }
            }
        }
    }

    func open(_ app: InstalledItem) {
        debugLog("[SpananiBridge] open() requested for: \(app.id)")
        let context = DatabaseManager.shared.viewContext

        if let installedApp = InstalledApp.first(
            satisfying: NSPredicate(format: "%K == %@", #keyPath(InstalledApp.bundleIdentifier), app.id),
            in: context
        ) {
            UIApplication.shared.open(installedApp.openAppURL)
        } else {
            let openURL = InstalledApp.openAppURL(targetBundleIdentifier: app.id)
            UIApplication.shared.open(openURL)
        }
    }

    func deactivate(_ app: InstalledItem) async throws {
        if let startError = await AppBootManager.shared.ensureMinimuxerStarted() { throw startError }
        // needs proper testing on device
        debugLog("[SpananiBridge] deactivate/activate toggle requested for: \(app.id)")
        let context = DatabaseManager.shared.viewContext

        guard let installedApp = InstalledApp.first(
            satisfying: NSPredicate(format: "%K == %@", #keyPath(InstalledApp.bundleIdentifier), app.id),
            in: context
        ) else {
            let error = NSError(
                domain: "SpananiBridge",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Installed app was not found."]
            )
            debugLog("[SpananiBridge] App not found for deactivation: \(app.id)")
            throw error
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            if installedApp.isActive {
                AppManager.shared.deactivate(
                    installedApp,
                    presentingViewController: Self.topViewController
                ) { result in
                    switch result {
                    case .success:
                        debugLog("[SpananiBridge] Deactivate succeeded for: \(app.id)")
                        continuation.resume()
                    case .failure(let error):
                        debugLog("[SpananiBridge] Deactivate failed for: \(app.id), error: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
            } else {
                AppManager.shared.activate(
                    installedApp,
                    presentingViewController: Self.topViewController
                ) { result in
                    switch result {
                    case .success:
                        debugLog("[SpananiBridge] Activate succeeded for: \(app.id)")
                        continuation.resume()
                    case .failure(let error):
                        debugLog("[SpananiBridge] Activate failed for: \(app.id), error: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    func deleteApp(_ app: InstalledItem) async throws {
        if let startError = await AppBootManager.shared.ensureMinimuxerStarted() { throw startError }
        // needs proper testing on device
        debugLog("[SpananiBridge] deleteApp() requested for: \(app.id)")
        let context = DatabaseManager.shared.viewContext

        guard let installedApp = InstalledApp.first(
            satisfying: NSPredicate(format: "%K == %@", #keyPath(InstalledApp.bundleIdentifier), app.id),
            in: context
        ) else {
            let error = NSError(
                domain: "SpananiBridge",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Installed app was not found."]
            )
            debugLog("[SpananiBridge] App not found for deletion: \(app.id)")
            throw error
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            AppManager.shared.deleteApp(
                installedApp,
                presentingViewController: Self.topViewController
            ) { result in
                switch result {
                case .success:
                    debugLog("[SpananiBridge] Delete succeeded for: \(app.id)")
                    continuation.resume()
                case .failure(let error):
                    debugLog("[SpananiBridge] Delete failed for: \(app.id), error: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func addSource(urlString: String) async throws {
        debugLog("[SpananiBridge] addSource() requested with URL: \(urlString)")
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let url = URL(string: trimmed),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()) else {
            let error = NSError(
                domain: "SpananiBridge",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL. Enter a valid HTTP or HTTPS address."]
            )
            debugLog("[SpananiBridge] Invalid source URL: \(urlString)")
            throw error
        }

        let context = DatabaseManager.shared.persistentContainer.newBackgroundContext()
        let source = try await AppManager.shared.fetchSource(sourceURL: url, managedObjectContext: context)

        guard let topVC = Self.topViewController else {
            let error = NSError(
                domain: "SpananiBridge",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "No active view controller available for confirmation."]
            )
            debugLog("[SpananiBridge] No top view controller to present add source dialog.")
            throw error
        }

        try await AppManager.shared.add(source, presentingViewController: topVC)
        debugLog("[SpananiBridge] addSource() completed successfully for: \(urlString)")
    }

    func removeSource(_ source: SourceItem) async throws {
        debugLog("[SpananiBridge] removeSource() requested for: \(source.id)")
        let context = DatabaseManager.shared.viewContext

        guard let sourceEntity = Source.first(
            satisfying: NSPredicate(format: "%K == %@", #keyPath(Source.identifier), source.id),
            in: context
        ) else {
            let error = NSError(
                domain: "SpananiBridge",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Source “\(source.name)” was not found in the database."]
            )
            debugLog("[SpananiBridge] Source not found for removal: \(source.id)")
            throw error
        }

        guard let topVC = Self.topViewController else {
            let error = NSError(
                domain: "SpananiBridge",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "No active view controller available for confirmation."]
            )
            debugLog("[SpananiBridge] No top view controller to present remove source dialog.")
            throw error
        }

        try await AppManager.shared.remove(sourceEntity, presentingViewController: topVC)
        debugLog("[SpananiBridge] removeSource() completed successfully for: \(source.id)")
    }

    func refreshSources() async {
        debugLog("[SpananiBridge] refreshSources() requested")
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            AppManager.shared.updateAllSources { result in
                switch result {
                case .success:
                    debugLog("[SpananiBridge] updateAllSources() succeeded.")
                case .failure(let error):
                    debugLog("[SpananiBridge] updateAllSources() failed: \(error)")
                }
                continuation.resume()
            }
        }
    }

    func signOut() async {
        // needs proper testing on device
        debugLog("[SpananiBridge] signOut() requested")
        await AuthManager.shared.signOut()
        model.account.appleID = nil
        debugLog("[SpananiBridge] signOut() completed")
    }

    // MARK: - Auto-Refresh & Reminders

    func setAutoRefresh(_ enabled: Bool) async {
        UserDefaults.standard.isBackgroundRefreshEnabled = enabled
        debugLog("[SpananiBridge] setAutoRefresh(\(enabled))")
    }

    func setReminders(_ enabled: Bool) async -> Bool {
        // needs proper testing on device
        debugLog("[SpananiBridge] setReminders(\(enabled)) requested")
        if enabled {
            let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            if granted {
                UserDefaults.standard.set(true, forKey: "spanani.reminders")
                await self.rescheduleReminders(force: true)
                return true
            } else {
                UserDefaults.standard.set(false, forKey: "spanani.reminders")
                await self.removePendingExpiryReminders()
                return false
            }
        } else {
            UserDefaults.standard.set(false, forKey: "spanani.reminders")
            await self.removePendingExpiryReminders()
            return false
        }
    }

    private func removePendingExpiryReminders() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let expiryIdentifiers = pending.map(\.identifier).filter { $0.hasPrefix("spanani.expiry.") }
        if !expiryIdentifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: expiryIdentifiers)
        }
        self.lastReminderSignature = nil
    }

    private func rescheduleReminders(force: Bool = false) async {
        // needs proper testing on device
        guard UserDefaults.standard.bool(forKey: "spanani.reminders") else { return }
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let status = settings.authorizationStatus
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }

        let context = DatabaseManager.shared.viewContext
        let installedApps = InstalledApp.all(in: context)
            .filter { $0.isActive && $0.bundleIdentifier != StoreApp.altstoreAppID }

        let signature = installedApps
            .map { "\($0.bundleIdentifier)\($0.expirationDate.timeIntervalSince1970)" }
            .sorted()
            .joined(separator: "|")

        if !force && signature == self.lastReminderSignature {
            return
        }

        let pending = await center.pendingNotificationRequests()
        let expiryIdentifiers = pending.map(\.identifier).filter { $0.hasPrefix("spanani.expiry.") }
        if !expiryIdentifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: expiryIdentifiers)
        }

        let now = Date()
        for app in installedApps {
            guard app.expirationDate > now else { continue }
            let fireDate = app.expirationDate.addingTimeInterval(-24 * 60 * 60)

            let content = UNMutableNotificationContent()
            content.body = "Open spanani Store and tap Refresh All to keep it running."
            content.sound = .default

            let trigger: UNNotificationTrigger
            if fireDate > now {
                content.title = "\(app.name) expires tomorrow"
                let components = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute, .second],
                    from: fireDate
                )
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            } else {
                content.title = "\(app.name) expires soon"
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
            }

            let identifier = "spanani.expiry.\(app.bundleIdentifier)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }

        self.lastReminderSignature = signature
    }

    // MARK: - Install IPA

    func installIPA(_ url: URL, progress: @escaping (Double) -> Void) async throws {
        if let startError = await AppBootManager.shared.ensureMinimuxerStarted() { throw startError }
        // needs proper testing on device
        debugLog("[SpananiBridge] installIPA() requested for: \(url.path)")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        let box = ProgressBox()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let group = AppManager.shared.install(
                .url(url),
                presentingViewController: Self.topViewController
            ) { result in
                box.observation?.invalidate()
                box.observation = nil

                switch result {
                case .success:
                    debugLog("[SpananiBridge] installIPA succeeded for: \(url.lastPathComponent)")
                    continuation.resume()
                case .failure(let error):
                    debugLog("[SpananiBridge] installIPA failed for: \(url.lastPathComponent), error: \(error)")
                    if error is CancellationError {
                        continuation.resume(throwing: OperationError.cancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                }
            }

            box.observation = group.progress.observe(\.fractionCompleted, options: [.initial, .new]) { p, _ in
                let frac = p.fractionCompleted
                Task { @MainActor in
                    progress(frac)
                }
            }
        }
    }
}

import Foundation
import SwiftUI

@MainActor
public protocol StoreActions: AnyObject {
    func install(_ app: StoreItem, progress: @escaping (Double) -> Void) async throws
    func refresh(_ app: InstalledItem) async throws
    func refreshAll(progress: @escaping (Double) -> Void) async throws
    func open(_ app: InstalledItem)
    func deactivate(_ app: InstalledItem) async throws
    func deleteApp(_ app: InstalledItem) async throws
    func addSource(urlString: String) async throws
    func removeSource(_ source: SourceItem) async throws
    func refreshSources() async
    func signOut() async
    func signIn() async
    func setAutoRefresh(_ enabled: Bool) async
    func setReminders(_ enabled: Bool) async -> Bool
    func installIPA(_ url: URL, progress: @escaping (Double) -> Void) async throws
    func openAnisetteSettings()
}

public extension StoreActions {
    func deleteApp(_ app: InstalledItem) async throws {}
    func addSource(urlString: String) async throws {}
    func removeSource(_ source: SourceItem) async throws {}
    func refreshSources() async {}
    func signOut() async {}
    func signIn() async {}
    func setAutoRefresh(_ enabled: Bool) async {}
    func setReminders(_ enabled: Bool) async -> Bool { enabled }
    func installIPA(_ url: URL, progress: @escaping (Double) -> Void) async throws {}
    func openAnisetteSettings() {}
}

public enum SubmitState: Equatable {
    case idle
    case uploading(Double)
    case done
    case failed(String)
}

@MainActor
public final class StoreModel: ObservableObject {
    @Published public var apps: [StoreItem]
    @Published public var installed: [InstalledItem]
    @Published public var sources: [SourceItem]
    @Published public var changes: [ChangeItem]
    @Published public var favorites: Set<String>
    @Published public var autoRefreshEnabled: Bool
    @Published public var remindersEnabled: Bool
    @Published public var account: AccountInfo
    @Published public var installStates: [String: InstallState]
    @Published public var refreshProgress: Double?
    @Published public var ipaProgress: Double?
    @Published public var ipaName: String?
    @Published public var activeLimit: Int
    @Published public var lastError: String?

    /// Shows an error alert, except for cancellations (the user stopped something on purpose).
    public func report(_ error: Error) {
        guard !Self.isCancellation(error) else { return }
        lastError = error.localizedDescription
    }

    public static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError { return true }
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled { return true }
        // a CancellationError that went through NSError bridging
        return nsError.domain == "Swift.CancellationError"
    }
    @Published public var submitState: SubmitState = .idle

    private static let submitEndpoint = URL(string: "https://store-api.spanani.de/submit")!

    public var actions: StoreActions?

    public init(
        apps: [StoreItem] = [],
        installed: [InstalledItem] = [],
        sources: [SourceItem] = [],
        changes: [ChangeItem] = [],
        account: AccountInfo = AccountInfo(),
        activeLimit: Int = 3,
        favorites: Set<String>? = nil,
        autoRefreshEnabled: Bool = true,
        remindersEnabled: Bool? = nil,
        actions: StoreActions? = nil
    ) {
        self.apps = apps
        self.installed = installed
        self.sources = sources
        self.changes = changes
        self.account = account
        self.installStates = [:]
        self.refreshProgress = nil
        self.ipaProgress = nil
        self.ipaName = nil
        self.activeLimit = activeLimit
        self.lastError = nil
        self.submitState = .idle
        self.actions = actions
        self.autoRefreshEnabled = autoRefreshEnabled

        if let favorites = favorites {
            self.favorites = favorites
        } else {
            let stored = UserDefaults.standard.stringArray(forKey: "spanani.favorites") ?? []
            self.favorites = Set(stored)
        }

        if let remindersEnabled = remindersEnabled {
            self.remindersEnabled = remindersEnabled
        } else {
            if UserDefaults.standard.object(forKey: "spanani.reminders") != nil {
                self.remindersEnabled = UserDefaults.standard.bool(forKey: "spanani.reminders")
            } else {
                self.remindersEnabled = true
            }
        }
    }

    public var categories: [String] {
        var seen = Set<String>()
        var list: [String] = []
        for app in apps {
            if !seen.contains(app.category) {
                seen.insert(app.category)
                list.append(app.category)
            }
        }
        return list
    }

    public var featured: [StoreItem] {
        apps.filter { $0.isFeatured }
    }

    public var newest: [StoreItem] {
        Array(apps.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }.prefix(9))
    }

    public var communityApps: [StoreItem] {
        apps.filter { $0.isCommunity }
    }

    public func apps(in category: String) -> [StoreItem] {
        apps.filter { $0.category == category }
    }

    public var recent: [StoreItem] {
        Array(apps.prefix(6))
    }

    public var activeCount: Int {
        installed.filter { $0.isActive }.count
    }

    public var soonestExpiringItem: InstalledItem? {
        installed.min(by: { $0.expiresAt < $1.expiresAt })
    }

    public var favoriteApps: [StoreItem] {
        apps.filter { favorites.contains($0.id) }
    }

    public func isFavorite(_ id: String) -> Bool {
        favorites.contains(id)
    }

    public func toggleFavorite(_ id: String) {
        if favorites.contains(id) {
            favorites.remove(id)
        } else {
            favorites.insert(id)
        }
        UserDefaults.standard.set(Array(favorites), forKey: "spanani.favorites")
        Haptics.selection()
    }

    public func setAutoRefresh(_ on: Bool) {
        autoRefreshEnabled = on
        Task {
            await actions?.setAutoRefresh(on)
        }
    }

    public func setReminders(_ on: Bool) {
        Haptics.selection()
        Task {
            let result = await actions?.setReminders(on) ?? on
            remindersEnabled = result
            UserDefaults.standard.set(result, forKey: "spanani.reminders")
            if result != on {
                lastError = "Notifications are turned off for this app. Enable them in iOS Settings."
            }
        }
    }

    public func installIPA(_ url: URL) {
        ipaName = url.lastPathComponent
        ipaProgress = 0
        Haptics.impact(.medium)
        Task {
            do {
                if let actions = self.actions {
                    try await actions.installIPA(url) { [weak self] progress in
                        Task { @MainActor in
                            self?.ipaProgress = progress
                        }
                    }
                } else {
                    let steps = 10
                    for step in 1...steps {
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        self.ipaProgress = Double(step) / Double(steps)
                    }
                }
                Haptics.notify(.success)
            } catch {
                self.report(error)
                Haptics.notify(.error)
            }
            self.ipaProgress = nil
            self.ipaName = nil
        }
    }

    public func state(for app: StoreItem) -> InstallState {
        if let state = installStates[app.id] {
            return state
        }
        if let installedItem = installed.first(where: { $0.id == app.id }) {
            return installedItem.hasUpdate ? .updateAvailable : .installed
        }
        return .idle
    }

    public func install(_ app: StoreItem) {
        installStates[app.id] = .installing(progress: 0.0)
        Haptics.impact(.medium)

        Task {
            if let actions = self.actions {
                do {
                    try await actions.install(app) { [weak self] progress in
                        Task { @MainActor in
                            self?.installStates[app.id] = .installing(progress: progress)
                        }
                    }
                    self.installStates.removeValue(forKey: app.id)
                    if let idx = self.installed.firstIndex(where: { $0.id == app.id }) {
                        self.installed[idx].versionString = app.versionString
                        self.installed[idx].hasUpdate = false
                        self.installed[idx].expiresAt = Date().addingTimeInterval(7 * 24 * 3600)
                    } else {
                        let newItem = InstalledItem(
                            id: app.id,
                            name: app.name,
                            versionString: app.versionString,
                            tint: app.tint,
                            symbol: app.symbol,
                            iconURL: app.iconURL,
                            expiresAt: Date().addingTimeInterval(7 * 24 * 3600),
                            isActive: true,
                            hasUpdate: false,
                            latestVersion: nil
                        )
                        self.installed.append(newItem)
                    }
                    Haptics.notify(.success)
                } catch let error where Self.isCancellation(error) {
                    // the user stopped the download: back to "Get", no alert
                    self.installStates.removeValue(forKey: app.id)
                } catch {
                    self.installStates[app.id] = .failed(error.localizedDescription)
                    self.report(error)
                    Haptics.notify(.error)
                }
            } else {
                let steps = 11
                for step in 1...steps {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    let p = Double(step) / Double(steps)
                    self.installStates[app.id] = .installing(progress: p)
                }
                self.installStates.removeValue(forKey: app.id)
                if let idx = self.installed.firstIndex(where: { $0.id == app.id }) {
                    self.installed[idx].versionString = app.versionString
                    self.installed[idx].hasUpdate = false
                    self.installed[idx].expiresAt = Date().addingTimeInterval(7 * 24 * 3600)
                } else {
                    let newItem = InstalledItem(
                        id: app.id,
                        name: app.name,
                        versionString: app.versionString,
                        tint: app.tint,
                        symbol: app.symbol,
                        iconURL: app.iconURL,
                        expiresAt: Date().addingTimeInterval(7 * 24 * 3600),
                        isActive: true,
                        hasUpdate: false,
                        latestVersion: nil
                    )
                    self.installed.append(newItem)
                }
                Haptics.notify(.success)
            }
        }
    }

    public func refresh(_ item: InstalledItem) {
        Haptics.impact(.medium)
        Task {
            if let actions = self.actions {
                do {
                    try await actions.refresh(item)
                    if let idx = self.installed.firstIndex(where: { $0.id == item.id }) {
                        self.installed[idx].expiresAt = Date().addingTimeInterval(7 * 24 * 3600)
                    }
                    Haptics.notify(.success)
                } catch {
                    self.report(error)
                    Haptics.notify(.error)
                }
            } else {
                try? await Task.sleep(nanoseconds: 600_000_000)
                if let idx = self.installed.firstIndex(where: { $0.id == item.id }) {
                    self.installed[idx].expiresAt = Date().addingTimeInterval(7 * 24 * 3600)
                }
                Haptics.notify(.success)
            }
        }
    }

    public func refreshAll() {
        guard refreshProgress == nil else { return }
        refreshProgress = 0.0
        Haptics.impact(.medium)

        Task {
            if let actions = self.actions {
                do {
                    try await actions.refreshAll { [weak self] progress in
                        Task { @MainActor in
                            self?.refreshProgress = progress
                        }
                    }
                    for i in 0..<self.installed.count {
                        self.installed[i].expiresAt = Date().addingTimeInterval(7 * 24 * 3600)
                    }
                    self.refreshProgress = nil
                    Haptics.notify(.success)
                } catch {
                    self.report(error)
                    self.refreshProgress = nil
                    Haptics.notify(.error)
                }
            } else {
                let steps = 10
                for step in 1...steps {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    self.refreshProgress = Double(step) / Double(steps)
                }
                for i in 0..<self.installed.count {
                    self.installed[i].expiresAt = Date().addingTimeInterval(7 * 24 * 3600)
                }
                self.refreshProgress = nil
                Haptics.notify(.success)
            }
        }
    }

    public func open(_ item: InstalledItem) {
        Haptics.impact(.light)
        actions?.open(item)
    }

    public func deactivate(_ item: InstalledItem) {
        Haptics.impact(.medium)
        Task {
            if let actions = self.actions {
                do {
                    try await actions.deactivate(item)
                    if let idx = self.installed.firstIndex(where: { $0.id == item.id }) {
                        self.installed[idx].isActive.toggle()
                    }
                    Haptics.notify(.success)
                } catch {
                    self.report(error)
                    Haptics.notify(.error)
                }
            } else {
                if let idx = self.installed.firstIndex(where: { $0.id == item.id }) {
                    self.installed[idx].isActive.toggle()
                }
                Haptics.notify(.success)
            }
        }
    }

    public func delete(_ item: InstalledItem) {
        Haptics.impact(.medium)
        Task {
            if let actions = self.actions {
                do {
                    try await actions.deleteApp(item)
                    self.installed.removeAll { $0.id == item.id }
                    Haptics.notify(.success)
                } catch {
                    self.report(error)
                    Haptics.notify(.error)
                }
            } else {
                self.installed.removeAll { $0.id == item.id }
                Haptics.notify(.success)
            }
        }
    }

    public func addSource(_ urlString: String) {
        Task {
            do {
                try await addSourceAsync(urlString)
            } catch {
                self.report(error)
                Haptics.notify(.error)
            }
        }
    }

    public func addSource(_ urlString: String) async throws {
        try await addSourceAsync(urlString)
    }

    private func addSourceAsync(_ urlString: String) async throws {
        Haptics.impact(.medium)
        if let actions = self.actions {
            try await actions.addSource(urlString: urlString)
            Haptics.notify(.success)
        } else {
            let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let url = URL(string: trimmed), let host = url.host, !host.isEmpty else {
                throw NSError(
                    domain: "SpananiUI",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid URL. Enter a complete address."]
                )
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            let newSource = SourceItem(
                name: host.capitalized,
                url: trimmed,
                appCount: 0,
                tint: .accentColor
            )
            self.sources.append(newSource)
            Haptics.notify(.success)
        }
    }

    public func removeSource(_ source: SourceItem) {
        Haptics.impact(.medium)
        Task {
            if let actions = self.actions {
                do {
                    try await actions.removeSource(source)
                    self.sources.removeAll { $0.id == source.id }
                    Haptics.notify(.success)
                } catch {
                    self.report(error)
                    Haptics.notify(.error)
                }
            } else {
                try? await Task.sleep(nanoseconds: 200_000_000)
                self.sources.removeAll { $0.id == source.id }
                Haptics.notify(.success)
            }
        }
    }

    public func reloadSources() {
        Task {
            await reloadSourcesAsync()
        }
    }

    public func reloadSources() async {
        await reloadSourcesAsync()
    }

    private func reloadSourcesAsync() async {
        Haptics.impact(.light)
        if let actions = self.actions {
            await actions.refreshSources()
            Haptics.notify(.success)
        } else {
            try? await Task.sleep(nanoseconds: 500_000_000)
            Haptics.notify(.success)
        }
    }

    public func signOut() {
        Haptics.impact(.medium)
        Task {
            if let actions = self.actions {
                await actions.signOut()
            }
            self.account.appleID = nil
            Haptics.notify(.success)
        }
    }

    public func signIn() {
        Haptics.impact(.medium)
        Task {
            await self.actions?.signIn()
        }
    }

    public func openAnisetteSettings() {
        Haptics.impact(.light)
        actions?.openAnisetteSettings()
    }

    public func submit(fileURL: URL, appName: String, note: String) {
        submitState = .uploading(0.0)
        Haptics.impact(.medium)

        Task {
            let hasAccess = fileURL.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }

            guard fileURL.pathExtension.lowercased() == "ipa" else {
                self.submitState = .failed("The file must be an .ipa file.")
                Haptics.notify(.error)
                return
            }

            let fileSize: Int64
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = resourceValues.fileSize {
                fileSize = Int64(size)
            } else if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                      let size = attrs[.size] as? Int64 {
                fileSize = size
            } else {
                self.submitState = .failed("Could not determine file size.")
                Haptics.notify(.error)
                return
            }

            let minSize: Int64 = 1024
            let maxSize: Int64 = 104_857_600

            guard fileSize >= minSize else {
                self.submitState = .failed("The file is too small (minimum 1 KB).")
                Haptics.notify(.error)
                return
            }

            guard fileSize <= maxSize else {
                self.submitState = .failed("The file exceeds the 100 MB limit.")
                Haptics.notify(.error)
                return
            }

            var request = URLRequest(url: Self.submitEndpoint)
            request.httpMethod = "POST"
            request.timeoutInterval = 600
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

            let rawFileName = fileURL.lastPathComponent
            let encodedFileName = rawFileName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? rawFileName
            request.setValue(encodedFileName, forHTTPHeaderField: "X-File-Name")

            let trimmedAppName = appName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedAppName.isEmpty {
                let truncated = String(trimmedAppName.prefix(60))
                let encoded = truncated.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? truncated
                request.setValue(encoded, forHTTPHeaderField: "X-App-Name")
            }

            let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedNote.isEmpty {
                let truncated = String(trimmedNote.prefix(300))
                let encoded = truncated.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? truncated
                request.setValue(encoded, forHTTPHeaderField: "X-Note")
            }

            // Upload task delegate tracking progress; needs proper testing with varied network speeds
            let progressDelegate = SubmitProgressDelegate { [weak self] fraction in
                Task { @MainActor in
                    guard let self = self else { return }
                    if case .uploading = self.submitState {
                        self.submitState = .uploading(min(max(fraction, 0.0), 1.0))
                    }
                }
            }

            do {
                let (data, response) = try await URLSession.shared.upload(
                    for: request,
                    fromFile: fileURL,
                    delegate: progressDelegate
                )

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.submitState = .failed("Upload failed. Check your connection and try again.")
                    Haptics.notify(.error)
                    return
                }

                if httpResponse.statusCode == 200 {
                    self.submitState = .done
                    Haptics.notify(.success)
                } else {
                    struct ErrorResponse: Decodable {
                        let error: String?
                    }
                    let errorMessage: String
                    if let decoded = try? JSONDecoder().decode(ErrorResponse.self, from: data),
                       let serverError = decoded.error,
                       !serverError.isEmpty {
                        errorMessage = serverError
                    } else {
                        errorMessage = "Upload failed. Check your connection and try again."
                    }
                    self.submitState = .failed(errorMessage)
                    Haptics.notify(.error)
                }
            } catch {
                self.submitState = .failed("Upload failed. Check your connection and try again.")
                Haptics.notify(.error)
            }
        }
    }

    public func resetSubmit() {
        submitState = .idle
    }
}

private final class SubmitProgressDelegate: NSObject, URLSessionTaskDelegate, Sendable {
    private let onProgress: @Sendable (Double) -> Void

    init(onProgress: @escaping @Sendable (Double) -> Void) {
        self.onProgress = onProgress
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        guard totalBytesExpectedToSend > 0 else { return }
        let fraction = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        onProgress(fraction)
    }
}

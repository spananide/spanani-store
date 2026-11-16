import Foundation
import SwiftUI

@MainActor
public protocol StoreActions: AnyObject {
    func install(_ app: StoreItem, progress: @escaping (Double) -> Void) async throws
    func refresh(_ app: InstalledItem) async throws
    func refreshAll(progress: @escaping (Double) -> Void) async throws
    func open(_ app: InstalledItem)
    func deactivate(_ app: InstalledItem) async throws
}

@MainActor
public final class StoreModel: ObservableObject {
    @Published public var apps: [StoreItem]
    @Published public var installed: [InstalledItem]
    @Published public var sources: [SourceItem]
    @Published public var account: AccountInfo
    @Published public var installStates: [String: InstallState]
    @Published public var refreshProgress: Double?
    @Published public var activeLimit: Int

    public var actions: StoreActions?

    public init(
        apps: [StoreItem] = [],
        installed: [InstalledItem] = [],
        sources: [SourceItem] = [],
        account: AccountInfo = AccountInfo(),
        activeLimit: Int = 3,
        actions: StoreActions? = nil
    ) {
        self.apps = apps
        self.installed = installed
        self.sources = sources
        self.account = account
        self.installStates = [:]
        self.refreshProgress = nil
        self.activeLimit = activeLimit
        self.actions = actions
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

    public var recent: [StoreItem] {
        Array(apps.prefix(6))
    }

    public var activeCount: Int {
        installed.filter { $0.isActive }.count
    }

    public var soonestExpiringItem: InstalledItem? {
        installed.min(by: { $0.expiresAt < $1.expiresAt })
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
                } catch {
                    self.installStates[app.id] = .failed(error.localizedDescription)
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
}

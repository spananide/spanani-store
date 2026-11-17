import SwiftUI

struct MyAppsView: View {
    @EnvironmentObject private var model: StoreModel
    var onNavigateToTab: ((Int) -> Void)? = nil

    private var soonestText: String {
        if let soonest = model.soonestExpiringItem {
            return Formatters.expiryRemainingText(expiresAt: soonest.expiresAt)
        }
        return "in 7 days"
    }

    private var appsWithUpdates: [InstalledItem] {
        model.installed.filter { $0.hasUpdate }
    }

    var body: some View {
        Group {
            if model.installed.isEmpty {
                ContentUnavailableView {
                    Label("No Apps Installed", systemImage: "arrow.down.app")
                } description: {
                    Text("Apps you get from Discover appear here.")
                } actions: {
                    Button("Browse Apps") {
                        Haptics.impact(.medium)
                        onNavigateToTab?(0)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    Section {
                        LabeledContent("Next Refresh", value: soonestText)

                        VStack(alignment: .leading, spacing: Spacing.s) {
                            LabeledContent("Active Apps", value: "\(model.activeCount) of \(model.activeLimit)")
                            ProgressView(
                                value: Double(model.activeCount),
                                total: Double(max(model.activeLimit, 1))
                            )
                        }

                        if let progress = model.refreshProgress {
                            HStack(spacing: Spacing.s) {
                                ProgressView(value: progress)
                                Text("Refreshing … \(Int(progress * 100)) %")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Button("Refresh All") {
                                model.refreshAll()
                            }
                        }
                    } header: {
                        Text("Status")
                    } footer: {
                        Text("Free Apple ID: up to 3 active apps, valid for 7 days.")
                    }

                    if !appsWithUpdates.isEmpty {
                        Section("Updates") {
                            ForEach(appsWithUpdates) { item in
                                let storeApp = model.apps.first { $0.id == item.id }
                                HStack(spacing: Spacing.m) {
                                    AppIconView(
                                        tint: item.tint,
                                        symbol: item.symbol,
                                        iconURL: item.iconURL,
                                        size: 44
                                    )

                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        Text(item.name)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                        Text("\(item.versionString) → \(item.latestVersion ?? "New")")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    InstallButton(
                                        state: .updateAvailable,
                                        action: {
                                            if let storeApp {
                                                model.install(storeApp)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }

                    Section("Installed") {
                        ForEach(model.installed) { item in
                            HStack(spacing: Spacing.m) {
                                AppIconView(
                                    tint: item.tint,
                                    symbol: item.symbol,
                                    iconURL: item.iconURL,
                                    size: 48
                                )

                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    HStack(spacing: Spacing.xs) {
                                        Text(item.name)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)

                                        if !item.isActive {
                                            Text("Inactive")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Text(Formatters.expiryRowText(expiresAt: item.expiresAt))
                                        .font(.footnote)
                                        .foregroundStyle(Formatters.urgencyColor(expiresAt: item.expiresAt))

                                    Text("Version \(item.versionString)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Menu {
                                    Button {
                                        model.refresh(item)
                                    } label: {
                                        Label("Refresh", systemImage: "arrow.clockwise")
                                    }

                                    Button {
                                        model.open(item)
                                    } label: {
                                        Label("Open", systemImage: "arrow.up.forward.app")
                                    }

                                    Button {
                                        model.deactivate(item)
                                    } label: {
                                        Label(
                                            item.isActive ? "Deactivate" : "Activate",
                                            systemImage: item.isActive ? "pause.circle" : "play.circle"
                                        )
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .frame(minWidth: 44, minHeight: 44)
                                        .contentShape(Rectangle())
                                }
                                .accessibilityLabel("Actions")
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    model.refresh(item)
                                } label: {
                                    Label("Refresh", systemImage: "arrow.clockwise")
                                }
                            }
                            .contextMenu {
                                Button {
                                    model.refresh(item)
                                } label: {
                                    Label("Refresh", systemImage: "arrow.clockwise")
                                }

                                Button {
                                    model.open(item)
                                } label: {
                                    Label("Open", systemImage: "arrow.up.forward.app")
                                }

                                Button {
                                    model.deactivate(item)
                                } label: {
                                    Label(
                                        item.isActive ? "Deactivate" : "Activate",
                                        systemImage: item.isActive ? "pause.circle" : "play.circle"
                                    )
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("My Apps")
    }
}

import SwiftUI

struct MyAppsView: View {
    @EnvironmentObject private var model: StoreModel
    var selectedApp: Binding<StoreItem?>? = nil
    var onNavigateToTab: ((Int) -> Void)? = nil

    @State private var internalSelectedApp: StoreItem? = nil

    private var appsWithUpdates: [InstalledItem] {
        model.installed.filter { $0.hasUpdate }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                if model.installed.isEmpty {
                    emptyStateView
                } else {
                    CountdownHeroView()

                    if !model.favoriteApps.isEmpty {
                        favoritesSection
                    }

                    if !appsWithUpdates.isEmpty {
                        updatesSection
                    }

                    installedSection
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .refreshable {
            await model.reloadSources()
        }
        .background(Color.paper)
        .sheet(item: $internalSelectedApp) { app in
            AppDetailView(app: app)
                .environmentObject(model)
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("My Apps")
                    .font(.brand(34, .extrabold))
                    .foregroundColor(.ink)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Favorites Section

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Favourites", count: model.favoriteApps.count)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(model.favoriteApps) { app in
                        Button {
                            if let binding = selectedApp {
                                binding.wrappedValue = app
                            } else {
                                internalSelectedApp = app
                            }
                        } label: {
                            VStack(spacing: 8) {
                                AppIconView(
                                    tint: app.tint,
                                    symbol: app.symbol,
                                    iconURL: app.iconURL,
                                    size: 72
                                )

                                Text(app.name)
                                    .font(.brand(13, .semibold))
                                    .foregroundColor(.ink)
                                    .lineLimit(1)
                                    .frame(width: 76)
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                model.toggleFavorite(app.id)
                            } label: {
                                Label("Remove from Favourites", systemImage: "star.slash")
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Updates Section

    private var updatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Updates", count: appsWithUpdates.count)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(appsWithUpdates) { item in
                    UpdateAppRowView(item: item)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Installed Section

    private var installedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Installed", count: model.installed.count)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(model.installed) { item in
                    InstalledAppRowView(item: item)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 32)

            Mark3DTile(size: 120)

            Text("Nothing installed yet")
                .font(.brand(24, .extrabold))
                .foregroundColor(.ink)

            Text("Get an app from Discover and it shows up here with a countdown.")
                .font(.system(size: 14))
                .foregroundColor(.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Button {
                Haptics.impact(.medium)
                onNavigateToTab?(0)
            } label: {
                Text("Browse apps")
                    .font(.brand(15, .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 48)
                    .background(Color.brand)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Countdown Hero View

private struct CountdownHeroView: View {
    @EnvironmentObject private var model: StoreModel

    private var soonest: InstalledItem? {
        model.soonestExpiringItem
    }

    private var countdownText: String {
        if let soonest = soonest {
            return Formatters.countdownText(expiresAt: soonest.expiresAt)
        }
        return "None"
    }

    private var urgencyColor: Color {
        if let soonest = soonest {
            return Formatters.urgencyColor(expiresAt: soonest.expiresAt)
        }
        return .ink
    }

    private var soonestAppName: String {
        soonest?.name ?? "No apps installed"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next expiry")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.inkSoft)

                    Text(countdownText)
                        .font(.brand(56, .extrabold))
                        .foregroundColor(urgencyColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(soonestAppName)
                        .font(.system(size: 14))
                        .foregroundColor(.inkSoft)
                        .lineLimit(1)
                }

                Spacer()

                Mark3DTile(size: 56)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(0..<model.activeLimit, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(index < model.activeCount ? Color.brand : Color.paperSunk)
                            .frame(height: 8)
                    }
                }

                Text("\(model.activeCount) of \(model.activeLimit) slots in use")
                    .font(.brand(13, .semibold))
                    .foregroundColor(.inkSoft)
            }

            refreshButtonArea

            Text("Free Apple ID: 3 active apps, 7 days each.")
                .font(.system(size: 12))
                .foregroundColor(.inkFaint)
        }
        .padding(20)
        .background(Color.paperRaised)
        .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SpananiRadius.card, style: .continuous)
                .stroke(Color.paperSunk, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var refreshButtonArea: some View {
        if let progress = model.refreshProgress {
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .brand))
                    .scaleEffect(0.8)

                Text("Refreshing … \(Int(progress * 100)) %")
                    .font(.brand(15, .semibold))
                    .foregroundColor(.brand)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.paperSunk)
            .clipShape(Capsule())
        } else {
            Button {
                model.refreshAll()
            } label: {
                Text("Refresh All")
                    .font(.brand(16, .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.brand)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Update App Row View

private struct UpdateAppRowView: View {
    @EnvironmentObject private var model: StoreModel
    let item: InstalledItem

    private var storeApp: StoreItem? {
        model.apps.first { $0.id == item.id }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                AppIconView(
                    tint: item.tint,
                    symbol: item.symbol,
                    iconURL: item.iconURL,
                    size: 50
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.brand(16, .semibold))
                        .foregroundColor(.ink)

                    Text("\(item.versionString) → \(item.latestVersion ?? "New")")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.accent)
                }

                Spacer()

                InstallButton(
                    state: .updateAvailable,
                    minHeight: 32,
                    fontSize: 14
                ) {
                    if let app = storeApp {
                        model.install(app)
                    }
                }
            }
            .padding(.vertical, 12)

            Rectangle()
                .fill(Color.paperSunk)
                .frame(height: 1)
                .padding(.leading, 64)
        }
    }
}

// MARK: - Installed App Row View

private struct InstalledAppRowView: View {
    @EnvironmentObject private var model: StoreModel
    let item: InstalledItem
    @State private var confirmDelete = false

    // The store cannot delete itself.
    private var canDelete: Bool { !item.id.hasPrefix("de.spanani.store") }

    private var daysLeft: Double {
        max(0, item.expiresAt.timeIntervalSinceNow / 86400.0)
    }

    private var rowExpiryLabel: String {
        Formatters.expiryRowText(expiresAt: item.expiresAt)
    }

    private var rowUrgencyColor: Color {
        Formatters.urgencyColor(expiresAt: item.expiresAt)
    }

    private var progressRatio: CGFloat {
        CGFloat(min(max(daysLeft / 7.0, 0.0), 1.0))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                AppIconView(
                    tint: item.tint,
                    symbol: item.symbol,
                    iconURL: item.iconURL,
                    size: 56
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(item.name)
                            .font(.brand(17, .semibold))
                            .foregroundColor(.ink)

                        if !item.isActive {
                            Text("Inactive")
                                .font(.brand(10, .semibold))
                                .foregroundColor(.inkFaint)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.paperSunk)
                                .clipShape(Capsule())
                        }
                    }

                    Text(rowExpiryLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(rowUrgencyColor)

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.paperSunk)
                            .frame(width: 130, height: 4)

                        Capsule()
                            .fill(rowUrgencyColor)
                            .frame(width: max(6, 130 * progressRatio), height: 4)
                    }

                    Text("Version \(item.versionString)")
                        .font(.system(size: 12))
                        .foregroundColor(.inkFaint)
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

                    if canDelete {
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.inkSoft)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Actions for \(item.name)")
            }
            .padding(.vertical, 12)
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

                if canDelete {
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            Rectangle()
                .fill(Color.paperSunk)
                .frame(height: 1)
                .padding(.leading, 70)
        }
        .confirmationDialog(
            "Delete \(item.name)?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                model.delete(item)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The app and its data are removed from this iPhone.")
        }
    }
}

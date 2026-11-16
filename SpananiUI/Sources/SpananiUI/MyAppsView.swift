import SwiftUI

struct MyAppsView: View {
    @EnvironmentObject private var model: StoreModel
    var onNavigateToTab: ((Int) -> Void)? = nil

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
                    SummaryCardView()

                    if !appsWithUpdates.isEmpty {
                        updatesSection
                    }

                    installedSection
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
        .background(Color.paper)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Übersicht")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.inkSoft)

                Text("Meine Apps")
                    .font(.brand(38, .extrabold))
                    .foregroundColor(.ink)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Updates Section

    private var updatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Updates",
                subtitle: "\(appsWithUpdates.count) Aktualisierungen verfügbar"
            )
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
            SectionHeader(
                title: "Installiert",
                subtitle: "\(model.installed.count) Apps auf diesem Gerät"
            )
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
                .frame(height: 40)

            SpananiLogo.markImage()
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.brand)
                .opacity(0.8)

            Text("Noch nichts installiert")
                .font(.brand(24, .extrabold))
                .foregroundColor(.ink)

            Text("Lade Apps aus dem Katalog herunter, um sie direkt auf deinem Gerät auszuführen.")
                .font(.system(size: 14))
                .foregroundColor(.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Button {
                Haptics.impact(.medium)
                onNavigateToTab?(0)
            } label: {
                Text("Zu Entdecken")
                    .font(.brand(15, .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
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

// MARK: - Summary Card View

private struct SummaryCardView: View {
    @EnvironmentObject private var model: StoreModel

    private var soonestDaysLeft: Double {
        if let soonest = model.soonestExpiringItem {
            return max(0, soonest.expiresAt.timeIntervalSinceNow / 86400.0)
        }
        return 7.0
    }

    private var soonestText: String {
        if let soonest = model.soonestExpiringItem {
            return Formatters.expiryRemainingText(expiresAt: soonest.expiresAt)
        }
        return "in 7 Tagen"
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            cardBackground
            cardWatermark

            VStack(alignment: .leading, spacing: 20) {
                topRow
                bottomSlotRow
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SpananiRadius.card, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .softShadow(color: Color.black.opacity(0.24), radius: 18, x: 0, y: 8)
        .padding(.horizontal, 20)
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: [
                Color.brand.opacity(0.40),
                Color.paperRaised
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardWatermark: some View {
        SpananiLogo.markImage()
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 170, height: 170)
            .foregroundColor(.white)
            .opacity(0.07)
            .rotationEffect(.degrees(-12))
            .offset(x: 30, y: 40)
    }

    private var topRow: some View {
        HStack(spacing: 16) {
            ExpiryRing(daysLeft: soonestDaysLeft, size: 84)

            VStack(alignment: .leading, spacing: 6) {
                Text("Nächste Auffrischung")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.inkSoft)

                Text(soonestText)
                    .font(.brand(24, .extrabold))
                    .foregroundColor(.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                refreshButton
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var refreshButton: some View {
        if let progress = model.refreshProgress {
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .brand))
                    .scaleEffect(0.8)

                Text("Aktualisiere … \(Int(progress * 100)) %")
                    .font(.brand(13, .semibold))
                    .foregroundColor(.brand)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.paperSunk)
            .clipShape(Capsule())
        } else {
            Button {
                model.refreshAll()
            } label: {
                Text("Alle auffrischen")
                    .font(.brand(14, .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Color.brand)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var bottomSlotRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            HStack {
                SlotDots(active: model.activeCount, limit: model.activeLimit)
                Spacer()
            }

            Text("Kostenlose Apple-ID: max. 3 aktive Apps, 7 Tage gültig.")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.inkFaint)
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

                    Text("\(item.versionString) → \(item.latestVersion ?? "Neu")")
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

    private var daysLeft: Double {
        max(0, item.expiresAt.timeIntervalSinceNow / 86400.0)
    }

    private var rowExpiryLabel: String {
        Formatters.expiryRowText(expiresAt: item.expiresAt)
    }

    private var rowUrgencyColor: Color {
        Formatters.urgencyColor(expiresAt: item.expiresAt)
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

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(item.name)
                            .font(.brand(17, .semibold))
                            .foregroundColor(.ink)

                        if !item.isActive {
                            Text("Inaktiv")
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

                    Text("Version \(item.versionString)")
                        .font(.system(size: 12))
                        .foregroundColor(.inkFaint)
                }

                Spacer()

                ExpiryRing(daysLeft: daysLeft, size: 44)

                Menu {
                    Button {
                        model.refresh(item)
                    } label: {
                        Label("Auffrischen", systemImage: "arrow.clockwise")
                    }

                    Button {
                        model.open(item)
                    } label: {
                        Label("Öffnen", systemImage: "arrow.up.forward.app")
                    }

                    Button {
                        model.deactivate(item)
                    } label: {
                        Label(
                            item.isActive ? "Deaktivieren" : "Aktivieren",
                            systemImage: item.isActive ? "pause.circle" : "play.circle"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.inkSoft)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
            }
            .padding(.vertical, 12)

            Rectangle()
                .fill(Color.paperSunk)
                .frame(height: 1)
                .padding(.leading, 70)
        }
    }
}

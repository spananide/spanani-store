import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var model: StoreModel
    @Binding var selectedApp: StoreItem?
    var onNavigateToTab: ((Int) -> Void)? = nil

    @State private var searchText: String = ""
    @State private var selectedCategory: String = "Alle"
    @State private var scrolledHeroID: String?

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var currentHeroIndex: Int {
        if let id = scrolledHeroID,
           let idx = model.featured.firstIndex(where: { $0.id == id }) {
            return idx
        }
        return 0
    }

    private var filteredApps: [StoreItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            if selectedCategory == "Alle" {
                return model.apps
            } else {
                return model.apps.filter { $0.category == selectedCategory }
            }
        } else {
            return model.apps.filter { app in
                app.name.lowercased().contains(query)
                    || app.subtitle.lowercased().contains(query)
                    || app.developer.lowercased().contains(query)
            }
        }
    }

    private var railApps: [StoreItem] {
        if selectedCategory == "Alle" {
            return model.recent
        } else {
            return model.apps.filter { $0.category == selectedCategory }
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                searchSection

                if isSearching {
                    searchResultsSection
                } else {
                    mainDiscoveryContent
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .refreshable {
            await model.reloadSources()
        }
        .background(Color.paper)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Formatters.germanDate())
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.inkSoft)

                Text("Entdecken")
                    .font(.brand(38, .extrabold))
                    .foregroundColor(.ink)
            }

            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.brand)
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.brand.opacity(0.35), radius: 8, x: 0, y: 4)

                SpananiLogo.markImage()
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Search Section

    private var searchSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.inkSoft)

            TextField("Apps suchen", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(.ink)
                .autocorrectionDisabled(true)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.inkFaint)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.paperSunk)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Search Results Section

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Ergebnisse",
                subtitle: filteredApps.count == 1
                    ? "1 App gefunden"
                    : "\(filteredApps.count) Apps gefunden"
            )
            .padding(.horizontal, 20)

            if filteredApps.isEmpty {
                emptySearchPlaceholder
            } else {
                VStack(spacing: 0) {
                    ForEach(filteredApps) { app in
                        AppRowView(app: app) {
                            selectedApp = app
                        } onInstall: {
                            model.install(app)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var emptySearchPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(.inkFaint)
                .padding(.bottom, 4)

            Text("Keine Apps gefunden")
                .font(.brand(18, .semibold))
                .foregroundColor(.ink)

            Text("Versuche es mit einem anderen Suchbegriff.")
                .font(.system(size: 14))
                .foregroundColor(.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Main Discovery Content

    private var mainDiscoveryContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            heroSection
            categorySection
            railSection
            allAppsSection
        }
    }

    // MARK: - Hero Carousel

    private var heroSection: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(model.featured) { app in
                        HeroCardView(app: app) {
                            selectedApp = app
                        } onInstall: {
                            model.install(app)
                        }
                        .id(app.id)
                    }
                }
                .padding(.horizontal, 20)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrolledHeroID)

            if model.featured.count > 1 {
                heroIndicatorDots
            }
        }
    }

    private var heroIndicatorDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<model.featured.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentHeroIndex ? Color.brand : Color.paperSunk)
                    .frame(width: index == currentHeroIndex ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.3), value: currentHeroIndex)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Category Section

    private var categorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    title: "Alle",
                    isSelected: selectedCategory == "Alle"
                ) {
                    Haptics.selection()
                    selectedCategory = "Alle"
                }

                ForEach(model.categories, id: \.self) { category in
                    CategoryChip(
                        title: category,
                        isSelected: selectedCategory == category
                    ) {
                        Haptics.selection()
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Rail Section

    private var railSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Neu & aktualisiert",
                subtitle: "Kuratierte Highlights der Redaktion"
            )
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(railApps) { app in
                        RailCardView(app: app) {
                            selectedApp = app
                        } onInstall: {
                            model.install(app)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - All Apps Section

    private var allAppsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Alle Apps",
                subtitle: filteredApps.count == 1
                    ? "1 verfügbare Anwendung"
                    : "\(filteredApps.count) verfügbare Anwendungen"
            )
            .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(filteredApps) { app in
                    AppRowView(app: app) {
                        selectedApp = app
                    } onInstall: {
                        model.install(app)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Hero Card View

private struct HeroCardView: View {
    @EnvironmentObject private var model: StoreModel
    let app: StoreItem
    var onSelect: () -> Void
    var onInstall: () -> Void

    private var cardWidth: CGFloat {
        min(max(UIScreen.main.bounds.width * 0.86, 300.0), 360.0)
    }

    var body: some View {
        Button(action: onSelect) {
            cardContent
        }
        .buttonStyle(.plain)
        .scrollTransition(axis: .horizontal) { content, phase in
            content
                .scaleEffect(phase.isIdentity ? 1.0 : 0.92)
                .opacity(phase.isIdentity ? 1.0 : 0.70)
        }
    }

    private var cardContent: some View {
        ZStack(alignment: .bottomLeading) {
            cardBackground
            watermarkLogo

            VStack(alignment: .leading, spacing: 0) {
                taglinePill
                Spacer()
                floatingIcon
                Spacer()
                detailsSection
            }
            .padding(22)
        }
        .frame(width: cardWidth, height: 400)
        .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.card, style: .continuous))
        .overlay(cardBorder)
        .softShadow(color: Color.black.opacity(0.24), radius: 18, x: 0, y: 8)
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: [
                app.tint.opacity(0.75),
                Color.paperRaised
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var watermarkLogo: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                SpananiLogo.markImage()
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 210, height: 210)
                    .foregroundColor(.white)
                    .opacity(0.08)
                    .rotationEffect(.degrees(-12))
                    .offset(x: 40, y: 50)
            }
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: SpananiRadius.card, style: .continuous)
            .stroke(Color.white.opacity(0.12), lineWidth: 1)
    }

    private var taglinePill: some View {
        Text(app.heroTagline.uppercased())
            .font(.brand(12, .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.28))
            .clipShape(Capsule())
    }

    private var floatingIcon: some View {
        HStack {
            Spacer()
            AppIconView(
                tint: app.tint,
                symbol: app.symbol,
                iconURL: app.iconURL,
                size: 132
            )
            Spacer()
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(app.name)
                .font(.brand(30, .extrabold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(app.subtitle)
                .font(.system(size: 14))
                .foregroundColor(.inkSoft)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(alignment: .center, spacing: 12) {
                InstallButton(
                    state: model.state(for: app),
                    minHeight: 34,
                    fontSize: 15,
                    action: onInstall
                )

                Text(Formatters.fileSize(app.sizeBytes))
                    .font(.brand(12, .semibold))
                    .foregroundColor(.inkSoft)

                Spacer()
            }
            .padding(.top, 4)
        }
    }
}

// MARK: - Rail Card View

private struct RailCardView: View {
    @EnvironmentObject private var model: StoreModel
    let app: StoreItem
    var onSelect: () -> Void
    var onInstall: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                topGradientArea
                infoArea
            }
            .frame(width: 160, height: 210)
            .background(Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .softShadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var topGradientArea: some View {
        ZStack {
            LinearGradient(
                colors: [app.tint.opacity(0.65), app.tint.opacity(0.20)],
                startPoint: .top,
                endPoint: .bottom
            )
            AppIconView(
                tint: app.tint,
                symbol: app.symbol,
                iconURL: app.iconURL,
                size: 72
            )
        }
        .frame(width: 160, height: 100)
    }

    private var infoArea: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(app.name)
                .font(.brand(15, .semibold))
                .foregroundColor(.ink)
                .lineLimit(1)

            Text(app.subtitle)
                .font(.system(size: 12))
                .foregroundColor(.inkSoft)
                .lineLimit(1)

            Spacer()

            InstallButton(
                state: model.state(for: app),
                minHeight: 28,
                fontSize: 13,
                action: onInstall
            )
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
    }
}

// MARK: - App Row View

private struct AppRowView: View {
    @EnvironmentObject private var model: StoreModel
    let app: StoreItem
    var onSelect: () -> Void
    var onInstall: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onSelect) {
                HStack(spacing: 14) {
                    AppIconView(
                        tint: app.tint,
                        symbol: app.symbol,
                        iconURL: app.iconURL,
                        size: 62
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(app.name)
                            .font(.brand(17, .semibold))
                            .foregroundColor(.ink)
                            .lineLimit(1)

                        Text(app.subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.inkSoft)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text(app.category)
                            Text("•")
                            Text(Formatters.fileSize(app.sizeBytes))
                        }
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.inkFaint)
                    }

                    Spacer()

                    InstallButton(
                        state: model.state(for: app),
                        minHeight: 32,
                        fontSize: 14,
                        action: onInstall
                    )
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Color.paperSunk)
                .frame(height: 1)
                .padding(.leading, 76)
        }
    }
}

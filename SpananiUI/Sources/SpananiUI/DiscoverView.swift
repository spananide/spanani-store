import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CategoryRef: Identifiable {
    let id: String
}

struct DiscoverView: View {
    @EnvironmentObject private var model: StoreModel
    @Binding var selectedApp: StoreItem?
    var initialSubmit: Bool = false
    var onNavigateToTab: ((Int) -> Void)? = nil

    @State private var searchText: String = ""
    @State private var scrolledHeroID: String?
    @State private var activeCategory: CategoryRef?
    @State private var showChanges: Bool = false

    @State private var isImporterPresented: Bool = false
    @State private var isConfirmInstallPresented: Bool = false
    @State private var pendingIPAURL: URL? = nil
    @State private var pendingIPAName: String = ""
    @State private var isSubmitPresented: Bool = false
    @State private var hasHandledInitialSubmit: Bool = false

    init(
        selectedApp: Binding<StoreItem?>,
        initialSubmit: Bool = false,
        onNavigateToTab: ((Int) -> Void)? = nil
    ) {
        self._selectedApp = selectedApp
        self.initialSubmit = initialSubmit
        self.onNavigateToTab = onNavigateToTab
    }

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
        guard !query.isEmpty else { return [] }
        return model.apps.filter { app in
            app.name.lowercased().contains(query)
                || app.subtitle.lowercased().contains(query)
                || app.developer.lowercased().contains(query)
        }
    }

    private var newestColumns: [[StoreItem]] {
        let items = model.newest
        var cols: [[StoreItem]] = []
        for i in stride(from: 0, to: items.count, by: 3) {
            cols.append(Array(items[i..<min(i + 3, items.count)]))
        }
        return cols
    }

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                searchAndIPARow

                if let progress = model.ipaProgress {
                    ipaProgressBanner(progress: progress)
                }

                if isSearching {
                    searchResultsSection
                } else {
                    exploreShelves
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .onAppear {
            // launch argument "-scroll <shelf id>" lets CI screenshots show lower shelves
            guard let target = UserDefaults.standard.string(forKey: "scroll") else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                proxy.scrollTo(target, anchor: .top)
            }
        }
        .refreshable {
            await model.reloadSources()
        }
        .background(Color.paper)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [UTType(filenameExtension: "ipa") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            handleFileImporter(result: result)
        }
        .confirmationDialog(
            "Install \(pendingIPAName)?",
            isPresented: $isConfirmInstallPresented,
            titleVisibility: .visible
        ) {
            Button("Install") {
                if let url = pendingIPAURL {
                    model.installIPA(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $isSubmitPresented) {
            SubmitSheet()
                .environmentObject(model)
        }
        .sheet(item: $activeCategory) { cat in
            CategoryListView(category: cat.id)
                .environmentObject(model)
        }
        .sheet(isPresented: $showChanges) {
            ChangesListView()
                .environmentObject(model)
        }
        .onAppear {
            if initialSubmit && !hasHandledInitialSubmit {
                hasHandledInitialSubmit = true
                isSubmitPresented = true
            }
        }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Formatters.englishDate())
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.inkSoft)

                Text("Discover")
                    .font(.brand(34, .extrabold))
                    .foregroundColor(.ink)
            }

            Spacer()

            Mark3DTile(size: 44)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Search & IPA Install Row

    private var searchAndIPARow: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.inkSoft)

                TextField("Search apps", text: $searchText)
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
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.paperSunk)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.paperSunk, lineWidth: 1)
            )

            Button {
                isImporterPresented = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.brand)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Install IPA")
        }
        .padding(.horizontal, 20)
    }

    // MARK: - IPA Progress Banner

    private func ipaProgressBanner(progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Installing \(model.ipaName ?? "IPA") · \(Int(progress * 100)) %")
                    .font(.brand(14, .semibold))
                    .foregroundColor(.brand)
                Spacer()
            }

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .brand))
        }
        .padding(14)
        .background(Color.paperRaised)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.paperSunk, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Explore Shelves

    @ViewBuilder
    private var exploreShelves: some View {
        VStack(alignment: .leading, spacing: 28) {
            // 1. Featured Carousel
            if !model.featured.isEmpty {
                featuredSection
            }

            // 2. Favourites Row
            if !model.favoriteApps.isEmpty {
                favoritesSection
            }

            // 3. New & Updated Shelf
            if !model.newest.isEmpty {
                newAndUpdatedShelf.id("new")
            }

            // 4. Category Shelves
            categoryShelves

            // 5. From the Community Shelf + Suggest Card
            communityShelf

            // 6. Browse Categories Grid
            browseCategoriesSection.id("browse")

            // 7. Latest Changes Section
            if !model.changes.isEmpty {
                latestChangesSection
            }
        }
    }

    // MARK: - 1. Featured Carousel

    private var featuredSection: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(model.featured) { app in
                        FeaturedCard(app: app) {
                            selectedApp = app
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

    // MARK: - 2. Favorites Section

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Favourites", count: model.favoriteApps.count)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(model.favoriteApps) { app in
                        Button {
                            selectedApp = app
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

    // MARK: - 3. New & Updated Shelf

    private var newAndUpdatedShelf: some View {
        VStack(alignment: .leading, spacing: 14) {
            ShelfHeader(title: "New & Updated")
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(0..<newestColumns.count, id: \.self) { colIndex in
                        VStack(spacing: 0) {
                            ForEach(newestColumns[colIndex]) { app in
                                CompactAppRow(app: app) {
                                    selectedApp = app
                                }
                            }
                        }
                        .frame(width: max(UIScreen.main.bounds.width - 56, 260))
                    }
                }
                .padding(.horizontal, 20)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }

    // MARK: - 4. Category Shelves

    @ViewBuilder
    private var categoryShelves: some View {
        ForEach(model.categories, id: \.self) { category in
            let categoryApps = model.apps(in: category)
            if !categoryApps.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    ShelfHeader(title: category) {
                        activeCategory = CategoryRef(id: category)
                    }
                    .padding(.horizontal, 20)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 14) {
                            ForEach(categoryApps) { app in
                                ShelfCard(app: app) {
                                    selectedApp = app
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .id(category)
            }
        }
    }

    // MARK: - 5. Community Shelf & Suggest Card

    @ViewBuilder
    private var communityShelf: some View {
        if !model.communityApps.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                ShelfHeader(title: "From the community")
                    .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(model.communityApps) { app in
                            ShelfCard(app: app, showCommunityBadge: true) {
                                selectedApp = app
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }

        suggestAppCard(title: "Missing an app?")
            .padding(.horizontal, 20)
    }

    // MARK: - 6. Browse Categories

    private var browseCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ShelfHeader(title: "Browse categories")
                .padding(.horizontal, 20)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(model.categories, id: \.self) { category in
                    let count = model.apps(in: category).count
                    let tint = model.apps(in: category).first?.tint ?? Color.brand
                    CategoryTile(
                        category: category,
                        count: count,
                        tint: tint
                    ) {
                        activeCategory = CategoryRef(id: category)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - 7. Latest Changes

    private var latestChangesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ShelfHeader(title: "Latest changes") {
                showChanges = true
            }
            .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(Array(model.changes.sorted(by: { $0.date > $1.date }).prefix(3))) { change in
                    ChangeRowView(change: change)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Search Results Section

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Results", count: filteredApps.count)
                .padding(.horizontal, 20)

            if filteredApps.isEmpty {
                emptySearchPlaceholder

                suggestAppCard(title: "No results. Suggest it?")
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(filteredApps) { app in
                        CompactAppRow(app: app) {
                            selectedApp = app
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

            Text("No apps found")
                .font(.brand(18, .semibold))
                .foregroundColor(.ink)

            Text("Try searching for something else.")
                .font(.system(size: 14))
                .foregroundColor(.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Suggest App Card

    private func suggestAppCard(title: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Color.brand.opacity(0.18)
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.brand)
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.brand(18, .extrabold))
                        .foregroundColor(.ink)

                    Text("Suggest an .ipa and we will review it.")
                        .font(.system(size: 13))
                        .foregroundColor(.inkSoft)
                }

                Spacer()
            }

            Button {
                Haptics.impact(.medium)
                isSubmitPresented = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("Suggest an app")
                        .font(.brand(14, .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(Color.brand)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(Color.paperRaised)
        .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SpananiRadius.card, style: .continuous)
                .stroke(Color.paperSunk, lineWidth: 1)
        )
    }

    // MARK: - File Importer Handler

    private func handleFileImporter(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            let tempDir = FileManager.default.temporaryDirectory
            let uniqueName = UUID().uuidString + "-" + url.lastPathComponent
            let destURL = tempDir.appendingPathComponent(uniqueName)

            do {
                if FileManager.default.fileExists(atPath: destURL.path) {
                    try FileManager.default.removeItem(at: destURL)
                }
                try FileManager.default.copyItem(at: url, to: destURL)
                pendingIPAURL = destURL
                pendingIPAName = url.lastPathComponent
                isConfirmInstallPresented = true
            } catch {
                model.lastError = error.localizedDescription
            }
        case .failure(let error):
            model.lastError = error.localizedDescription
        }
    }
}

// MARK: - Featured Card

private struct FeaturedCard: View {
    @EnvironmentObject private var model: StoreModel
    let app: StoreItem
    var onSelect: () -> Void

    private var cardWidth: CGFloat {
        min(max(UIScreen.main.bounds.width * 0.86, 300.0), 360.0)
    }

    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [app.tint, app.tint.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.45)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack {
                    Spacer()
                        .frame(height: 52)
                    HStack {
                        Spacer()
                        AppIconView(
                            tint: app.tint,
                            symbol: app.symbol,
                            iconURL: app.iconURL,
                            size: 108
                        )
                        Spacer()
                    }
                    Spacer()
                }

                HStack(spacing: 6) {
                    if !app.heroTagline.isEmpty {
                        Text(app.heroTagline.uppercased())
                            .font(.brand(11, .semibold))
                            .foregroundColor(.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.paperSunk)
                            .clipShape(Capsule())
                    }

                    if app.isCommunity {
                        CommunityBadge()
                    }
                }
                .padding(16)

                VStack(alignment: .leading, spacing: 6) {
                    Spacer()

                    Text(app.name)
                        .font(.brand(28, .extrabold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(app.subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.85))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(alignment: .center, spacing: 12) {
                        InstallButton(
                            state: model.state(for: app),
                            minHeight: 34,
                            fontSize: 15
                        ) {
                            model.install(app)
                        }

                        Text(Formatters.fileSize(app.sizeBytes))
                            .font(.brand(12, .semibold))
                            .foregroundColor(Color.white.opacity(0.85))

                        Spacer()
                    }
                    .padding(.top, 4)
                }
                .padding(18)
            }
            .frame(width: cardWidth, height: 340)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.card, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                model.toggleFavorite(app.id)
            } label: {
                if model.isFavorite(app.id) {
                    Label("Remove from Favourites", systemImage: "star.slash")
                } else {
                    Label("Add to Favourites", systemImage: "star")
                }
            }
        }
    }
}

// MARK: - Compact App Row

private struct CompactAppRow: View {
    @EnvironmentObject private var model: StoreModel
    let app: StoreItem
    var onSelect: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    AppIconView(
                        tint: app.tint,
                        symbol: app.symbol,
                        iconURL: app.iconURL,
                        size: 56
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(app.name)
                            .font(.brand(16, .semibold))
                            .foregroundColor(.ink)
                            .lineLimit(1)

                        Text(app.subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.inkSoft)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    InstallButton(
                        state: model.state(for: app),
                        minHeight: 30,
                        fontSize: 13
                    ) {
                        model.install(app)
                    }
                }
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button {
                    model.toggleFavorite(app.id)
                } label: {
                    if model.isFavorite(app.id) {
                        Label("Remove from Favourites", systemImage: "star.slash")
                    } else {
                        Label("Add to Favourites", systemImage: "star")
                    }
                }
            }

            Rectangle()
                .fill(Color.paperSunk)
                .frame(height: 1)
                .padding(.leading, 68)
        }
    }
}

// MARK: - Shelf Card

private struct ShelfCard: View {
    @EnvironmentObject private var model: StoreModel
    let app: StoreItem
    var showCommunityBadge: Bool = false
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                if showCommunityBadge {
                    CommunityBadge()
                }

                AppIconView(
                    tint: app.tint,
                    symbol: app.symbol,
                    iconURL: app.iconURL,
                    size: 84
                )

                Text(app.name)
                    .font(.brand(15, .semibold))
                    .foregroundColor(.ink)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)

                Text(app.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.inkSoft)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 32)

                InstallButton(
                    state: model.state(for: app),
                    minHeight: 28,
                    fontSize: 13
                ) {
                    model.install(app)
                }
            }
            .padding(12)
            .frame(width: 150)
            .background(app.tint.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                model.toggleFavorite(app.id)
            } label: {
                if model.isFavorite(app.id) {
                    Label("Remove from Favourites", systemImage: "star.slash")
                } else {
                    Label("Add to Favourites", systemImage: "star")
                }
            }
        }
    }
}

// MARK: - Category Tile

private struct CategoryTile: View {
    let category: String
    let count: Int
    let tint: Color
    var action: () -> Void

    private var symbol: String {
        switch category {
        case "Games": return "gamecontroller.fill"
        case "Media": return "play.rectangle.fill"
        case "Utilities": return "wrench.and.screwdriver.fill"
        case "Developer": return "hammer.fill"
        case "Social": return "bubble.left.and.bubble.right.fill"
        case "Photo & Video": return "camera.fill"
        case "Lifestyle": return "heart.fill"
        case "Education": return "book.fill"
        default: return "square.grid.2x2.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(category)
                        .font(.brand(17, .extrabold))
                        .foregroundColor(.ink)
                        .lineLimit(1)

                    Text(count == 1 ? "1 app" : "\(count) apps")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.inkSoft)
                }

                Spacer()

                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(tint)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 78)
            .background(tint.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category List View

private struct CategoryListView: View {
    @EnvironmentObject private var model: StoreModel
    @Environment(\.dismiss) private var dismiss
    let category: String
    @State private var detail: StoreItem?

    var body: some View {
        ZStack {
            Color.paper
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text(category)
                        .font(.brand(24, .extrabold))
                        .foregroundColor(.ink)

                    Spacer()

                    Button {
                        Haptics.impact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.ink)
                            .frame(width: 36, height: 36)
                            .background(Color.paperRaised)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

                let apps = model.apps(in: category)
                if apps.isEmpty {
                    Spacer()
                    Text("No apps in this category.")
                        .font(.system(size: 14))
                        .foregroundColor(.inkSoft)
                    Spacer()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(apps) { app in
                                CompactAppRow(app: app) {
                                    detail = app
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .sheet(item: $detail) { app in
            AppDetailView(app: app)
                .environmentObject(model)
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Changes Helpers & View

private struct ChangeGroup: Identifiable {
    let id: String
    let title: String
    let items: [ChangeItem]
}

private func groupChanges(_ changes: [ChangeItem]) -> [ChangeGroup] {
    let sorted = changes.sorted(by: { $0.date > $1.date })
    let calendar = Calendar.current
    let dayFormatter = DateFormatter()
    dayFormatter.locale = Locale(identifier: "en_GB")
    dayFormatter.dateFormat = "d MMM"

    var groups: [ChangeGroup] = []
    var currentTitle = ""
    var currentItems: [ChangeItem] = []

    for item in sorted {
        let title: String
        if calendar.isDateInToday(item.date) {
            title = "Today"
        } else if calendar.isDateInYesterday(item.date) {
            title = "Yesterday"
        } else {
            title = dayFormatter.string(from: item.date)
        }

        if title == currentTitle {
            currentItems.append(item)
        } else {
            if !currentItems.isEmpty {
                groups.append(ChangeGroup(id: currentTitle, title: currentTitle, items: currentItems))
            }
            currentTitle = title
            currentItems = [item]
        }
    }

    if !currentItems.isEmpty {
        groups.append(ChangeGroup(id: currentTitle, title: currentTitle, items: currentItems))
    }

    return groups
}

private struct ChangesListView: View {
    @EnvironmentObject private var model: StoreModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.paper
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Latest Changes")
                        .font(.brand(24, .extrabold))
                        .foregroundColor(.ink)

                    Spacer()

                    Button {
                        Haptics.impact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.ink)
                            .frame(width: 36, height: 36)
                            .background(Color.paperRaised)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        let groups = groupChanges(model.changes)
                        if groups.isEmpty {
                            VStack(spacing: 12) {
                                Spacer()
                                    .frame(height: 32)
                                Mark3DTile(size: 96)
                                Text("No changes yet")
                                    .font(.brand(22, .extrabold))
                                    .foregroundColor(.ink)
                                Text("New versions from your sources show up here.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.inkSoft)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 36)
                        } else {
                            ForEach(groups) { group in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(group.title)
                                        .font(.brand(17, .semibold))
                                        .foregroundColor(.inkSoft)
                                        .padding(.horizontal, 20)

                                    VStack(spacing: 0) {
                                        ForEach(group.items) { item in
                                            ChangeRowView(change: item)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Change Row View

private struct ChangeRowView: View {
    @EnvironmentObject private var model: StoreModel
    let change: ChangeItem

    private var matchingApp: StoreItem? {
        model.apps.first { $0.id == change.appID }
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: change.date, relativeTo: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                AppIconView(
                    tint: change.tint,
                    symbol: change.symbol,
                    iconURL: change.iconURL,
                    size: 44
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(change.appName)  \(change.version)")
                            .font(.brand(16, .semibold))
                            .foregroundColor(.ink)
                            .lineLimit(1)

                        Spacer()

                        Text(relativeTime)
                            .font(.system(size: 12))
                            .foregroundColor(.inkFaint)
                    }

                    Text(change.notes)
                        .font(.system(size: 14))
                        .foregroundColor(.inkSoft)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                if let app = matchingApp {
                    InstallButton(
                        state: model.state(for: app),
                        minHeight: 30,
                        fontSize: 13
                    ) {
                        model.install(app)
                    }
                    .padding(.leading, 4)
                }
            }
            .padding(.vertical, 12)

            Rectangle()
                .fill(Color.paperSunk)
                .frame(height: 1)
                .padding(.leading, 56)
        }
    }
}

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct DiscoverView: View {
    @EnvironmentObject private var model: StoreModel
    @Binding var selectedApp: StoreItem?
    var onNavigateToTab: ((Int) -> Void)? = nil

    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"
    @State private var scrolledHeroID: String?
    @State private var selectedSegment: Int = 0

    @State private var isImporterPresented: Bool = false
    @State private var isConfirmInstallPresented: Bool = false
    @State private var pendingIPAURL: URL? = nil
    @State private var pendingIPAName: String = ""

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
            if selectedCategory == "All" {
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

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                searchAndIPARow

                if let progress = model.ipaProgress {
                    ipaProgressBanner(progress: progress)
                }

                SegmentSwitch(
                    options: ["Apps", "Changes"],
                    selection: $selectedSegment
                )
                .padding(.horizontal, 20)

                if selectedSegment == 0 {
                    if isSearching {
                        searchResultsSection
                    } else {
                        appsDiscoveryContent
                    }
                } else {
                    changesContent
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 140)
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

    // MARK: - Apps Discovery Content

    private var appsDiscoveryContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !model.favoriteApps.isEmpty {
                favoritesSection
            }

            if !model.featured.isEmpty {
                heroSection
            }

            categorySection
            allAppsSection
        }
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
                    title: "All",
                    isSelected: selectedCategory == "All"
                ) {
                    Haptics.selection()
                    selectedCategory = "All"
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

    // MARK: - All Apps Section

    private var allAppsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "All Apps", count: filteredApps.count)
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

    // MARK: - Search Results Section

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Results", count: filteredApps.count)
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

    // MARK: - Changes Content

    private var changesContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            if model.changes.isEmpty {
                emptyChangesView
            } else {
                ForEach(groupedChanges) { group in
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
    }

    private var emptyChangesView: some View {
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
    }

    private struct ChangeGroup: Identifiable {
        let id: String
        let title: String
        let items: [ChangeItem]
    }

    private var groupedChanges: [ChangeGroup] {
        let sorted = model.changes.sorted(by: { $0.date > $1.date })
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
            VStack(spacing: 0) {
                topZone
                bottomZone
            }
            .frame(width: cardWidth, height: 390)
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

    private var topZone: some View {
        ZStack(alignment: .topLeading) {
            app.tint

            if !app.heroTagline.isEmpty {
                Text(app.heroTagline.uppercased())
                    .font(.brand(12, .semibold))
                    .foregroundColor(.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.paperSunk)
                    .clipShape(Capsule())
                    .padding(16)
            }

            Center {
                AppIconView(
                    tint: app.tint,
                    symbol: app.symbol,
                    iconURL: app.iconURL,
                    size: 120
                )
            }
        }
        .frame(height: 220)
    }

    private var bottomZone: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(app.name)
                .font(.brand(28, .extrabold))
                .foregroundColor(.ink)
                .lineLimit(1)

            Text(app.subtitle)
                .font(.system(size: 14))
                .foregroundColor(.inkSoft)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer()

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
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.paperRaised)
    }
}

// MARK: - Center Helper

private struct Center<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        HStack {
            Spacer()
            content()
            Spacer()
        }
        .frame(maxHeight: .infinity)
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
                        size: 56
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

                        Text("\(app.category) · \(Formatters.fileSize(app.sizeBytes))")
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
                .padding(.leading, 70)
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

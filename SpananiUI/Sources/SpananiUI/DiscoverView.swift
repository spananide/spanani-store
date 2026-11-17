import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var model: StoreModel
    @Binding var selectedApp: StoreItem?
    var onNavigateToTab: ((Int) -> Void)? = nil

    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var filteredApps: [StoreItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            if selectedCategory == "All" {
                return model.apps
            } else {
                return model.apps.filter { $0.category == selectedCategory }
            }
        } else {
            return model.apps.filter { app in
                app.name.localizedCaseInsensitiveContains(query)
                    || app.subtitle.localizedCaseInsensitiveContains(query)
                    || app.developer.localizedCaseInsensitiveContains(query)
            }
        }
    }

    var body: some View {
        List {
            if !isSearching && !model.featured.isEmpty {
                Section("Featured") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: Spacing.m) {
                            ForEach(model.featured) { app in
                                VStack(alignment: .leading, spacing: Spacing.s) {
                                    Button {
                                        selectedApp = app
                                    } label: {
                                        VStack(alignment: .leading, spacing: Spacing.s) {
                                            AppIconView(
                                                tint: app.tint,
                                                symbol: app.symbol,
                                                iconURL: app.iconURL,
                                                size: 64
                                            )
                                            Text(app.name)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)
                                            Text(app.subtitle)
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                        }
                                        .frame(width: 140, alignment: .leading)
                                    }
                                    .buttonStyle(.plain)

                                    InstallButton(
                                        state: model.state(for: app),
                                        action: { model.install(app) }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, Spacing.s)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }

            if !filteredApps.isEmpty {
                Section(isSearching ? "Results" : "Apps") {
                    ForEach(filteredApps) { app in
                        HStack(spacing: Spacing.m) {
                            AppIconView(
                                tint: app.tint,
                                symbol: app.symbol,
                                iconURL: app.iconURL,
                                size: 56
                            )

                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(app.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Text(app.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                Text("\(app.category) · \(Formatters.fileSize(app.sizeBytes))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            InstallButton(
                                state: model.state(for: app),
                                action: { model.install(app) }
                            )
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedApp = app
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Discover")
        .searchable(text: $searchText, prompt: "Search Apps")
        .refreshable {
            await model.reloadSources()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All").tag("All")
                        ForEach(model.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                } label: {
                    Label("Category", systemImage: "line.3.horizontal.decrease")
                }
            }
        }
        .overlay {
            if model.apps.isEmpty {
                ContentUnavailableView(
                    "No Apps",
                    systemImage: "square.grid.2x2",
                    description: Text("Add a source in Sources, or pull down to refresh.")
                )
            } else if isSearching && filteredApps.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }
}

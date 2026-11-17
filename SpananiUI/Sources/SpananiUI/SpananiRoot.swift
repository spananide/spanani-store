import SwiftUI

public struct SpananiRoot: View {
    @ObservedObject public var model: StoreModel
    @State private var selectedTab: Int
    @State private var selectedAppForDetail: StoreItem?
    private let initialDetail: Int?

    public init(model: StoreModel, initialTab: Int = 0, initialDetail: Int? = nil) {
        self.model = model
        self.initialDetail = initialDetail
        _selectedTab = State(initialValue: initialTab)
        SpananiFont.register()

        if let detail = initialDetail,
           model.apps.indices.contains(detail) {
            _selectedAppForDetail = State(initialValue: model.apps[detail])
        }
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DiscoverView(
                    selectedApp: $selectedAppForDetail,
                    onNavigateToTab: { tabIndex in
                        selectedTab = tabIndex
                    }
                )
            }
            .tabItem {
                Label("Discover", systemImage: "square.grid.2x2")
            }
            .tag(0)

            NavigationStack {
                MyAppsView(
                    onNavigateToTab: { tabIndex in
                        selectedTab = tabIndex
                    }
                )
            }
            .tabItem {
                Label("My Apps", systemImage: "arrow.down.app")
            }
            .tag(1)

            NavigationStack {
                SourcesView()
            }
            .tabItem {
                Label("Sources", systemImage: "tray.full")
            }
            .tag(2)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(3)
        }
        .tint(.spananiAccent)
        .environmentObject(model)
        .onAppear {
            if selectedAppForDetail == nil,
               let detail = initialDetail,
               model.apps.indices.contains(detail) {
                selectedAppForDetail = model.apps[detail]
            }
        }
        .sheet(item: $selectedAppForDetail) { app in
            AppDetailView(app: app)
                .tint(.spananiAccent)
                .environmentObject(model)
                .presentationDragIndicator(.visible)
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { model.lastError != nil },
                set: { if !$0 { model.lastError = nil } }
            )
        ) {
            Button("OK") {
                model.lastError = nil
            }
        } message: {
            Text(model.lastError ?? "")
        }
    }
}

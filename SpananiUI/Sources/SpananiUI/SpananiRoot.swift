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
        ZStack {
            Color.paper
                .ignoresSafeArea()

            tabContent

            VStack {
                Spacer()
                GlassTabBar(selection: $selectedTab)
            }
        }
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
                .environmentObject(model)
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            DiscoverView(
                selectedApp: $selectedAppForDetail,
                onNavigateToTab: { tabIndex in
                    selectedTab = tabIndex
                }
            )
        case 1:
            MyAppsView(
                onNavigateToTab: { tabIndex in
                    selectedTab = tabIndex
                }
            )
        case 2:
            SourcesView()
        case 3:
            SettingsView()
        default:
            DiscoverView(
                selectedApp: $selectedAppForDetail,
                onNavigateToTab: { tabIndex in
                    selectedTab = tabIndex
                }
            )
        }
    }
}

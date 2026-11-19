import SwiftUI
import UIKit

public struct SpananiRoot: View {
    @ObservedObject public var model: StoreModel
    @State private var selectedTab: Int
    @State private var selectedAppForDetail: StoreItem?
    private let initialDetail: Int?
    private let initialSubmit: Bool

    public init(
        model: StoreModel,
        initialTab: Int = 0,
        initialDetail: Int? = nil,
        initialSubmit: Bool = false
    ) {
        self.model = model
        self.initialDetail = initialDetail
        self.initialSubmit = initialSubmit
        _selectedTab = State(initialValue: initialSubmit ? 0 : initialTab)
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

            GeometryReader { geo in
                tabContent
                    .padding(.top, missingTopInset(geo.safeAreaInsets.top))
            }

            VStack {
                Spacer()
                SpananiTabBar(selection: $selectedTab)
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
            if let error = model.lastError {
                Text(error)
            }
        }
    }

    // On the device the overlay can arrive without the top safe area (content under the Dynamic Island): add only what is missing.
    private func missingTopInset(_ safeTop: CGFloat) -> CGFloat {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let statusBar = scene?.statusBarManager?.statusBarFrame.height ?? 0
        return max(0, statusBar - safeTop)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            DiscoverView(
                selectedApp: $selectedAppForDetail,
                initialSubmit: initialSubmit,
                onNavigateToTab: { tabIndex in
                    selectedTab = tabIndex
                }
            )
        case 1:
            MyAppsView(
                selectedApp: $selectedAppForDetail,
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
                initialSubmit: initialSubmit,
                onNavigateToTab: { tabIndex in
                    selectedTab = tabIndex
                }
            )
        }
    }
}

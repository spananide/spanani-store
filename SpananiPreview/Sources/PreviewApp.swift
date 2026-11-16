import SwiftUI
import SpananiUI

@main
struct PreviewApp: App {
    @StateObject private var model: StoreModel
    private let initialTab: Int
    private let initialDetail: Int?

    init() {
        let store = MainActor.assumeIsolated {
            DemoData.makeModel()
        }
        _model = StateObject(wrappedValue: store)

        if UserDefaults.standard.object(forKey: "tab") != nil {
            initialTab = UserDefaults.standard.integer(forKey: "tab")
        } else {
            initialTab = 0
        }

        if UserDefaults.standard.object(forKey: "detail") != nil {
            initialDetail = UserDefaults.standard.integer(forKey: "detail")
        } else {
            initialDetail = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            SpananiRoot(
                model: model,
                initialTab: initialTab,
                initialDetail: initialDetail
            )
        }
    }
}

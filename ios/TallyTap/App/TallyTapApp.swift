import SwiftUI

@main
struct TallyTapApp: App {
    @StateObject private var model = LedgerModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
        }
    }
}

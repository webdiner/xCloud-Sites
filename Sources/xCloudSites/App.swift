import SwiftUI

@main
struct xCloudSitesApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra("xCloud Sites", systemImage: "cloud.fill") {
            RootView()
                .environmentObject(state)
                .frame(width: 340, height: 460)
        }
        .menuBarExtraStyle(.window)
    }
}

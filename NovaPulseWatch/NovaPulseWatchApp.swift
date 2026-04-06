import SwiftUI

@main
struct NovaPulseWatchApp: App {
    @StateObject private var viewModel = WatchHealthViewModel()

    var body: some Scene {
        WindowGroup {
            WatchDashboardView()
                .environmentObject(viewModel)
        }
    }
}

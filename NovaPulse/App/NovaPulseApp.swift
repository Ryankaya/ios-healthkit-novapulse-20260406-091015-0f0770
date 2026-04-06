import SwiftUI

@main
struct NovaPulseApp: App {
    @StateObject private var healthKitService = HealthKitService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKitService)
        }
    }
}

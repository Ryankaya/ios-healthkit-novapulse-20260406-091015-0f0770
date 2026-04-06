import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @StateObject private var dashboardVM = HealthDashboardViewModel()

    var body: some View {
        Group {
            if healthKitService.authorizationStatus == .notDetermined {
                PermissionView()
                    .environmentObject(healthKitService)
            } else {
                DashboardView()
                    .environmentObject(healthKitService)
                    .environmentObject(dashboardVM)
            }
        }
        .onAppear {
            dashboardVM.setHealthKitService(healthKitService)
        }
        .onChange(of: healthKitService.authorizationStatus) { _ in
            dashboardVM.fetchAllMetrics()
        }
    }
}

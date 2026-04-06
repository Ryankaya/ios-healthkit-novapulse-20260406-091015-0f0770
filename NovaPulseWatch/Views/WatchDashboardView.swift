import SwiftUI

struct WatchDashboardView: View {
    @EnvironmentObject var vm: WatchHealthViewModel

    var body: some View {
        TabView {
            WatchStepsView()
                .environmentObject(vm)
                .tag(0)

            WatchHeartView()
                .environmentObject(vm)
                .tag(1)

            WatchActivityView()
                .environmentObject(vm)
                .tag(2)
        }
        .tabViewStyle(.page)
        .onAppear {
            vm.service.requestAuthorization()
            vm.fetchAll()
        }
    }
}

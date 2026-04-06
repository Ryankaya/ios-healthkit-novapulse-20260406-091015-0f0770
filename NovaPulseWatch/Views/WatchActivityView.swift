import SwiftUI

struct WatchActivityView: View {
    @EnvironmentObject var vm: WatchHealthViewModel
    @State private var ringAnimated = false

    var body: some View {
        VStack(spacing: 6) {
            // Concentric rings: steps (outer) + energy (inner)
            ZStack {
                // Steps ring (outer)
                Circle()
                    .stroke(Color.green.opacity(0.15), lineWidth: 7)
                    .frame(width: 90, height: 90)
                Circle()
                    .trim(from: 0, to: ringAnimated ? vm.stepProgress : 0)
                    .stroke(Color.green,
                            style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))

                // Energy ring (inner)
                Circle()
                    .stroke(Color.orange.opacity(0.15), lineWidth: 6)
                    .frame(width: 68, height: 68)
                Circle()
                    .trim(from: 0, to: ringAnimated ? vm.energyProgress : 0)
                    .stroke(Color.orange,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 68, height: 68)
                    .rotationEffect(.degrees(-90))

                // Center icon
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.orange)
            }
            .animation(.easeInOut(duration: 1.0), value: ringAnimated)
            .onAppear { ringAnimated = true }

            // Stats
            HStack(spacing: 16) {
                statLabel(icon: "figure.walk",
                          value: vm.formattedSteps,
                          color: .green)
                statLabel(icon: "flame.fill",
                          value: "\(vm.formattedEnergy) kcal",
                          color: .orange)
            }
        }
        .containerBackground(Color.black.gradient, for: .tabView)
    }

    @ViewBuilder
    private func statLabel(icon: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

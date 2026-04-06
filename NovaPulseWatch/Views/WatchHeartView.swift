import SwiftUI

struct WatchHeartView: View {
    @EnvironmentObject var vm: WatchHealthViewModel
    @State private var heartbeat = false

    var body: some View {
        VStack(spacing: 8) {
            // Pulsing heart icon
            Image(systemName: "heart.fill")
                .font(.system(size: 34))
                .foregroundStyle(vm.hrZone.color)
                .scaleEffect(heartbeat ? 1.15 : 1.0)
                .animation(
                    .easeInOut(duration: 0.45).repeatForever(autoreverses: true),
                    value: heartbeat
                )
                .onAppear { heartbeat = true }

            // BPM
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(vm.formattedHR)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("bpm")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Zone pill
            Text(vm.hrZone.rawValue)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(vm.hrZone.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(vm.hrZone.color.opacity(0.18))
                .clipShape(Capsule())

            // SpO2 secondary
            HStack(spacing: 4) {
                Image(systemName: "lungs.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.blue.opacity(0.7))
                Text("SpO₂ \(vm.formattedSpO2)")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .containerBackground(Color.black.gradient, for: .tabView)
    }
}

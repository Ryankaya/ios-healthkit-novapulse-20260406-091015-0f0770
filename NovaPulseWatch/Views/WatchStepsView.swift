import SwiftUI

struct WatchStepsView: View {
    @EnvironmentObject var vm: WatchHealthViewModel
    @State private var ringAnimated = false

    var body: some View {
        VStack(spacing: 6) {
            // Animated ring
            ZStack {
                // Background track
                Circle()
                    .stroke(Color.green.opacity(0.18), lineWidth: 9)

                // Progress arc
                Circle()
                    .trim(from: 0, to: ringAnimated ? vm.stepProgress : 0)
                    .stroke(
                        AngularGradient(
                            colors: [.green, .mint, .green],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: ringAnimated)

                VStack(spacing: 2) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.green)
                    Text(vm.formattedSteps)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
            }
            .frame(width: 90, height: 90)
            .onAppear { ringAnimated = true }

            // Goal label
            Text("\(Int(vm.stepProgress * 100))% of goal")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.green.opacity(0.8))

            // Steps remaining
            let remaining = max(0, vm.stepGoal - vm.steps)
            if remaining > 0 {
                Text("\(Int(remaining)) to go")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
            } else {
                Label("Goal reached!", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
            }
        }
        .containerBackground(Color.black.gradient, for: .tabView)
    }
}

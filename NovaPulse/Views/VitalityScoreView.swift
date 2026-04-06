import SwiftUI

struct VitalityScoreView: View {
    let score: VitalityScore
    @State private var animated = false

    var body: some View {
        VStack(spacing: 16) {
            // Ring + Score
            HStack(spacing: 24) {
                scoreRing
                    .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 10) {
                    Text(score.grade.rawValue)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(score.grade.emoji + " Vitality Grade")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))

                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                        Text("Updated \(score.computedAt, style: .relative) ago")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                Spacer()
            }

            // Sub-scores
            HStack(spacing: 0) {
                subScorePill("Cardio",    value: score.cardiovascular, color: .npRedFallback)
                subScorePill("Activity",  value: score.activity,       color: .npGreenFallback)
                subScorePill("Recovery",  value: score.recovery,       color: .npBlueFallback)
                subScorePill("Breathing", value: score.respiratory,    color: .npOrangeFallback)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.09), Color.white.opacity(0.04)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: Ring
    private var scoreRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 10)

            Circle()
                .trim(from: 0, to: animated ? CGFloat(score.overall / 100) : 0)
                .stroke(
                    LinearGradient.scoreGradient,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.2), value: animated)

            VStack(spacing: 2) {
                Text("\(Int(score.overall))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("/ 100")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .onAppear { animated = true }
    }

    @ViewBuilder
    private func subScorePill(_ label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(Int(value))")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
            Rectangle()
                .fill(color)
                .frame(height: 3)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
    }
}

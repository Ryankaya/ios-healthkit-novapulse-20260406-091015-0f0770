import SwiftUI

struct MetricCardView: View {
    let metric: HealthMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon + Trend
            HStack {
                Image(systemName: metric.type.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(metric.type.accentColor)
                Spacer()
                trendBadge
            }

            // Value
            Text(metric.formattedValue)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Unit + Name
            VStack(alignment: .leading, spacing: 2) {
                Text(metric.type.unit)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
                Text(metric.type.rawValue)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
            }

            // Sparkline
            MiniSparkline(points: metric.weeklyData.map(\.value), color: metric.type.accentColor)
                .frame(height: 28)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            metric.isInNormalRange
                                ? metric.type.accentColor.opacity(0.25)
                                : Color.npRedFallback.opacity(0.4),
                            lineWidth: 1
                        )
                )
        )
    }

    @ViewBuilder
    private var trendBadge: some View {
        Image(systemName: metric.trend.icon)
            .font(.caption2)
            .foregroundStyle(metric.trend.color)
            .padding(4)
            .background(metric.trend.color.opacity(0.15))
            .clipShape(Circle())
    }
}

// MARK: - Mini Sparkline
struct MiniSparkline: View {
    let points: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            if points.count >= 2 {
                let min = points.min() ?? 0
                let max = points.max() ?? 1
                let range = max - min == 0 ? 1 : max - min
                let step = geo.size.width / CGFloat(points.count - 1)

                Path { path in
                    for (i, val) in points.enumerated() {
                        let x = CGFloat(i) * step
                        let y = geo.size.height - CGFloat((val - min) / range) * geo.size.height
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else       { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

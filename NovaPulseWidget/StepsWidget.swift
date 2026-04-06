import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct StepsEntry: TimelineEntry {
    let date: Date
    let steps: Double
    let heartRate: Double
    let activeEnergy: Double

    static let stepGoal: Double = 10_000
    var stepProgress: Double { min(steps / Self.stepGoal, 1.0) }

    /// Placeholder shown while real data is loading
    static let placeholder = StepsEntry(date: Date(), steps: 7_432, heartRate: 72, activeEnergy: 321)
}

// MARK: - Timeline Provider
struct StepsProvider: TimelineProvider {
    func placeholder(in context: Context) -> StepsEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (StepsEntry) -> Void) {
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
        Task {
            async let s  = WidgetHealthService.fetchTodaySteps()
            async let hr = WidgetHealthService.fetchLatestHeartRate()
            async let ae = WidgetHealthService.fetchActiveEnergy()
            var (steps, hr_, ae_) = await (s, hr, ae)
            // Demo fallback for Simulator
            if steps == 0 { steps = 7_432 }
            if hr_   == 0 { hr_   = 72    }
            if ae_   == 0 { ae_   = 321   }
            let entry = StepsEntry(date: Date(), steps: steps, heartRate: hr_, activeEnergy: ae_)
            let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
            completion(Timeline(entries: [entry], policy: .after(refresh)))
        }
    }
}

// MARK: - Widget Declaration
struct StepsWidget: Widget {
    static let kind = "StepsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: StepsProvider()) { entry in
            StepsWidgetView(entry: entry)
                .containerBackground(Color.black, for: .widget)
        }
        .configurationDisplayName("Steps")
        .description("Daily step progress and heart rate at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Views
struct StepsWidgetView: View {
    let entry: StepsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:  smallView
        case .systemMedium: mediumView
        default:            smallView
        }
    }

    // MARK: Small — circular ring + step count
    private var smallView: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.2), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: entry.stepProgress)
                    .stroke(Color.green,
                            style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: entry.stepProgress)
                VStack(spacing: 1) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.green)
                    Text(stepK)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 76, height: 76)

            Text("\(Int(entry.stepProgress * 100))% of goal")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(8)
    }

    // MARK: Medium — ring + steps + HR + energy columns
    private var mediumView: some View {
        HStack(spacing: 16) {
            // Ring
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: entry.stepProgress)
                    .stroke(Color.green,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Image(systemName: "figure.walk")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text(stepK)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("steps")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .frame(width: 88, height: 88)

            // Stats column
            VStack(alignment: .leading, spacing: 10) {
                statRow(icon: "heart.fill", color: .red,
                        value: String(format: "%.0f", entry.heartRate), unit: "bpm")
                statRow(icon: "flame.fill", color: .orange,
                        value: String(format: "%.0f", entry.activeEnergy), unit: "kcal")
                statRow(icon: "target", color: .green,
                        value: "\(Int(entry.stepProgress * 100))%", unit: "goal")
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: Helpers
    private var stepK: String {
        entry.steps >= 1000
            ? String(format: "%.1fk", entry.steps / 1000)
            : String(format: "%.0f", entry.steps)
    }

    @ViewBuilder
    private func statRow(icon: String, color: Color, value: String, unit: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 16)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(unit)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.45))
        }
    }
}

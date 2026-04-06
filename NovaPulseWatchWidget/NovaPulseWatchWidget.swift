import WidgetKit
import SwiftUI
import HealthKit

// MARK: - Entry
struct WatchStepsEntry: TimelineEntry {
    let date: Date
    let steps: Double
    let heartRate: Double
    let stepGoal: Double = 10_000
    var stepProgress: Double { min(steps / stepGoal, 1.0) }

    static let placeholder = WatchStepsEntry(date: Date(), steps: 7_432, heartRate: 72)
}

// MARK: - Provider
struct WatchStepsProvider: TimelineProvider {
    private let store = HKHealthStore()

    func placeholder(in context: Context) -> WatchStepsEntry { .placeholder }
    func getSnapshot(in context: Context, completion: @escaping (WatchStepsEntry) -> Void) {
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchStepsEntry>) -> Void) {
        Task {
            let steps = await fetchSteps()
            let hr    = await fetchHR()
            let entry = WatchStepsEntry(
                date: Date(),
                steps: steps > 0 ? steps : 7_432,
                heartRate: hr > 0 ? hr : 72
            )
            let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func fetchSteps() async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let start = Calendar.current.startOfDay(for: Date())
        let pred  = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: pred,
                                      options: .cumulativeSum) { _, r, _ in
                cont.resume(returning: r?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            }
            store.execute(q)
        }
    }

    private func fetchHR() async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else { return 0 }
        let unit = HKUnit.count().unitDivided(by: .minute())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1,
                                  sortDescriptors: [sort]) { _, s, _ in
                cont.resume(returning:
                    (s?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit) ?? 0)
            }
            store.execute(q)
        }
    }
}

// MARK: - Views
struct WatchWidgetEntryView: View {
    let entry: WatchStepsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:   circularView
        case .accessoryCorner:     cornerView
        case .accessoryRectangular: rectangularView
        default:                   circularView
        }
    }

    // Circular complication: ring + step count
    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            ProgressView(value: entry.stepProgress)
                .progressViewStyle(.circular)
                .tint(.green)
            VStack(spacing: 1) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.green)
                Text(stepK)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
            }
        }
    }

    // Corner: gauge arc
    private var cornerView: some View {
        ZStack {
            Image(systemName: "figure.walk")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.green)
        }
        .widgetLabel {
            ProgressView(value: entry.stepProgress)
                .progressViewStyle(.linear)
                .tint(.green)
        }
    }

    // Rectangular: steps + HR side-by-side
    private var rectangularView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Label(stepK, systemImage: "figure.walk")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                ProgressView(value: entry.stepProgress)
                    .progressViewStyle(.linear)
                    .tint(.green)
                    .frame(width: 80)
                Text("\(Int(entry.stepProgress * 100))% of goal")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Divider().background(.white.opacity(0.2))
            VStack(spacing: 3) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                Text(String(format: "%.0f", entry.heartRate))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("bpm")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 4)
        .containerBackground(.black, for: .widget)
    }

    private var stepK: String {
        entry.steps >= 1000
            ? String(format: "%.1fk", entry.steps / 1000)
            : String(format: "%.0f", entry.steps)
    }
}

// MARK: - Widget
struct NovaPulseWatchWidget: Widget {
    static let kind = "NovaPulseWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: WatchStepsProvider()) { entry in
            WatchWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("NovaPulse Steps")
        .description("Step ring, progress, and heart rate on your watch face.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryRectangular])
    }
}

@main
struct NovaPulseWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        NovaPulseWatchWidget()
    }
}

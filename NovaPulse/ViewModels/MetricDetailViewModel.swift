import Foundation
import SwiftUI
import Combine

@MainActor
final class MetricDetailViewModel: ObservableObject {

    @Published var metric: HealthMetric?
    @Published var chartRange: ChartRange = .week
    @Published var isLoading: Bool = false

    private weak var healthKitService: HealthKitService?
    private var fetchTask: Task<Void, Never>?

    enum ChartRange: String, CaseIterable {
        case day   = "Day"
        case week  = "Week"
        case month = "Month"

        var days: Int {
            switch self {
            case .day:   return 1
            case .week:  return 7
            case .month: return 30
            }
        }
    }

    func configure(metricType: MetricType, service: HealthKitService) {
        self.healthKitService = service
        fetchData(for: metricType)
    }

    func fetchData(for type: MetricType) {
        fetchTask?.cancel()
        fetchTask = Task {
            guard let service = healthKitService else { return }
            isLoading = true
            do {
                let data = try await service.fetchDailyStatistics(for: type, days: chartRange.days)
                let current = try await service.fetchLatestSample(for: type) ?? data.last?.value ?? 0
                let avg = data.isEmpty ? current : data.map(\.value).reduce(0, +) / Double(data.count)
                let trend: MetricTrend = {
                    guard data.count >= 2 else { return .stable }
                    let last = data.last!.value
                    let prev = data[data.count - 2].value
                    let delta = (last - prev) / max(prev, 1)
                    if delta > 0.05  { return .rising }
                    if delta < -0.05 { return .falling }
                    return .stable
                }()
                metric = HealthMetric(
                    type: type,
                    currentValue: current,
                    dailyAverage: avg,
                    weeklyData: data,
                    trend: trend,
                    lastUpdated: Date()
                )
            } catch {
                // Keep existing or nil
            }
            isLoading = false
        }
    }

    func changeRange(_ range: ChartRange, for type: MetricType) {
        chartRange = range
        fetchData(for: type)
    }

    var chartPoints: [(x: Date, y: Double)] {
        metric?.weeklyData.map { (x: $0.timestamp, y: $0.displayValue) } ?? []
    }
}

private extension HealthDataPoint {
    var displayValue: Double {
        switch metricType {
        case .oxygenSaturation: return value * 100
        case .hrv:              return value * 1000
        default:                return value
        }
    }
}

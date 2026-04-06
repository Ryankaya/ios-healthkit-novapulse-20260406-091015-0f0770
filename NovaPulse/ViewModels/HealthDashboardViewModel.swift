import Foundation
import Combine
import SwiftUI

@MainActor
final class HealthDashboardViewModel: ObservableObject {

    // MARK: Published State
    @Published var metrics: [MetricType: HealthMetric] = [:]
    @Published var vitalityScore: VitalityScore?
    @Published var insights: [CircadianInsight] = []
    @Published var isRefreshing: Bool = false
    @Published var selectedMetric: MetricType?
    @Published var errorMessage: String?

    // MARK: Private
    private weak var healthKitService: HealthKitService?
    private var refreshTask: Task<Void, Never>?

    // MARK: Configuration
    func setHealthKitService(_ service: HealthKitService) {
        self.healthKitService = service
    }

    // MARK: Fetch All Metrics
    func fetchAllMetrics() {
        refreshTask?.cancel()
        refreshTask = Task {
            guard let service = healthKitService else { return }
            isRefreshing = true
            errorMessage = nil

            await withTaskGroup(of: Void.self) { group in
                for metricType in MetricType.allCases {
                    group.addTask { [weak self] in
                        await self?.fetchMetric(metricType, using: service)
                    }
                }
            }

            computeVitalityScore()
            generateInsights()
            isRefreshing = false
        }
    }

    // MARK: Fetch Single Metric
    private func fetchMetric(_ type: MetricType, using service: HealthKitService) async {
        do {
            let weeklyData: [HealthDataPoint]
            let currentValue: Double

            if type == .sleepHours {
                let hours = try await service.fetchSleepHours()
                currentValue = hours
                weeklyData = []
            } else {
                weeklyData = try await service.fetchDailyStatistics(for: type, days: 7)
                currentValue = try await service.fetchLatestSample(for: type) ?? weeklyData.last?.value ?? 0
            }

            let dailyAvg = weeklyData.isEmpty ? currentValue
                : weeklyData.map(\.value).reduce(0, +) / Double(weeklyData.count)
            let trend = computeTrend(from: weeklyData)

            let metric = HealthMetric(
                type: type,
                currentValue: currentValue,
                dailyAverage: dailyAvg,
                weeklyData: weeklyData,
                trend: trend,
                lastUpdated: Date()
            )
            metrics[type] = metric
        } catch {
            // Use synthetic demo data when HealthKit has no real data
            metrics[type] = makeDemoMetric(for: type)
        }
    }

    // MARK: Trend Calculation
    private func computeTrend(from data: [HealthDataPoint]) -> MetricTrend {
        guard data.count >= 2 else { return .stable }
        let recent = data.suffix(3).map(\.value).reduce(0, +) / 3
        let older  = data.prefix(3).map(\.value).reduce(0, +) / 3
        let delta  = (recent - older) / max(older, 1)
        if delta > 0.05  { return .rising }
        if delta < -0.05 { return .falling }
        return .stable
    }

    // MARK: Vitality Score
    private func computeVitalityScore() {
        func scoreFor(_ type: MetricType, value: Double) -> Double {
            let range = type.normalRange
            if range.contains(value) { return 100 }
            let mid = (range.lowerBound + range.upperBound) / 2
            let span = range.upperBound - range.lowerBound
            let dist = abs(value - mid)
            return max(0, 100 - (dist / span) * 80)
        }

        let hrScore  = scoreFor(.heartRate,        value: metrics[.heartRate]?.displayDouble ?? 70)
        let hrvScore = scoreFor(.hrv,               value: metrics[.hrv]?.displayDouble ?? 50)
        let spo2     = scoreFor(.oxygenSaturation, value: metrics[.oxygenSaturation]?.displayDouble ?? 98)
        let rrScore  = scoreFor(.respiratoryRate,  value: metrics[.respiratoryRate]?.displayDouble ?? 16)
        let stepScore = scoreFor(.steps,           value: metrics[.steps]?.displayDouble ?? 8000)
        let aeScore  = scoreFor(.activeEnergy,     value: metrics[.activeEnergy]?.displayDouble ?? 300)
        let sleepScore = scoreFor(.sleepHours,     value: metrics[.sleepHours]?.displayDouble ?? 7.5)

        let cardiovascular = (hrScore + hrvScore) / 2
        let activity       = (stepScore + aeScore) / 2
        let recovery       = (sleepScore + hrvScore) / 2
        let respiratory    = (spo2 + rrScore) / 2
        let overall        = (cardiovascular + activity + recovery + respiratory) / 4

        vitalityScore = VitalityScore(
            overall: overall,
            cardiovascular: cardiovascular,
            activity: activity,
            recovery: recovery,
            respiratory: respiratory,
            computedAt: Date()
        )
    }

    // MARK: Insight Generation
    private func generateInsights() {
        var newInsights: [CircadianInsight] = []

        // Heart Rate insight
        if let hr = metrics[.heartRate]?.displayDouble {
            if hr > 100 {
                newInsights.append(CircadianInsight(
                    title: "Elevated Heart Rate",
                    detail: "Your resting heart rate of \(Int(hr)) bpm is above normal. Consider relaxation techniques or a lighter activity day.",
                    category: .heart,
                    priority: .high
                ))
            } else if hr < 60 {
                newInsights.append(CircadianInsight(
                    title: "Bradycardia Alert",
                    detail: "Heart rate of \(Int(hr)) bpm is below 60 bpm. This is common in athletes but consult a physician if unusual.",
                    category: .heart,
                    priority: .medium
                ))
            } else {
                newInsights.append(CircadianInsight(
                    title: "Healthy Heart Rate",
                    detail: "Your heart rate of \(Int(hr)) bpm is within the optimal range. Keep it up!",
                    category: .heart,
                    priority: .low
                ))
            }
        }

        // Sleep insight
        if let sleep = metrics[.sleepHours]?.displayDouble, sleep > 0 {
            if sleep < 6 {
                newInsights.append(CircadianInsight(
                    title: "Sleep Deficit Detected",
                    detail: "You got \(String(format: "%.1f", sleep))h of sleep. Aim for 7–9 hours to support recovery and cognitive performance.",
                    category: .sleep,
                    priority: .high
                ))
            } else if sleep >= 7 && sleep <= 9 {
                newInsights.append(CircadianInsight(
                    title: "Optimal Sleep Duration",
                    detail: "\(String(format: "%.1f", sleep))h of quality sleep detected. Your body is well-rested for peak performance.",
                    category: .sleep,
                    priority: .low
                ))
            }
        }

        // Steps insight
        if let steps = metrics[.steps]?.displayDouble {
            if steps < 5000 {
                newInsights.append(CircadianInsight(
                    title: "Low Activity Today",
                    detail: "Only \(Int(steps)) steps so far. A 20-minute walk can significantly boost your vitality score.",
                    category: .activity,
                    priority: .medium
                ))
            } else if steps >= 10000 {
                newInsights.append(CircadianInsight(
                    title: "Step Goal Achieved!",
                    detail: "Fantastic! \(Int(steps)) steps logged today. You're in the top tier for daily physical activity.",
                    category: .activity,
                    priority: .low
                ))
            }
        }

        // HRV insight
        if let hrv = metrics[.hrv]?.displayDouble, hrv > 0 {
            if hrv < 20 {
                newInsights.append(CircadianInsight(
                    title: "Low HRV — Rest Recommended",
                    detail: "HRV of \(String(format: "%.1f", hrv)) ms suggests your nervous system may need recovery. Consider light yoga or meditation.",
                    category: .recovery,
                    priority: .high
                ))
            } else if hrv >= 50 {
                newInsights.append(CircadianInsight(
                    title: "High HRV — Peak Readiness",
                    detail: "HRV of \(String(format: "%.1f", hrv)) ms indicates excellent autonomic balance. Great day for intense training.",
                    category: .recovery,
                    priority: .low
                ))
            }
        }

        // O2 Saturation insight
        if let spo2 = metrics[.oxygenSaturation]?.displayDouble {
            if spo2 < 95 {
                newInsights.append(CircadianInsight(
                    title: "Low Blood Oxygen",
                    detail: "SpO₂ of \(String(format: "%.1f", spo2))% is below 95%. Consult a healthcare provider if persistent.",
                    category: .breathing,
                    priority: .high
                ))
            }
        }

        insights = newInsights.sorted { $0.priority > $1.priority }
    }

    // MARK: Demo Data (Simulator / No HealthKit Data)
    private func makeDemoMetric(for type: MetricType) -> HealthMetric {
        let demoValues: [MetricType: Double] = [
            .heartRate:        72,
            .steps:            9450,
            .activeEnergy:     380,
            .restingEnergy:    1650,
            .oxygenSaturation: 0.98,
            .respiratoryRate:  15,
            .hrv:              0.045,
            .sleepHours:       7.2
        ]
        let value = demoValues[type] ?? 0

        let now = Date()
        let weeklyData: [HealthDataPoint] = (0..<7).map { day in
            let date = Calendar.current.date(byAdding: .day, value: -(6 - day), to: now) ?? now
            let jitter = Double.random(in: 0.85...1.15)
            return HealthDataPoint(timestamp: date, value: value * jitter, metricType: type)
        }

        return HealthMetric(
            type: type,
            currentValue: value,
            dailyAverage: value,
            weeklyData: weeklyData,
            trend: .stable,
            lastUpdated: now
        )
    }
}

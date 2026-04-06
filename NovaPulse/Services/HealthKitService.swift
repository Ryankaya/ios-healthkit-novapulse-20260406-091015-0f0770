import Foundation
import HealthKit
import Combine

// MARK: - Authorization Status
enum HKAuthStatus {
    case notDetermined
    case authorized
    case denied
}

// MARK: - HealthKitService
@MainActor
final class HealthKitService: ObservableObject {

    // MARK: Published State
    @Published var authorizationStatus: HKAuthStatus = .notDetermined
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: Private
    private let store = HKHealthStore()

    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        let identifiers: [HKQuantityTypeIdentifier] = [
            .heartRate,
            .stepCount,
            .activeEnergyBurned,
            .basalEnergyBurned,
            .oxygenSaturation,
            .respiratoryRate,
            .heartRateVariabilitySDNN
        ]
        identifiers.forEach { id in
            if let t = HKObjectType.quantityType(forIdentifier: id) {
                types.insert(t)
            }
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        return types
    }()

    // MARK: Init
    init() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .denied
            return
        }
    }

    // MARK: Authorization
    func requestAuthorization() {
        Task {
            do {
                try await store.requestAuthorization(toShare: [], read: readTypes)
                authorizationStatus = .authorized
            } catch {
                errorMessage = error.localizedDescription
                authorizationStatus = .denied
            }
        }
    }

    // MARK: Quantity Queries
    func fetchLatestSample(for type: MetricType) async throws -> Double? {
        guard let hkType = type.healthKitType, let unit = type.hkUnit else { return nil }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()),
                                                    end: Date())
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: hkType,
                                      predicate: predicate,
                                      limit: 1,
                                      sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    func fetchDailyStatistics(for type: MetricType, days: Int = 7) async throws -> [HealthDataPoint] {
        guard let hkType = type.healthKitType, let unit = type.hkUnit else { return [] }
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else { return [] }

        let interval = DateComponents(day: 1)
        let statisticsOptions: HKStatisticsOptions = (type == .steps ||
                                                       type == .activeEnergy ||
                                                       type == .restingEnergy)
            ? .cumulativeSum : .discreteAverage

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: hkType,
                quantitySamplePredicate: HKQuery.predicateForSamples(withStart: startDate, end: endDate),
                options: statisticsOptions,
                anchorDate: calendar.startOfDay(for: endDate),
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                var points: [HealthDataPoint] = []
                results?.enumerateStatistics(from: startDate, to: endDate) { stat, _ in
                    let value: Double?
                    if statisticsOptions == .cumulativeSum {
                        value = stat.sumQuantity()?.doubleValue(for: unit)
                    } else {
                        value = stat.averageQuantity()?.doubleValue(for: unit)
                    }
                    if let v = value {
                        points.append(HealthDataPoint(timestamp: stat.startDate, value: v, metricType: type))
                    }
                }
                continuation.resume(returning: points)
            }
            store.execute(query)
        }
    }

    // MARK: Sleep Query
    func fetchSleepHours(for date: Date = Date()) async throws -> Double {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }
        let calendar = Calendar.current
        let startOfDay = calendar.date(byAdding: .hour, value: -24, to: calendar.startOfDay(for: date)) ?? date

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: date)
            let query = HKSampleQuery(sampleType: sleepType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: nil) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let totalSeconds = (samples as? [HKCategorySample])?.filter {
                    $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                    $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                    $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                    $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                }.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } ?? 0
                continuation.resume(returning: totalSeconds / 3600)
            }
            store.execute(query)
        }
    }
}

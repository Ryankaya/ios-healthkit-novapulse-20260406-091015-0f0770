import Foundation
import HealthKit

/// Wraps HKHealthStore for the watchOS target. Authorization is requested
/// independently from the iOS companion app — required by HealthKit on watchOS.
@MainActor
final class WatchHealthService: ObservableObject {

    private let store = HKHealthStore()

    @Published var isAuthorized = false

    private let readTypes: Set<HKObjectType> = {
        var s = Set<HKObjectType>()
        let ids: [HKQuantityTypeIdentifier] = [
            .heartRate, .stepCount, .activeEnergyBurned, .oxygenSaturation
        ]
        ids.forEach { if let t = HKObjectType.quantityType(forIdentifier: $0) { s.insert(t) } }
        return s
    }()

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        Task {
            try? await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
        }
    }

    // MARK: - Queries

    func fetchTodaySteps() async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let start = Calendar.current.startOfDay(for: Date())
        return await cumulativeSum(type: type, start: start, unit: .count())
    }

    func fetchActiveEnergy() async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        let start = Calendar.current.startOfDay(for: Date())
        return await cumulativeSum(type: type, start: start, unit: .kilocalorie())
    }

    func fetchLatestHeartRate() async -> Double {
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

    func fetchLatestSpO2() async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else { return 0 }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1,
                                  sortDescriptors: [sort]) { _, s, _ in
                cont.resume(returning:
                    (s?.first as? HKQuantitySample)?.quantity.doubleValue(for: .percent()) ?? 0)
            }
            store.execute(q)
        }
    }

    // MARK: - Private helpers

    private func cumulativeSum(type: HKQuantityType, start: Date, unit: HKUnit) async -> Double {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, r, _ in
                cont.resume(returning: r?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(q)
        }
    }
}

import Foundation
import HealthKit

/// Lightweight HealthKit helper for widget timeline providers.
/// Inherits authorization from the host NovaPulse app — no extra prompt needed.
enum WidgetHealthService {
    private static let store = HKHealthStore()

    // MARK: Today's Steps (cumulative sum)
    static func fetchTodaySteps() async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, res, _ in
                cont.resume(returning: res?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            }
            store.execute(q)
        }
    }

    // MARK: Latest Heart Rate
    static func fetchLatestHeartRate() async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else { return 0 }
        let unit = HKUnit.count().unitDivided(by: .minute())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1,
                                  sortDescriptors: [sort]) { _, samples, _ in
                cont.resume(returning: (samples?.first as? HKQuantitySample)?
                    .quantity.doubleValue(for: unit) ?? 0)
            }
            store.execute(q)
        }
    }

    // MARK: Today's Active Energy
    static func fetchActiveEnergy() async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, res, _ in
                cont.resume(returning: res?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0)
            }
            store.execute(q)
        }
    }
}

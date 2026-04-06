import SwiftUI
import HealthKit

// MARK: - Metric Type
enum MetricType: String, CaseIterable, Codable, Identifiable {
    case heartRate       = "Heart Rate"
    case steps           = "Steps"
    case activeEnergy    = "Active Energy"
    case restingEnergy   = "Resting Energy"
    case oxygenSaturation = "Blood Oxygen"
    case respiratoryRate = "Respiratory Rate"
    case hrv             = "Heart Rate Variability"
    case sleepHours      = "Sleep"

    var id: String { rawValue }

    var unit: String {
        switch self {
        case .heartRate:        return "bpm"
        case .steps:            return "steps"
        case .activeEnergy:     return "kcal"
        case .restingEnergy:    return "kcal"
        case .oxygenSaturation: return "%"
        case .respiratoryRate:  return "br/min"
        case .hrv:              return "ms"
        case .sleepHours:       return "hrs"
        }
    }

    var icon: String {
        switch self {
        case .heartRate:        return "heart.fill"
        case .steps:            return "figure.walk"
        case .activeEnergy:     return "flame.fill"
        case .restingEnergy:    return "bolt.heart.fill"
        case .oxygenSaturation: return "lungs.fill"
        case .respiratoryRate:  return "wind"
        case .hrv:              return "waveform.path.ecg"
        case .sleepHours:       return "moon.zzz.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .heartRate:        return .npRed
        case .steps:            return .npGreen
        case .activeEnergy:     return .npOrange
        case .restingEnergy:    return .npYellow
        case .oxygenSaturation: return .npBlue
        case .respiratoryRate:  return .npCyan
        case .hrv:              return .npPurple
        case .sleepHours:       return .npIndigo
        }
    }

    var healthKitType: HKQuantityType? {
        switch self {
        case .heartRate:
            return HKObjectType.quantityType(forIdentifier: .heartRate)
        case .steps:
            return HKObjectType.quantityType(forIdentifier: .stepCount)
        case .activeEnergy:
            return HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
        case .restingEnergy:
            return HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)
        case .oxygenSaturation:
            return HKObjectType.quantityType(forIdentifier: .oxygenSaturation)
        case .respiratoryRate:
            return HKObjectType.quantityType(forIdentifier: .respiratoryRate)
        case .hrv:
            return HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
        case .sleepHours:
            return nil // Handled via HKCategoryType
        }
    }

    var hkUnit: HKUnit? {
        switch self {
        case .heartRate:        return HKUnit.count().unitDivided(by: .minute())
        case .steps:            return .count()
        case .activeEnergy:     return .kilocalorie()
        case .restingEnergy:    return .kilocalorie()
        case .oxygenSaturation: return .percent()
        case .respiratoryRate:  return HKUnit.count().unitDivided(by: .minute())
        case .hrv:              return .secondUnit(with: .milli)
        case .sleepHours:       return nil
        }
    }

    var normalRange: ClosedRange<Double> {
        switch self {
        case .heartRate:        return 60...100
        case .steps:            return 7000...15000
        case .activeEnergy:     return 200...600
        case .restingEnergy:    return 1200...2000
        case .oxygenSaturation: return 95...100
        case .respiratoryRate:  return 12...20
        case .hrv:              return 20...100
        case .sleepHours:       return 7...9
        }
    }
}

// MARK: - Health Data Point
struct HealthDataPoint: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let value: Double
    let metricType: MetricType

    init(id: UUID = UUID(), timestamp: Date, value: Double, metricType: MetricType) {
        self.id = id
        self.timestamp = timestamp
        self.value = value
        self.metricType = metricType
    }
}

// MARK: - Health Metric (aggregated)
struct HealthMetric: Identifiable, Codable {
    let id: UUID
    let type: MetricType
    var currentValue: Double
    var dailyAverage: Double
    var weeklyData: [HealthDataPoint]
    var trend: MetricTrend
    var lastUpdated: Date

    init(
        id: UUID = UUID(),
        type: MetricType,
        currentValue: Double = 0,
        dailyAverage: Double = 0,
        weeklyData: [HealthDataPoint] = [],
        trend: MetricTrend = .stable,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.currentValue = currentValue
        self.dailyAverage = dailyAverage
        self.weeklyData = weeklyData
        self.trend = trend
        self.lastUpdated = lastUpdated
    }

    var formattedValue: String {
        switch type {
        case .steps, .heartRate, .respiratoryRate:
            return String(format: "%.0f", currentValue)
        case .activeEnergy, .restingEnergy:
            return String(format: "%.0f", currentValue)
        case .oxygenSaturation:
            return String(format: "%.1f", currentValue * 100)
        case .hrv:
            return String(format: "%.1f", currentValue * 1000)
        case .sleepHours:
            return String(format: "%.1f", currentValue)
        }
    }

    var isInNormalRange: Bool {
        let displayValue = displayDouble
        return type.normalRange.contains(displayValue)
    }

    var displayDouble: Double {
        switch type {
        case .oxygenSaturation: return currentValue * 100
        case .hrv:              return currentValue * 1000
        default:                return currentValue
        }
    }
}

// MARK: - Trend
enum MetricTrend: String, Codable {
    case rising   = "rising"
    case falling  = "falling"
    case stable   = "stable"

    var icon: String {
        switch self {
        case .rising:  return "arrow.up.right"
        case .falling: return "arrow.down.right"
        case .stable:  return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .rising:  return .npGreen
        case .falling: return .npRed
        case .stable:  return .npBlue
        }
    }
}

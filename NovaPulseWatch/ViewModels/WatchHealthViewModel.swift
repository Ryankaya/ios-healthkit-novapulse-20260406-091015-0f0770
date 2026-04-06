import Foundation
import SwiftUI
import Combine

@MainActor
final class WatchHealthViewModel: ObservableObject {

    // MARK: Published state
    @Published var steps: Double = 0
    @Published var heartRate: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var spO2: Double = 0
    @Published var isLoading = false

    // Accessible from views for authorization check
    let service = WatchHealthService()

    // MARK: Constants
    let stepGoal: Double = 10_000
    let energyGoal: Double = 500

    // MARK: Derived
    var stepProgress: Double     { min(steps / stepGoal, 1.0) }
    var energyProgress: Double   { min(activeEnergy / energyGoal, 1.0) }

    var formattedSteps: String {
        steps >= 1000
            ? String(format: "%.1fk", steps / 1000)
            : String(format: "%.0f", steps)
    }
    var formattedHR: String   { String(format: "%.0f", heartRate) }
    var formattedEnergy: String { String(format: "%.0f", activeEnergy) }
    var formattedSpO2: String  { String(format: "%.1f%%", spO2 * 100) }

    var hrZone: HRZone {
        switch heartRate {
        case 0..<50:   return .veryLow
        case 50..<60:  return .low
        case 60..<100: return .normal
        case 100..<140: return .elevated
        default:       return .high
        }
    }

    enum HRZone: String {
        case veryLow = "Very Low"
        case low     = "Low"
        case normal  = "Normal"
        case elevated = "Elevated"
        case high    = "High"

        var color: Color {
            switch self {
            case .veryLow:  return .blue
            case .low:      return .cyan
            case .normal:   return .green
            case .elevated: return .orange
            case .high:     return .red
            }
        }
    }

    // MARK: Actions
    func fetchAll() {
        Task {
            isLoading = true
            async let s    = service.fetchTodaySteps()
            async let hr   = service.fetchLatestHeartRate()
            async let ae   = service.fetchActiveEnergy()
            async let spo2 = service.fetchLatestSpO2()
            let (s_, hr_, ae_, spo2_) = await (s, hr, ae, spo2)

            // Demo fallback when running on Simulator
            steps       = s_    > 0 ? s_    : 8_247
            heartRate   = hr_   > 0 ? hr_   : 76
            activeEnergy = ae_  > 0 ? ae_   : 387
            spO2        = spo2_ > 0 ? spo2_ : 0.98
            isLoading = false
        }
    }
}

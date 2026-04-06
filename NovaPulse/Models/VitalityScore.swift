import Foundation

// MARK: - Vitality Score
struct VitalityScore: Codable {
    let overall: Double         // 0–100
    let cardiovascular: Double  // heart rate + HRV
    let activity: Double        // steps + active energy
    let recovery: Double        // sleep + HRV
    let respiratory: Double     // O2 sat + respiratory rate
    let computedAt: Date

    var grade: Grade {
        switch overall {
        case 85...100: return .excellent
        case 70..<85:  return .good
        case 55..<70:  return .fair
        default:       return .needsAttention
        }
    }

    enum Grade: String, Codable {
        case excellent      = "Excellent"
        case good           = "Good"
        case fair           = "Fair"
        case needsAttention = "Needs Attention"

        var emoji: String {
            switch self {
            case .excellent:      return "⚡️"
            case .good:           return "✅"
            case .fair:           return "⚠️"
            case .needsAttention: return "🔴"
            }
        }
    }
}

// MARK: - Circadian Insight
struct CircadianInsight: Identifiable, Codable {
    let id: UUID
    let title: String
    let detail: String
    let category: InsightCategory
    let priority: InsightPriority
    let generatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        category: InsightCategory,
        priority: InsightPriority,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.category = category
        self.priority = priority
        self.generatedAt = generatedAt
    }
}

enum InsightCategory: String, Codable {
    case sleep        = "Sleep"
    case activity     = "Activity"
    case heart        = "Heart"
    case breathing    = "Breathing"
    case recovery     = "Recovery"

    var icon: String {
        switch self {
        case .sleep:    return "moon.zzz.fill"
        case .activity: return "figure.run"
        case .heart:    return "heart.fill"
        case .breathing: return "wind"
        case .recovery: return "arrow.clockwise.heart.fill"
        }
    }
}

enum InsightPriority: Int, Codable, Comparable {
    case low    = 0
    case medium = 1
    case high   = 2

    static func < (lhs: InsightPriority, rhs: InsightPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

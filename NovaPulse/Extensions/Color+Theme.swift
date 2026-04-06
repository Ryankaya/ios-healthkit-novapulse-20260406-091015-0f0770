import SwiftUI

extension Color {
    // NovaPulse brand palette
    static let npBackground   = Color("npBackground")
    static let npCard         = Color("npCard")
    static let npRed          = Color("npRed")
    static let npGreen        = Color("npGreen")
    static let npBlue         = Color("npBlue")
    static let npOrange       = Color("npOrange")
    static let npYellow       = Color("npYellow")
    static let npCyan         = Color("npCyan")
    static let npPurple       = Color("npPurple")
    static let npIndigo       = Color("npIndigo")
    static let npTextPrimary  = Color("npTextPrimary")
    static let npTextSecondary = Color("npTextSecondary")

    // Fallback raw values (used if asset catalog colors not found)
    static let npRedFallback    = Color(red: 1.0,  green: 0.27, blue: 0.27)
    static let npGreenFallback  = Color(red: 0.18, green: 0.85, blue: 0.55)
    static let npBlueFallback   = Color(red: 0.27, green: 0.60, blue: 1.0)
    static let npOrangeFallback = Color(red: 1.0,  green: 0.58, blue: 0.0)
}

extension LinearGradient {
    static func npGradient(colors: [Color]) -> LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let scoreGradient = npGradient(colors: [.npBlue, .npPurple])
    static let heartGradient = npGradient(colors: [.npRed, .npOrange])
    static let activityGradient = npGradient(colors: [.npGreen, .npCyan])
}

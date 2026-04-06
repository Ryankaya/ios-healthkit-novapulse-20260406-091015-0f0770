# NovaPulse — Biometric Intelligence Dashboard

**Feature:** HealthKit
**Platform:** iOS 17+
**Architecture:** MVVM (strict)
**Date:** 2026-04-06

---

## What is NovaPulse?

NovaPulse is a production-quality iOS health monitoring app that transforms raw Apple Health data into a unified **Biometric Intelligence Dashboard**. It reads eight distinct HealthKit metrics and synthesises them into an animated **Vitality Score** ring (0–100), weekly trend sparklines, and AI-style circadian insights — all rendered in a dark glassmorphism UI.

### Metrics Tracked
| Metric | HealthKit Type | Normal Range |
|--------|---------------|-------------|
| Heart Rate | `.heartRate` | 60–100 bpm |
| Steps | `.stepCount` | 7,000–15,000 |
| Active Energy | `.activeEnergyBurned` | 200–600 kcal |
| Resting Energy | `.basalEnergyBurned` | 1,200–2,000 kcal |
| Blood Oxygen | `.oxygenSaturation` | 95–100% |
| Respiratory Rate | `.respiratoryRate` | 12–20 br/min |
| HRV | `.heartRateVariabilitySDNN` | 20–100 ms |
| Sleep | `HKCategoryType (.sleepAnalysis)` | 7–9 hrs |

### Key Features
- **Vitality Score Ring** — animated circular progress gauge blending cardiovascular, activity, recovery, and respiratory sub-scores
- **Swift Charts integration** — area + line chart with normal-range guide lines; supports Day / Week / Month ranges
- **Circadian Insights** — rule-based engine generates expandable insight cards ranked by priority (high/medium/low)
- **Mini Sparklines** — 7-day hand-drawn `Path` chart on every metric card
- **Demo Mode** — realistic synthetic data when HealthKit has no samples (Simulator friendly)
- **Pull-to-refresh** — parallel async fetching via `TaskGroup` for all eight metrics

---

## Architecture

```
NovaPulse/
├── App/
│   ├── NovaPulseApp.swift        # @main, injects HealthKitService
│   └── ContentView.swift         # Auth gate → Dashboard
├── Models/
│   ├── HealthMetric.swift        # MetricType, HealthMetric, HealthDataPoint, MetricTrend
│   └── VitalityScore.swift       # VitalityScore, CircadianInsight, InsightCategory
├── ViewModels/
│   ├── HealthDashboardViewModel.swift  # Fetches all metrics, computes score + insights
│   └── MetricDetailViewModel.swift     # Per-metric chart data + range switching
├── Views/
│   ├── PermissionView.swift      # HealthKit authorization onboarding
│   ├── DashboardView.swift       # LazyVGrid of metric cards + score + insights
│   ├── MetricCardView.swift      # Card + sparkline
│   ├── VitalityScoreView.swift   # Animated ring gauge
│   ├── InsightsView.swift        # Expandable insight rows
│   └── MetricDetailView.swift    # Full Swift Charts detail + range picker
├── Services/
│   └── HealthKitService.swift    # HKHealthStore wrapper, async/await queries
├── Extensions/
│   └── Color+Theme.swift         # Brand color palette + gradients
└── Resources/
    └── Info.plist                # NSHealth* usage descriptions
```

**MVVM rules:**
- Models are plain `struct`/`enum` — Codable, no UIKit/SwiftUI imports
- ViewModels are `@MainActor ObservableObject` with `@Published` properties
- Views contain zero business logic — only render and forward events

---

## Apple Developer Documentation

- [HealthKit Framework Overview](https://developer.apple.com/documentation/healthkit)
  Core concepts: `HKHealthStore`, data types, authorization model, `HKSampleQuery`, `HKStatisticsCollectionQuery`.

- [Reading Data from HealthKit](https://developer.apple.com/documentation/healthkit/reading_data_from_healthkit)
  How to build predicates, execute queries, and interpret `HKQuantitySample` and `HKCategorySample` results.

- [HKStatisticsCollectionQuery](https://developer.apple.com/documentation/healthkit/hkstatisticscollectionquery)
  Used for daily aggregated step counts, energy, and averages over the 7-day chart window.

- [Swift Charts](https://developer.apple.com/documentation/charts)
  `AreaMark`, `LineMark`, `PointMark`, `RuleMark`, `AxisMarks` used in `MetricDetailView`.

---

## Setup

1. Open `NovaPulse.xcodeproj` in Xcode 15+
2. Select your development team under *Signing & Capabilities*
3. Enable the **HealthKit** capability (already in entitlements)
4. Run on a physical iPhone for live HealthKit data, or Simulator for demo mode

---

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9

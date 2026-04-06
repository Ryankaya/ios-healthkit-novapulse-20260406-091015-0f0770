import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @EnvironmentObject var dashboardVM: HealthDashboardViewModel

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerSection

                        // Vitality Score
                        if let score = dashboardVM.vitalityScore {
                            VitalityScoreView(score: score)
                                .padding(.horizontal)
                        }

                        // Metrics Grid
                        if !dashboardVM.metrics.isEmpty {
                            metricsGrid
                        }

                        // Insights
                        if !dashboardVM.insights.isEmpty {
                            InsightsView(insights: dashboardVM.insights)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 32)
                }
                .refreshable {
                    dashboardVM.fetchAllMetrics()
                }

                if dashboardVM.isRefreshing && dashboardVM.metrics.isEmpty {
                    loadingOverlay
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            dashboardVM.fetchAllMetrics()
        }
    }

    // MARK: Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("NovaPulse")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(Date(), style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            if dashboardVM.isRefreshing {
                ProgressView()
                    .tint(.white.opacity(0.6))
                    .scaleEffect(0.85)
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }

    // MARK: Metrics Grid
    private var metricsGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(MetricType.allCases) { type in
                if let metric = dashboardVM.metrics[type] {
                    NavigationLink(destination: metricDetailDestination(for: type)) {
                        MetricCardView(metric: metric)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func metricDetailDestination(for type: MetricType) -> some View {
        MetricDetailView(metricType: type)
            .environmentObject(healthKitService)
    }

    // MARK: Loading
    private var loadingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
            Text("Reading health data…")
                .foregroundStyle(.white.opacity(0.7))
                .font(.subheadline)
        }
    }
}

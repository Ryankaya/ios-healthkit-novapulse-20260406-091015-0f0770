import SwiftUI
import Charts

struct MetricDetailView: View {
    let metricType: MetricType

    @EnvironmentObject var healthKitService: HealthKitService
    @StateObject private var viewModel = MetricDetailViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Current Value Hero
                    heroSection

                    // Range Picker
                    rangePicker

                    // Chart
                    chartSection

                    // Stats
                    statsSection
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(metricType.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            viewModel.configure(metricType: metricType, service: healthKitService)
        }
    }

    // MARK: Hero
    private var heroSection: some View {
        HStack(spacing: 0) {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: metricType.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(metricType.accentColor)
                    .padding()
                    .background(metricType.accentColor.opacity(0.15))
                    .clipShape(Circle())

                if let metric = viewModel.metric {
                    Text(metric.formattedValue)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(metricType.unit)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.5))
                } else {
                    ProgressView().tint(metricType.accentColor)
                }
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: Range Picker
    private var rangePicker: some View {
        HStack {
            ForEach(MetricDetailViewModel.ChartRange.allCases, id: \.self) { range in
                Button {
                    viewModel.changeRange(range, for: metricType)
                } label: {
                    Text(range.rawValue)
                        .font(.subheadline)
                        .fontWeight(viewModel.chartRange == range ? .bold : .regular)
                        .foregroundStyle(viewModel.chartRange == range ? .black : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.chartRange == range
                                ? metricType.accentColor
                                : Color.white.opacity(0.08)
                        )
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: Chart
    @ViewBuilder
    private var chartSection: some View {
        if !viewModel.chartPoints.isEmpty {
            Chart {
                ForEach(viewModel.chartPoints, id: \.x) { point in
                    AreaMark(
                        x: .value("Date", point.x),
                        y: .value(metricType.rawValue, point.y)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [metricType.accentColor.opacity(0.5), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Date", point.x),
                        y: .value(metricType.rawValue, point.y)
                    )
                    .foregroundStyle(metricType.accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                    PointMark(
                        x: .value("Date", point.x),
                        y: .value(metricType.rawValue, point.y)
                    )
                    .foregroundStyle(metricType.accentColor)
                    .symbolSize(40)
                }

                // Normal range band
                RuleMark(y: .value("Min", metricType.normalRange.lowerBound))
                    .foregroundStyle(.white.opacity(0.15))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .trailing) {
                        Text("Min")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.35))
                    }

                RuleMark(y: .value("Max", metricType.normalRange.upperBound))
                    .foregroundStyle(.white.opacity(0.15))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .trailing) {
                        Text("Max")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.35))
                    }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(.white.opacity(0.1))
                    AxisValueLabel().foregroundStyle(.white.opacity(0.4))
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(.white.opacity(0.1))
                    AxisValueLabel().foregroundStyle(.white.opacity(0.4))
                }
            }
            .frame(height: 220)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.06))
            )
        } else if viewModel.isLoading {
            ProgressView()
                .tint(metricType.accentColor)
                .frame(height: 220)
        }
    }

    // MARK: Stats
    @ViewBuilder
    private var statsSection: some View {
        if let metric = viewModel.metric {
            HStack(spacing: 12) {
                statCard(title: "Average", value: averageString(for: metric), color: metricType.accentColor)
                statCard(title: "Trend", value: metric.trend.icon, color: metric.trend.color, isIcon: true)
                statCard(title: "Status", value: metric.isInNormalRange ? "Normal" : "Abnormal",
                         color: metric.isInNormalRange ? .npGreenFallback : .npRedFallback)
            }
        }
    }

    private func averageString(for metric: HealthMetric) -> String {
        let avg: Double
        switch metricType {
        case .oxygenSaturation: avg = metric.dailyAverage * 100
        case .hrv:              avg = metric.dailyAverage * 1000
        default:                avg = metric.dailyAverage
        }
        return String(format: "%.1f %@", avg, metricType.unit)
    }

    @ViewBuilder
    private func statCard(title: String, value: String, color: Color, isIcon: Bool = false) -> some View {
        VStack(spacing: 6) {
            if isIcon {
                Image(systemName: value)
                    .font(.title2)
                    .foregroundStyle(color)
            } else {
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.07))
        )
    }
}

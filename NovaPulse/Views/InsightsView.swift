import SwiftUI

struct InsightsView: View {
    let insights: [CircadianInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.npOrangeFallback)
                Text("Biometric Insights")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            ForEach(insights) { insight in
                InsightRowView(insight: insight)
            }
        }
    }
}

struct InsightRowView: View {
    let insight: CircadianInsight
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    // Category icon
                    Image(systemName: insight.category.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(priorityColor)
                        .frame(width: 32, height: 32)
                        .background(priorityColor.opacity(0.15))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Text(insight.category.rawValue)
                            .font(.caption2)
                            .foregroundStyle(priorityColor.opacity(0.8))
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(insight.detail)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.leading, 44)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(priorityColor.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var priorityColor: Color {
        switch insight.priority {
        case .high:   return Color.npRedFallback
        case .medium: return Color.npOrangeFallback
        case .low:    return Color.npGreenFallback
        }
    }
}

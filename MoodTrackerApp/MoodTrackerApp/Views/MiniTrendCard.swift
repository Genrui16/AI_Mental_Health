#if os(iOS)
import SwiftUI
import Charts

/// Sparkline 风格的迷你趋势卡片。
@available(iOS 16.0, *)
struct MiniTrendCard: View {
    let title: String
    let points: [(Date, Double)]
    let unit: String

    private var trendArrow: (name: String, color: Color)? {
        guard points.count >= 2 else { return nil }
        let diff = points.last!.1 - points[points.count - 2].1
        return diff >= 0 ? ("arrow.up", .green) : ("arrow.down", .red)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
            if let last = points.last?.1 {
                HStack(alignment: .top) {
                    Text("\(Int(last)) \(unit)")
                        .font(.headline)
                    Spacer()
                    if let arrow = trendArrow {
                        Image(systemName: arrow.name)
                            .font(.caption.bold())
                            .foregroundStyle(arrow.color)
                    }
                }
            }
            Chart(points, id: \.0) {
                LineMark(x: .value("Date", $0.0), y: .value("Value", $0.1))
                AreaMark(x: .value("Date", $0.0), y: .value("Value", $0.1))
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 72)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
#endif

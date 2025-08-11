#if os(iOS)
import SwiftUI
import Charts

/// 心情趋势视图，用于展示用户的情绪变化和节律评分趋势图。
struct MoodTrendView: View {
    /// 心情记录列表，由外部传入。
    var moodLogs: [MoodLog]

    /// 显示的时间范围，默认一周。
    @State private var selectedRange: TimeRange = .week

    /// 过滤后的日志，根据所选时间范围。
    private var filteredLogs: [MoodLog] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -selectedRange.days, to: Date()) ?? Date()
        return moodLogs.filter { $0.time >= startDate }
    }

    /// 将心情日志映射为图表数据点。
    private var chartData: [MoodChartData] {
        filteredLogs.map { log in
            MoodChartData(date: log.time, score: moodScore(for: log.mood))
        }
        .sorted { $0.date < $1.date }
    }

    /// 简单的趋势说明。
    private var trendDescription: String {
        guard chartData.count >= 2,
              let first = chartData.first?.score,
              let last = chartData.last?.score else {
            return "数据不足无法判断趋势"
        }
        let diff = last - first
        let maxScore = chartData.map { $0.score }.max() ?? last
        let minScore = chartData.map { $0.score }.min() ?? first
        if diff > 0 {
            return "情绪整体呈上升趋势 (最高\(maxScore)分, 最低\(minScore)分)"
        } else if diff < 0 {
            return "情绪整体呈下降趋势 (最高\(maxScore)分, 最低\(minScore)分)"
        } else {
            return "情绪保持稳定 (最高\(maxScore)分, 最低\(minScore)分)"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("范围", selection: $selectedRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)

            Chart(chartData) { point in
                LineMark(
                    x: .value("日期", point.date),
                    y: .value("评分", point.score)
                )
                PointMark(
                    x: .value("日期", point.date),
                    y: .value("评分", point.score)
                )
            }
            .frame(height: 200)
            .chartYScale(domain: 0...10)

            Text(trendDescription)
                .font(.footnote)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle("心情趋势")
    }
}

/// 图表使用的数据结构。
struct MoodChartData: Identifiable {
    let id = UUID()
    let date: Date
    let score: Int
}

/// 支持的时间范围。
enum TimeRange: String, CaseIterable, Identifiable {
    case week = "一周"
    case month = "一月"

    var id: Self { self }

    /// 对应的天数。
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        }
    }
}

/// 将心情字符串转为数值评分，用于绘制图表。
private func moodScore(for mood: String) -> Int {
    let mapping: [String: Int] = [
        "非常不好": 2,
        "不好": 4,
        "一般": 6,
        "好": 8,
        "很好": 10
    ]
    return mapping[mood] ?? 6
}

// MARK: - 预览
#if DEBUG
struct MoodTrendView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MoodTrendView(moodLogs: [])
        }
    }
}
#endif
#endif

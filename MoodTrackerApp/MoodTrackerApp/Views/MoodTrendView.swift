#if os(iOS)
import SwiftUI
import Charts

/// 心情趋势视图，用于展示用户的情绪变化和节律评分趋势图。
struct MoodTrendView: View {
    /// 传入心情记录列表，可在实际使用时注入。
    var moodLogs: [MoodLog] = []

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
        guard let first = chartData.first?.score, let last = chartData.last?.score else {
            return "暂无足够数据"
        }
        let diff = last - first
        if diff > 0 {
            return "情绪整体呈上升趋势"
        } else if diff < 0 {
            return "情绪整体呈下降趋势"
        } else {
            return "情绪保持稳定"
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
        "非常不好": 1,
        "不好": 2,
        "一般": 3,
        "好": 4,
        "很好": 5
    ]
    return mapping[mood] ?? 3
}

// MARK: - 预览
#if DEBUG
struct MoodTrendView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MoodTrendView()
        }
    }
}
#endif
#endif

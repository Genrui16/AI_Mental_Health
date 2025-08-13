import Foundation

enum SuggestionType: String, Codable, CaseIterable {
    case hydrate, medReminder, walk, stretch, journal, breathe, sleep, social, custom
}

enum SuggestionAction: String, Codable { case shown, accepted, skipped, snoozed }

struct SuggestionEvent: Codable, Identifiable {
    let id: UUID
    let type: SuggestionType
    let time: Date
    let action: SuggestionAction
    let context: Context
    struct Context: Codable {
        let hour: Int
        let weekday: Int
        let locationHint: String?
    }
}

struct SuggestionStats {
    var shown = 0
    var skipped = 0
    var lastShownAt: Date?
    // Jeffreys prior: Beta(0.5, 0.5)
    var skipRateSmoothed: Double {
        let a = Double(skipped) + 0.5
        let b = Double(shown - skipped) + 0.5
        return a / (a + b)
    }
}

final class SuggestionAnalytics {
    private(set) var byType: [SuggestionType: SuggestionStats] = [:]
    private(set) var byTypeHour: [SuggestionType: [Int: SuggestionStats]] = [:]

    func ingest(_ e: SuggestionEvent) {
        var stats = byType[e.type, default: .init()]
        if e.action == .shown { stats.shown += 1; stats.lastShownAt = e.time }
        if e.action == .skipped { stats.skipped += 1 }
        byType[e.type] = stats

        var hourMap = byTypeHour[e.type, default: [:]]
        var hourStats = hourMap[e.context.hour, default: .init()]
        if e.action == .shown { hourStats.shown += 1; hourStats.lastShownAt = e.time }
        if e.action == .skipped { hourStats.skipped += 1 }
        hourMap[e.context.hour] = hourStats
        byTypeHour[e.type] = hourMap
    }

    /// 返回 TopN（跳过率高且曝光数足够）
    func topNSkipped(_ n: Int = 3, minShown: Int = 5) -> [(SuggestionType, SuggestionStats)] {
        byType
            .filter { $0.value.shown >= minShown }
            .sorted { $0.value.skipRateSmoothed > $1.value.skipRateSmoothed }
            .prefix(n)
            .map { ($0.key, $0.value) }
    }

    /// 给出“更可能被接受”的时段建议（找该类型跳过率最低的时段）
    func betterHours(for type: SuggestionType, minShown: Int = 3) -> [Int] {
        let hourStats = byTypeHour[type] ?? [:]
        return hourStats
            .filter { $0.value.shown >= minShown }
            .sorted { $0.value.skipRateSmoothed < $1.value.skipRateSmoothed }
            .prefix(3)
            .map { $0.key }
            .sorted()
    }
}

func makeSystemPrompt(userName: String, analytics: SuggestionAnalytics) -> String {
    let top = analytics.topNSkipped(3)
    var lines = [
        "你是 MindSync 的日程与健康助手。给用户提供高度可执行、轻量的建议，兼顾个性化与节奏感。"
    ]
    if !top.isEmpty {
        lines.append("请降低以下建议类型的出现频率，或优先改在更合适的时段给出：")
        for (type, stats) in top {
            let hours = analytics.betterHours(for: type)
            let hourText = hours.isEmpty ? "（改时段暂不明确）" : "建议时段：\(hours.map { "\($0)点" }.joined(separator: "、"))"
            lines.append("- \(type.rawValue)：近期跳过率≈\(Int(stats.skipRateSmoothed * 100))%，\(hourText)")
        }
        lines.append("除非用户主动请求或上下文强相关，不要连续两次给同一类型的建议。若必须给，请调整为『更短更具体』的版本。")
    }
    lines.append("回复时请包含简短理由和一步起手动作。")
    return lines.joined(separator: "\n")
}


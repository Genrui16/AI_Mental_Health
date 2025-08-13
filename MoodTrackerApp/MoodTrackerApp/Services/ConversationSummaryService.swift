import Foundation
#if canImport(NaturalLanguage)
import NaturalLanguage
#endif

/// 通过本地分析生成用户对话摘要，避免将完整对话上传到云端。
@MainActor
final class ConversationSummaryService {
    static let shared = ConversationSummaryService()
    private init() {}

    /// 根据给定的聊天会话生成简要摘要并保存。
    func updateSummary(with sessions: [ChatSession]) {
        let summary = generateSummary(from: sessions)
        if !summary.isEmpty {
            UserSummaryStore.shared.save(summary: summary)
        }
    }

    /// 使用简单的关键词统计生成摘要。
    private func generateSummary(from sessions: [ChatSession]) -> String {
        // 仅统计最近 14 天的用户消息
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let recentSessions = sessions.filter { $0.date >= startDate }
        let texts = recentSessions.flatMap { $0.messages }.filter { $0.role == .user }.map { $0.text }
        guard !texts.isEmpty else { return "" }
        let joined = texts.joined(separator: " ")
        #if canImport(NaturalLanguage)
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = joined
        var counts: [String: Int] = [:]
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther]
        tagger.enumerateTags(in: joined.startIndex..<joined.endIndex, unit: .word, scheme: .lemma, options: options) { tag, _ in
            if let lemma = tag?.rawValue {
                counts[lemma, default: 0] += 1
            }
            return true
        }
        // 过滤出现次数少于 5 次的关键词，并取 Top3
        let keywords = counts.filter { $0.value >= 5 }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
        return keywords.isEmpty ? "" : "常提到: " + keywords.joined(separator: ", ")
        #else
        // 如果不支持 NaturalLanguage，则简单截取最近消息。
        return texts.suffix(5).joined(separator: ", ")
        #endif
    }
}

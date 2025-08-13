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
        let texts = sessions.flatMap { $0.messages }.filter { $0.role == .user }.map { $0.text }
        guard !texts.isEmpty else { return "" }
        let joined = texts.joined(separator: " ")
        #if canImport(NaturalLanguage)
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = joined
        var counts: [String: Int] = [:]
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther]
        tagger.enumerateTags(in: joined.startIndex..<joined.endIndex, unit: .word, scheme: .lemma, options: options) { tag, tokenRange in
            if let lemma = tag?.rawValue {
                counts[lemma, default: 0] += 1
            }
            return true
        }
        let keywords = counts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
        return "常提到: " + keywords.joined(separator: ", ")
        #else
        // 如果不支持 NaturalLanguage，则简单截取最近消息。
        return texts.suffix(5).joined(separator: ", ")
        #endif
    }
}

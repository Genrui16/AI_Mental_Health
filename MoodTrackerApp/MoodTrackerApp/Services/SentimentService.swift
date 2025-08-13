import Foundation
import NaturalLanguage

@MainActor
final class SentimentService {
    static let shared = SentimentService()
    private init() {}

    /// 自定义中文情感词表，用于弥补 NaturalLanguage 对中文支持有限的问题。
    private let positiveKeywords: [String] = ["开心", "高兴", "快乐", "满意", "幸福", "喜悦", "兴奋", "期待"]
    private let negativeKeywords: [String] = ["不开心", "难过", "悲伤", "沮丧", "生气", "愤怒", "压力", "抑郁", "焦虑"]
    
    func analyze(_ text: String) -> Double? {
        // 先根据自定义词表判断中文情感倾向
        var score: Double = 0
        for word in positiveKeywords {
            if text.contains(word) {
                score += 1
            }
        }
        for word in negativeKeywords {
            if text.contains(word) {
                score -= 1
            }
        }
        if score > 0 {
            return 0.5
        } else if score < 0 {
            return -0.5
        }
        // 若词表未覆盖，则调用系统情感分析作为退化方案
        if #available(iOS 13.0, macOS 10.15, *) {
            let tagger = NLTagger(tagSchemes: [.sentimentScore])
            tagger.string = text
            let (tag, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
            if let scoreString = tag?.rawValue, let score = Double(scoreString) {
                return score
            }
            return 0.0
        } else {
            return nil
        }
    }

    func label(for score: Double) -> String {
        if score > 0.1 {
            return "积极"
        } else if score < -0.1 {
            return "消极"
        } else {
            return "中性"
        }
    }
}

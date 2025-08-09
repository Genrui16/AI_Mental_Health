import Foundation
import NaturalLanguage

@MainActor
final class SentimentService {
    static let shared = SentimentService()
    private init() {}
    
    func analyze(_ text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let (tag, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        if let scoreString = tag?.rawValue, let score = Double(scoreString) {
            return score
        }
        return 0.0
    }
    
    func label(for score: Double) -> String {
        switch score {
        case let x where x > 0.2: return "积极"
        case let x where x < -0.2: return "消极"
        default: return "中性"
        }
    }
}

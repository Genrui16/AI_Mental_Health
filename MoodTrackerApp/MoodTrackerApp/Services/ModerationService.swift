import Foundation

struct ModerationResult: Decodable {
    struct Item: Decodable {
        let flagged: Bool
        let categories: [String: Bool]
        let category_scores: [String: Double]?
    }
    let id: String
    let model: String
    let results: [Item]
}

enum ModerationDecision {
    case allow
    case softBlock(reason: String)
    case hardBlock(reason: String)
}

final class ModerationService {
    private let apiKey: String
    init(apiKey: String) { self.apiKey = apiKey }

    func check(text: String) async throws -> ModerationDecision {
        let url = URL(string: "https://api.openai.com/v1/moderations")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let payload: [String: Any] = [
            "model": "omni-moderation-latest",
            "input": text
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, _) = try await URLSession.shared.data(for: req)
        let result = try JSONDecoder().decode(ModerationResult.self, from: data)
        guard let r = result.results.first else { return .allow }

        let c = r.categories
        if c["self-harm"] == true || c["self-harm/intent"] == true || c["self-harm/instructions"] == true {
            return .hardBlock(reason: "self_harm")
        }
        if c["sexual/minors"] == true {
            return .hardBlock(reason: "sexual_minors")
        }
        if c["illicit"] == true || c["illicit/violent"] == true {
            return .softBlock(reason: "illicit")
        }
        if r.flagged {
            return .softBlock(reason: "other_flagged")
        }
        return .allow
    }
}

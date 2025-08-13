import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// 使用 OpenAI Moderation API 进行内容审核的服务。
struct ModerationService {
    static let shared = ModerationService()
    private init() {}

    struct Result {
        /// 被标记的不当类别列表
        let flaggedCategories: [String]
    }

    /// 调用 omni-moderation-latest 模型审核文本。
    func check(_ text: String, completion: @escaping (Result) -> Void) {
        guard let apiKey = KeychainService.shared.getAPIKey(), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(Result(flaggedCategories: []))
            return
        }
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/moderations")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": "omni-moderation-latest",
            "input": text
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard
                let data = data,
                let response = try? JSONDecoder().decode(APIResponse.self, from: data),
                let categories = response.results.first?.categories
            else {
                completion(Result(flaggedCategories: []))
                return
            }
            let flagged = categories.filter { $0.value }.map { $0.key }
            completion(Result(flaggedCategories: flagged))
        }.resume()
    }

    private struct APIResponse: Decodable {
        struct Item: Decodable {
            let categories: [String: Bool]
        }
        let results: [Item]
    }
}

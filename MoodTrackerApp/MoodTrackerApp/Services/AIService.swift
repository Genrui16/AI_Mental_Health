#if canImport(FoundationNetworking)
import Foundation
import FoundationNetworking
#else
import Foundation
#endif

/// 负责与 ChatGPT 等 AI 服务通信的服务类。
@MainActor
final class AIService {
    static let shared = AIService()
    private init() {}

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model = "gpt-3.5-turbo"

    /// 根据既往日志和可选的上下文信息生成每日个性化建议。
    /// - Parameters:
    ///   - logs: 近期的心情日志，用于为模型提供背景。
    ///   - context: 额外的上下文信息，例如健康数据摘要或执行反馈，可为空。
    ///   - completion: 异步回调，返回生成的日程项或错误。
    func getDailyScheduleSuggestions(from logs: [MoodLog], context: String? = nil, completion: @Sendable @escaping (Result<[ScheduleItem], Error>) -> Void) {
        guard let apiKey = KeychainService.shared.getAPIKey() else {
            completion(.failure(AIServiceError.apiKeyMissing))
            return
        }
        let logsText = logs.map { log in
            let formatter = ISO8601DateFormatter()
            return "\(formatter.string(from: log.time)) - \(log.mood): \(log.description)"
        }.joined(separator: "\n")
        var prompt = """
        基于以下心情日志，生成三条日程建议，以 JSON 数组返回，每个元素包含 minutes_from_now(整数, 分钟) 与 title:
        \n\(logsText)
        """
        if let context = context, !context.isEmpty {
            prompt += "\n附加信息:\n\(context)"
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AIServiceError.invalidResponse))
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                if
                    let data = data,
                    let apiError = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data)
                {
                    completion(.failure(AIServiceError.api(apiError.error.message)))
                } else {
                    completion(.failure(AIServiceError.httpStatus(httpResponse.statusCode)))
                }
                return
            }
            guard let data = data else {
                completion(.failure(AIServiceError.noData))
                return
            }
            guard
                let response = try? JSONDecoder().decode(ChatResponse.self, from: data),
                let text = response.choices.first?.message.content,
                let jsonData = text.data(using: .utf8)
            else {
                if let apiError = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                    completion(.failure(AIServiceError.api(apiError.error.message)))
                } else {
                    completion(.failure(AIServiceError.decoding))
                }
                return
            }
            struct Suggestion: Decodable {
                let minutes_from_now: Int
                let title: String
            }
            if let suggestions = try? JSONDecoder().decode([Suggestion].self, from: jsonData) {
                let now = Date()
                let items = suggestions.map { s in
                    ScheduleItem(time: now.addingTimeInterval(TimeInterval(s.minutes_from_now * 60)), title: s.title)
                }
                completion(.success(items))
            } else {
                completion(.failure(AIServiceError.decoding))
            }
        }
        task.resume()
    }

    /// 与 AI 聊天获取回复，支持传入最近的对话历史以提高连贯性。
    /// - Parameters:
    ///   - messages: 包含最近对话记录的数组，仅会取最后若干条发送给模型。
    ///   - completion: 异步回调，返回 AI 回复或错误。
    func chat(with messages: [ChatMessage], completion: @escaping (Result<String, Error>) -> Void) {
        guard let apiKey = KeychainService.shared.getAPIKey() else {
            completion(.failure(AIServiceError.apiKeyMissing))
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // 控制历史长度，避免超过 token 限制
        let recent = Array(messages.suffix(10))
        let messagePayload: [[String: String]] = recent.map { msg in
            let role = msg.role == .user ? "user" : "assistant"
            return ["role": role, "content": msg.text]
        }

        let body: [String: Any] = [
            "model": model,
            "messages": messagePayload
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AIServiceError.invalidResponse))
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                if
                    let data = data,
                    let apiError = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data)
                {
                    completion(.failure(AIServiceError.api(apiError.error.message)))
                } else {
                    completion(.failure(AIServiceError.httpStatus(httpResponse.statusCode)))
                }
                return
            }
            guard let data = data else {
                completion(.failure(AIServiceError.noData))
                return
            }
            if
                let response = try? JSONDecoder().decode(ChatResponse.self, from: data),
                let text = response.choices.first?.message.content
            {
                completion(.success(text.trimmingCharacters(in: .whitespacesAndNewlines)))
            } else if let apiError = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                completion(.failure(AIServiceError.api(apiError.error.message)))
            } else {
                completion(.failure(AIServiceError.decoding))
            }
        }
        task.resume()
    }
}

/// 服务错误类型。
enum AIServiceError: LocalizedError {
    case apiKeyMissing
    case invalidResponse
    case httpStatus(Int)
    case noData
    case decoding
    case api(String)

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing: return "未设置 API Key"
        case .invalidResponse: return "Invalid response from server"
        case .httpStatus(let code): return "Server returned status code \(code)"
        case .noData: return "No data returned"
        case .decoding: return "Failed to decode response"
        case .api(let message): return message
        }
    }
}

/// OpenAI Chat Completions 接口的响应数据模型。
private struct ChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable { let content: String }
        let message: Message
    }
    let choices: [Choice]
}

/// OpenAI 错误响应模型。
private struct OpenAIErrorResponse: Decodable {
    struct APIError: Decodable { let message: String }
    let error: APIError
}


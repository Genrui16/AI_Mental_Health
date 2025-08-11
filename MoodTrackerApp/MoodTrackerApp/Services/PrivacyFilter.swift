import Foundation

/// 工具结构体，用于在发送给 AI 之前对文本进行脱敏处理。
struct PrivacyFilter {
    /// 使用简单的正则表达式去除可能的邮箱、电话号码等敏感信息。
    static func sanitize(_ text: String) -> String {
        let pattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}|\\d{3,}"
        return text.replacingOccurrences(of: pattern, with: "***", options: [.regularExpression, .caseInsensitive])
    }
}

import Foundation

/// 负责持久化保存用户长期摘要信息的简单存储。
@MainActor
final class UserSummaryStore {
    static let shared = UserSummaryStore()
    private let fileURL: URL

    private init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = directory.appendingPathComponent("user_summary.txt")
    }

    /// 读取当前的用户摘要，没有则返回空字符串。
    func loadSummary() -> String {
        guard let data = try? Data(contentsOf: fileURL),
              let text = String(data: data, encoding: .utf8) else { return "" }
        return text
    }

    /// 保存新的摘要内容，会覆盖旧内容。
    func save(summary: String) {
        guard let data = summary.data(using: .utf8) else { return }
        try? data.write(to: fileURL)
    }
}

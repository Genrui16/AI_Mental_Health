import Foundation

/// 负责与 ChatGPT 等 AI 服务通信的服务类。
final class AIService {
    static let shared = AIService()

    private init() {}

    /// 根据既往日志生成每日个性化建议。这里使用占位实现，返回静态示例。
    func getDailyScheduleSuggestions(from logs: [MoodLog], completion: @escaping ([ScheduleItem]) -> Void) {
        // TODO: 在此处调用 ChatGPT API，解析返回结果并转换为 ScheduleItem 列表。
        // 下面是示例数据。
        let now = Date()
        let suggestions = [
            ScheduleItem(time: now.addingTimeInterval(600), title: "喝一杯温水并做伸展运动"),
            ScheduleItem(time: now.addingTimeInterval(3600), title: "进行 20 分钟的冥想练习"),
            ScheduleItem(time: now.addingTimeInterval(7200), title: "午休 30 分钟")
        ]
        completion(suggestions)
    }

    /// 与 AI 聊天获取回复。此处模拟返回固定文本。
    func chat(with message: String, completion: @escaping (String) -> Void) {
        // TODO: 调用 ChatGPT API，返回实际回答
        // 这里简单模拟一个回应
        let reply = "感谢你的分享！记得关注自己的感受，可以尝试一些放松练习。"
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            completion(reply)
        }
    }
}

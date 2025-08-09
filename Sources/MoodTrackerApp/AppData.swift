import Foundation

/// 全局数据存储，保存活动、心情记录和物质摄入信息。
class AppData: ObservableObject {
    /// 用户记录的活动列表。
    @Published var activities: [Activity] = []
    /// 用户记录的心情列表。
    @Published var moodLogs: [MoodLog] = []
    /// 用户记录的物质摄入列表。
    @Published var substances: [SubstanceEntry] = []
}

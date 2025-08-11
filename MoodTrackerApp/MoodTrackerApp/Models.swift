import Foundation

/// 通用的日程项目，用于展示建议或实际活动。
struct ScheduleItem: Identifiable, Codable {
    let id = UUID()
    var time: Date
    var title: String
    var notes: String = ""
}

/// 活动记录，例如运动、冥想等。
struct Activity: Identifiable, Codable {
    let id = UUID()
    var name: String
    var duration: TimeInterval
    /// 活动强度，1~3 代表低、中、高强度，可根据需要调整。
    var intensity: Int?
}

/// 心情记录，记录特定时间点的情绪及其描述，以及摄入的物质信息。
struct MoodLog: Identifiable, Codable {
    let id = UUID()
    var time: Date
    var mood: String
    var description: String
    var substances: [SubstanceEntry] = []
}

/// 摄入的物质条目，例如尼古丁、大麻、咖啡因等。
struct SubstanceEntry: Identifiable, Codable {
    let id = UUID()
    var type: SubstanceType
    var amount: Double
    var unit: String
}

/// 支持的物质类型。
enum SubstanceType: String, CaseIterable, Codable {
    case nicotine = "尼古丁"
    case cannabis = "大麻"
    case caffeine = "咖啡因"
    // 如有其他物质类型，可以在此处添加。
}

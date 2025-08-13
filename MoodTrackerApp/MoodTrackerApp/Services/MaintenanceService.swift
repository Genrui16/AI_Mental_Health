import Foundation
import CoreData

/// 简单的维护服务：清理过旧的数据，避免长期占用存储。
enum MaintenanceService {
    /// 清理策略：
    /// - 聊天会话：保留最近 90 天
    /// - 日程事件：保留最近 30 天
    static func run(context: NSManagedObjectContext) async {
        await purgeChatSessions(olderThan: 90)
        purgeEvents(context: context, days: 30)
    }

    static func purgeChatSessions(olderThan days: Int) async {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
        var sessions = await MainActor.run { ChatStore.shared.loadSessions() }
        let before = sessions.count
        sessions = sessions.filter { $0.date >= cutoff }
        if sessions.count != before {
            // 覆盖写回（在主线程上访问 ChatStore）
            await MainActor.run {
                for s in sessions {
                    ChatStore.shared.saveSession(s)
                }
            }
        }
    }

    static func purgeEvents(context: NSManagedObjectContext, days: Int) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
        let fetchA: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "ActualEvent")
        fetchA.predicate = NSPredicate(format: "time < %@", cutoff as NSDate)
        let fetchS: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "SuggestedEvent")
        fetchS.predicate = NSPredicate(format: "time < %@", cutoff as NSDate)

        let batchDeleteA = NSBatchDeleteRequest(fetchRequest: fetchA)
        let batchDeleteS = NSBatchDeleteRequest(fetchRequest: fetchS)
        _ = try? context.execute(batchDeleteA)
        _ = try? context.execute(batchDeleteS)
        try? context.save()
    }
}

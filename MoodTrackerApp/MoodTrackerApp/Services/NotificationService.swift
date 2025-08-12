import Foundation
import UserNotifications

/// 统一管理本地通知的服务。
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let center = UNUserNotificationCenter.current()
    private let diaryIdentifier = "dailyDiaryReminder"

    /// 请求通知权限，如已拒绝则回调 false。
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    completion?(granted)
                }
            case .denied:
                completion?(false)
            default:
                completion?(true)
            }
        }
    }

    /// 为建议事件安排通知，默认提前5分钟提醒。
    func scheduleEventNotifications(for events: [SuggestedEvent], minutesBefore: Int = 5) {
        let now = Date()
        for event in events {
            var triggerDate = event.time.addingTimeInterval(TimeInterval(-minutesBefore * 60))
            if triggerDate < now { triggerDate = event.time }
            guard triggerDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = event.title
            if let notes = event.notes { content.body = notes }
            content.userInfo = ["id": event.id.uuidString]

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: event.id.uuidString, content: content, trigger: trigger)
            center.add(request)
        }
    }

    /// 移除指定标识符的通知。
    func cancelNotifications(ids: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// 安排每日的日记提醒。
    func scheduleDiaryReminder(at date: Date) {
        cancelDiaryReminder()
        var components = Calendar.current.dateComponents([.hour, .minute], from: date)
        components.second = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "记录一下今天的心情和想法吧"
        let request = UNNotificationRequest(identifier: diaryIdentifier, content: content, trigger: trigger)
        center.add(request)
    }

    /// 取消每日的日记提醒。
    func cancelDiaryReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [diaryIdentifier])
    }
}

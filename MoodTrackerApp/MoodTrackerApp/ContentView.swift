//
//  ContentView.swift
//  MoodTrackerApp
//
//  Created by 刘根瑞 on 8/10/25.
//

import SwiftUI

#if os(iOS)
import UserNotifications
#endif

/// 主视图，包含底部标签栏用于在不同模块间切换。
/// 该视图整合了时间轴、心理日记和个人中心等功能模块。
struct ContentView: View {
    @AppStorage("diaryNotificationsEnabled") private var diaryNotificationsEnabled: Bool = true
    @AppStorage("diaryReminderHour") private var diaryReminderHour: Int = 21
    @AppStorage("diaryReminderMinute") private var diaryReminderMinute: Int = 0

    private var diaryReminderDate: Date {
        var comps = DateComponents()
        comps.hour = diaryReminderHour
        comps.minute = diaryReminderMinute
        return Calendar.current.date(from: comps) ?? Date()
    }

    var body: some View {
        TabView {
            TimelineView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("时间轴")
                }

            DiaryView()
                .tabItem {
                    Image(systemName: "book")
                    Text("日记")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("我的")
                }
        }
        .onAppear {
            if diaryNotificationsEnabled {
                NotificationService.shared.requestAuthorization { granted in
                    if granted {
                        NotificationService.shared.scheduleDiaryReminder(at: diaryReminderDate)
                    }
                }
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif

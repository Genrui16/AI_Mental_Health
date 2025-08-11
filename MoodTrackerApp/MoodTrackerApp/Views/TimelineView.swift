#if os(iOS)
import SwiftUI
import CoreData
import UserNotifications

/// 时间轴视图，左侧展示 AI 建议的日程，右侧记录用户的实际活动。
struct TimelineView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ActualEvent.time, ascending: true)],
        animation: .default)
    private var actualEvents: FetchedResults<ActualEvent>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SuggestedEvent.time, ascending: true)],
        animation: .default)
    private var suggestedEvents: FetchedResults<SuggestedEvent>

    @State private var editingEvent: ActualEvent?
    @State private var showingEditor = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingAPIKeyPrompt = false
    @State private var apiKeyInput: String = ""
    @State private var isLoading = false
    @AppStorage("scheduleNotificationsEnabled") private var notificationsEnabled: Bool = true

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                    LazyVStack(alignment: .leading) {
                        // 显示建议日程和实际日程，两列对齐
                        ForEach(0..<max(suggestedEvents.count, actualEvents.count), id: \.self) { index in
                            HStack(alignment: .top, spacing: 16) {
                                // 建议日程列
                                VStack(alignment: .leading) {
                                    if index < suggestedEvents.count {
                                        let item = suggestedEvents[index]
                                        ScheduleRow(
                                            item: ScheduleItem(time: item.time, title: item.title, notes: item.notes ?? ""),
                                            isSuggested: true,
                                            isCompleted: item.isCompleted,
                                            onToggleCompleted: { toggleCompletion(item) }
                                        )
                                    } else {
                                        Spacer().frame(height: 0)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                // 实际活动列
                                VStack(alignment: .leading) {
                                    if index < actualEvents.count {
                                        let event = actualEvents[index]
                                        ScheduleRow(item: ScheduleItem(time: event.time, title: event.title, notes: event.notes ?? ""), isSuggested: false)
                                            .contextMenu {
                                                Button("编辑") {
                                                    editingEvent = event
                                                    showingEditor = true
                                                }
                                                Button(role: .destructive) {
                                                    delete(event)
                                                } label: {
                                                    Text("删除")
                                                }
                                            }
                                            .onTapGesture {
                                                editingEvent = event
                                                showingEditor = true
                                            }
                                    } else {
                                        // 为了视觉对齐，当没有记录时可以留空
                                        Spacer().frame(height: 0)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                }
                if isLoading {
                    ProgressView().scaleEffect(1.2)
                }
            }
            .navigationTitle("时间轴")
            .toolbar {
                ToolbarItemGroup(placement: toolbarPlacement) {
                    Button(action: generateSuggestions) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("刷新建议日程")
                    .disabled(isLoading)

                    Button(action: { editingEvent = nil; showingEditor = true }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("新增实际活动")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            EventEditView(event: editingEvent)
        }
        .alert("设置 API Key", isPresented: $showingAPIKeyPrompt) {
            TextField("API Key", text: $apiKeyInput)
            Button("保存") {
                KeychainService.shared.saveAPIKey(apiKeyInput)
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("使用此功能需要设置 OpenAI API Key")
        }
        .alert("获取建议失败", isPresented: $showingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "未知错误")
        }
        .onAppear {
            // 如果没有任何示例数据，初始化几条实际活动记录。
            if actualEvents.isEmpty {
                let sampleTitles = ["早餐和服药", "早间散步", "工作/学习"]
                for (idx, title) in sampleTitles.enumerated() {
                    let newItem = ActualEvent(context: viewContext)
                    newItem.id = UUID()
                    newItem.time = Date().addingTimeInterval(Double(idx) * 1800)
                    newItem.title = title
                }
                try? viewContext.save()
            }
        }
    }

    /// 刷新建议日程，调用 AIService 获取个性化建议。
    private func generateSuggestions() {
        guard KeychainService.shared.getAPIKey() != nil else {
            showingAPIKeyPrompt = true
            return
        }
        isLoading = true
        requestNotificationPermissionIfNeeded()
        let logs = MoodLogStore.shared.recentLogs(days: 7)
        var contextPieces: [String] = []
        let exec = executionSummary()
        if !exec.isEmpty { contextPieces.append(exec) }
        let userSummary = UserSummaryStore.shared.loadSummary()
        if !userSummary.isEmpty { contextPieces.append("用户摘要: \(userSummary)") }

        if #available(iOS 15.0, *) {
            let group = DispatchGroup()
            var steps: Double = 0
            var sleep: Double = 0
            var heart: Double = 0
            group.enter()
            HealthService.shared.fetchStepCount { count in
                steps = count
                group.leave()
            }
            group.enter()
            HealthService.shared.fetchSleepAnalysis { hours in
                sleep = hours
                group.leave()
            }
            group.enter()
            HealthService.shared.fetchHeartRate { rate in
                heart = rate
                group.leave()
            }
            group.notify(queue: .main) {
                if steps > 0 { contextPieces.append("步数: \(Int(steps))") }
                if sleep > 0 { contextPieces.append(String(format: "睡眠: %.1f小时", sleep)) }
                if heart > 0 { contextPieces.append(String(format: "心率: %.0f", heart)) }
                requestSuggestions(logs: logs, context: contextPieces.joined(separator: "\n"))
            }
        } else {
            requestSuggestions(logs: logs, context: contextPieces.joined(separator: "\n"))
        }
    }

    /// 调用 AIService 并处理返回结果。
    private func requestSuggestions(logs: [MoodLog], context: String) {
        AIService.shared.getDailyScheduleSuggestions(from: logs, context: context) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let items):
                    let center = UNUserNotificationCenter.current()
                    let oldIds = suggestedEvents.map { $0.id.uuidString }
                    center.removePendingNotificationRequests(withIdentifiers: oldIds)
                    for item in suggestedEvents {
                        viewContext.delete(item)
                    }
                    for suggestion in items {
                        let newItem = SuggestedEvent(context: viewContext)
                        newItem.id = UUID()
                        newItem.time = suggestion.time
                        newItem.title = suggestion.title
                        newItem.notes = suggestion.notes
                        newItem.isCompleted = false
                    }
                    try? viewContext.save()
                    if notificationsEnabled {
                        scheduleNotifications(for: Array(suggestedEvents))
                    }
                case .failure(let error):
                    errorMessage = "获取建议失败，请稍后重试。\n" + error.localizedDescription
                    showingError = true
                }
            }
        }
    }

    /// 生成昨日执行情况的简要总结。
    private func executionSummary() -> String {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return "" }
        let start = calendar.startOfDay(for: yesterday)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return "" }
        let sugg = suggestedEvents.filter { $0.time >= start && $0.time < end }
        let actual = actualEvents.filter { $0.time >= start && $0.time < end }
        guard !sugg.isEmpty else { return "" }
        var missed: [String] = []
        for s in sugg {
            if !actual.contains(where: { $0.title == s.title }) {
                missed.append(s.title)
            }
        }
        let completed = sugg.count - missed.count
        var summary = "昨日建议\(sugg.count)项, 完成\(completed)项"
        if !missed.isEmpty {
            summary += "，未完成: " + missed.joined(separator: ",")
        }
        return summary
    }

    private func delete(_ event: ActualEvent) {
        viewContext.delete(event)
        try? viewContext.save()
    }

    private func toggleCompletion(_ event: SuggestedEvent) {
        event.isCompleted.toggle()
        try? viewContext.save()
        let key = completionCountKey(for: Date())
        var count = UserDefaults.standard.integer(forKey: key)
        if event.isCompleted {
            count += 1
        } else {
            count = max(0, count - 1)
        }
        UserDefaults.standard.set(count, forKey: key)
    }

    /// 请求通知权限，如果未授权则提示用户。
    private func requestNotificationPermissionIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    if !granted {
                        errorMessage = "通知权限被拒绝，提醒功能将不可用"
                        showingError = true
                    }
                }
            case .denied:
                errorMessage = "未开启通知权限，提醒功能将不可用"
                showingError = true
            default:
                break
            }
        }
    }

    /// 根据当前平台选择合适的工具栏位置。
    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarTrailing
        #else
        return .automatic
        #endif
    }

    /// 为建议事件安排本地通知。
    private func scheduleNotifications(for events: [SuggestedEvent]) {
        let center = UNUserNotificationCenter.current()
        for event in events {
            let content = UNMutableNotificationContent()
            content.title = event.title
            if let notes = event.notes { content.body = notes }
            content.userInfo = ["id": event.id.uuidString]
            var triggerDate = event.time.addingTimeInterval(-300)
            if triggerDate < Date() { triggerDate = event.time }
            guard triggerDate > Date() else { continue }
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: event.id.uuidString, content: content, trigger: trigger)
            center.add(request)
        }
    }

    /// 生成用于存储完成计数的 UserDefaults key。
    private func completionCountKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "completedSuggestions-\(formatter.string(from: date))"
    }
}

// MARK: - 预览
#if DEBUG
struct TimelineView_Previews: PreviewProvider {
    static var previews: some View {
        TimelineView()
    }
}
#endif
#endif

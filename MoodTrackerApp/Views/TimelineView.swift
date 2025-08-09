import SwiftUI

/// 时间轴视图，左侧展示 AI 建议的日程，右侧记录用户的实际活动、心情和物质摄入。
struct TimelineView: View {
    @EnvironmentObject var appData: AppData
    @State private var suggestedEvents: [ScheduleItem] = []
    /// 当前展示的新增表单类型。
    @State private var activeSheet: EntryType?

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    // 显示建议日程和实际日程，两列对齐
                    ForEach(0..<max(suggestedEvents.count, actualEvents.count), id: \.self) { index in
                        HStack(alignment: .top, spacing: 16) {
                            // 建议日程列
                            VStack(alignment: .leading) {
                                if index < suggestedEvents.count {
                                    ScheduleRow(item: suggestedEvents[index], isSuggested: true)
                                } else {
                                    Spacer().frame(height: 0)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // 实际活动列
                            VStack(alignment: .leading) {
                                if index < actualEvents.count {
                                    ScheduleRow(item: actualEvents[index], isSuggested: false)
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
            .navigationTitle("时间轴")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Menu {
                            Button("新增活动") { activeSheet = .activity }
                            Button("新增心情记录") { activeSheet = .mood }
                            Button("新增物质摄入") { activeSheet = .substance }
                        } label: {
                            Image(systemName: "plus")
                        }

                        Button(action: generateSuggestions) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .accessibilityLabel("刷新建议日程")
                    }
                }
            }
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .activity:
                NewActivityView().environmentObject(appData)
            case .mood:
                NewMoodLogView().environmentObject(appData)
            case .substance:
                NewSubstanceEntryView().environmentObject(appData)
            }
        }
    }

    /// 将用户记录转换为时间轴显示的列表。
    private var actualEvents: [ScheduleItem] {
        let activities = appData.activities.map { ScheduleItem(time: $0.time, title: $0.name) }
        let moods = appData.moodLogs.map { ScheduleItem(time: $0.time, title: "心情: \($0.mood)") }
        let substances = appData.substances.map { ScheduleItem(time: $0.time, title: "摄入: \($0.type.rawValue)") }
        return (activities + moods + substances).sorted { $0.time < $1.time }
    }

    /// 刷新建议日程，可在此集成 ChatGPT API 获取个性化建议。
    private func generateSuggestions() {
        // 目前使用静态示例，后续可调用 AIService.shared.getDailyScheduleSuggestions()
        let now = Date()
        suggestedEvents = [
            ScheduleItem(time: now.addingTimeInterval(300), title: "起床后做 10 分钟冥想"),
            ScheduleItem(time: now.addingTimeInterval(1800), title: "进行 30 分钟有氧运动"),
            ScheduleItem(time: now.addingTimeInterval(5400), title: "安排阅读和反思时间")
        ]
    }
}

/// 新增表单类型。
private enum EntryType: Identifiable {
    case activity, mood, substance
    var id: Int { hashValue }
}

// MARK: - 预览
#if DEBUG
struct TimelineView_Previews: PreviewProvider {
    static var previews: some View {
        TimelineView().environmentObject(AppData())
    }
}
#endif

import SwiftUI

/// 时间轴视图，左侧展示 AI 建议的日程，右侧记录用户的实际活动。
struct TimelineView: View {
    @State private var suggestedEvents: [ScheduleItem] = []
    @State private var actualEvents: [ScheduleItem] = []

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
                    Button(action: generateSuggestions) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("刷新建议日程")
                }
            }
        }
        .onAppear {
            // 初始加载示例数据，可以在后续集成时从数据库加载。
            actualEvents = [
                ScheduleItem(time: Date(), title: "早餐和服药"),
                ScheduleItem(time: Date().addingTimeInterval(1800), title: "早间散步"),
                ScheduleItem(time: Date().addingTimeInterval(3600 * 2), title: "工作/学习")
            ]
        }
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

// MARK: - 预览
#if DEBUG
struct TimelineView_Previews: PreviewProvider {
    static var previews: some View {
        TimelineView()
    }
}
#endif

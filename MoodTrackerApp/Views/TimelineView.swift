#if os(iOS)
import SwiftUI
import CoreData

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
                                    let item = suggestedEvents[index]
                                    ScheduleRow(item: ScheduleItem(time: item.time, title: item.title, notes: item.notes ?? ""), isSuggested: true)
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
            .navigationTitle("时间轴")
            .toolbar {
                ToolbarItemGroup(placement: toolbarPlacement) {
                    Button(action: generateSuggestions) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("刷新建议日程")

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

    /// 刷新建议日程，可在此集成 ChatGPT API 获取个性化建议。
    private func generateSuggestions() {
        // 清空旧建议
        for item in suggestedEvents {
            viewContext.delete(item)
        }

        // 目前使用静态示例，后续可调用 AIService.shared.getDailyScheduleSuggestions()
        let now = Date()
        let suggestions = [
            (now.addingTimeInterval(300), "起床后做 10 分钟冥想"),
            (now.addingTimeInterval(1800), "进行 30 分钟有氧运动"),
            (now.addingTimeInterval(5400), "安排阅读和反思时间")
        ]

        for (time, title) in suggestions {
            let newItem = SuggestedEvent(context: viewContext)
            newItem.id = UUID()
            newItem.time = time
            newItem.title = title
        }
        try? viewContext.save()
    }

    private func delete(_ event: ActualEvent) {
        viewContext.delete(event)
        try? viewContext.save()
    }

    /// 根据当前平台选择合适的工具栏位置。
    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarTrailing
        #else
        return .automatic
        #endif
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

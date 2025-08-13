#if os(iOS)
import SwiftUI
import CoreData

/// 用于新增或编辑实际活动的表单视图。
struct EventEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var time: Date
    @State private var title: String
    @State private var notes: String

    var event: ActualEvent?

    init(event: ActualEvent? = nil) {
        self.event = event
        _time = State(initialValue: event?.time ?? Date())
        _title = State(initialValue: event?.title ?? "")
        _notes = State(initialValue: event?.notes ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                DatePicker("时间", selection: $time)
                TextField("标题", text: $title)
                TextField("备注", text: $notes)
            }
            .navigationTitle(event == nil ? "新增活动" : "编辑活动")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let event = event {
                            event.time = time
                            event.title = title
                            event.notes = notes
                            event.updatedAt = Date()
                        } else {
                            let newItem = ActualEvent(context: viewContext)
                            newItem.id = UUID()
                            newItem.time = time
                            newItem.title = title
                            newItem.notes = notes
                            newItem.updatedAt = Date()
                        }
                        try? viewContext.save()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}
#endif

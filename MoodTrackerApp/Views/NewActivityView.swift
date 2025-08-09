import SwiftUI

/// 新增活动的表单视图。
struct NewActivityView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var time: Date = Date()
    @State private var duration: Double = 0
    @State private var intensity: Int = 1

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("活动名称", text: $name)
                    DatePicker("时间", selection: $time)
                    TextField("持续时间(分钟)", value: $duration, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                    Picker("强度(1~3)", selection: $intensity) {
                        ForEach(1...3, id: \.self) { i in
                            Text("\(i)").tag(i)
                        }
                    }
                }
            }
            .navigationTitle("新增活动")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .disabled(!isValid)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    /// 表单是否有效。
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && duration > 0 && (1...3).contains(intensity)
    }

    /// 保存活动并关闭表单。
    private func save() {
        let activity = Activity(time: time, name: name, duration: duration * 60, intensity: intensity)
        appData.activities.append(activity)
        dismiss()
    }
}

#if DEBUG
struct NewActivityView_Previews: PreviewProvider {
    static var previews: some View {
        NewActivityView().environmentObject(AppData())
    }
}
#endif

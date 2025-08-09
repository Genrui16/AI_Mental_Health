import SwiftUI

/// 新增心情记录表单。
struct NewMoodLogView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) private var dismiss

    @State private var time: Date = Date()
    @State private var mood: String = ""
    @State private var description: String = ""

    // 可选的物质摄入
    @State private var includeSubstance = false
    @State private var substanceType: SubstanceType = .nicotine
    @State private var amount: Double = 0
    @State private var unit: String = "mg"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("心情")) {
                    DatePicker("时间", selection: $time)
                    TextField("心情", text: $mood)
                    TextField("描述", text: $description)
                }

                Section(header: Toggle("记录物质摄入", isOn: $includeSubstance)) {
                    if includeSubstance {
                        Picker("类型", selection: $substanceType) {
                            ForEach(SubstanceType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        TextField("数量", value: $amount, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                        TextField("单位", text: $unit)
                    }
                }
            }
            .navigationTitle("新增心情记录")
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
        let moodValid = !mood.trimmingCharacters(in: .whitespaces).isEmpty
        let substanceValid = !includeSubstance || (amount > 0 && !unit.trimmingCharacters(in: .whitespaces).isEmpty)
        return moodValid && substanceValid
    }

    /// 保存心情记录并关闭表单。
    private func save() {
        var substances: [SubstanceEntry] = []
        if includeSubstance {
            let entry = SubstanceEntry(time: time, type: substanceType, amount: amount, unit: unit)
            appData.substances.append(entry)
            substances.append(entry)
        }
        let log = MoodLog(time: time, mood: mood, description: description, substances: substances)
        appData.moodLogs.append(log)
        dismiss()
    }
}

#if DEBUG
struct NewMoodLogView_Previews: PreviewProvider {
    static var previews: some View {
        NewMoodLogView().environmentObject(AppData())
    }
}
#endif

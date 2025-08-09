import SwiftUI

/// 新增物质摄入记录表单。
struct NewSubstanceEntryView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) private var dismiss

    @State private var time: Date = Date()
    @State private var type: SubstanceType = .nicotine
    @State private var amount: Double = 0
    @State private var unit: String = "mg"

    var body: some View {
        NavigationView {
            Form {
                DatePicker("时间", selection: $time)
                Picker("类型", selection: $type) {
                    ForEach(SubstanceType.allCases, id: \.self) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                TextField("数量", value: $amount, formatter: NumberFormatter())
                    .keyboardType(.decimalPad)
                TextField("单位", text: $unit)
            }
            .navigationTitle("新增物质摄入")
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

    private var isValid: Bool {
        amount > 0 && !unit.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func save() {
        let entry = SubstanceEntry(time: time, type: type, amount: amount, unit: unit)
        appData.substances.append(entry)
        dismiss()
    }
}

#if DEBUG
struct NewSubstanceEntryView_Previews: PreviewProvider {
    static var previews: some View {
        NewSubstanceEntryView().environmentObject(AppData())
    }
}
#endif

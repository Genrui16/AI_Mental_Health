// Only compile this view on iOS since it relies on UIKit and UserNotifications.
#if os(iOS)
import SwiftUI
import UserNotifications
import UIKit

/// 设置页，允许用户配置 API Key、通知和数据选项等偏好。
struct SettingsView: View {
    @State private var apiKeyInput: String = ""
    @State private var storedKey: String? = KeychainService.shared.getAPIKey()
    @AppStorage("scheduleNotificationsEnabled") private var scheduleNotificationsEnabled: Bool = true
    @AppStorage("eventNotifyMinutesBefore") private var eventNotifyMinutesBefore: Int = 5
    @AppStorage("diaryNotificationsEnabled") private var diaryNotificationsEnabled: Bool = true
    @AppStorage("diaryReminderHour") private var diaryReminderHour: Int = 21
    @AppStorage("diaryReminderMinute") private var diaryReminderMinute: Int = 0
    @AppStorage("preferredFontSize") private var preferredFontSize: Double = 16
    @AppStorage("preferredTint") private var preferredTint: Int = 0

    @State private var showingAlert = false
    @State private var alertMessage = ""

    private var diaryReminderDate: Date {
        var comps = DateComponents()
        comps.hour = diaryReminderHour
        comps.minute = diaryReminderMinute
        return Calendar.current.date(from: comps) ?? Date()
    }

    var body: some View {
        Form {
            Section(header: Text("OpenAI")) {
                if let storedKey = storedKey, !storedKey.isEmpty {
                    HStack {
                        Text("当前 Key")
                        Spacer()
                        Text(mask(storedKey))
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                    Button("删除 Key") {
                        KeychainService.shared.deleteAPIKey()
                        self.storedKey = nil
                    }
                    .foregroundColor(.red)
                } else {
                    SecureField("输入 OpenAI API Key", text: $apiKeyInput)
                    Button("保存") {
                        guard !apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            alertMessage = "请输入有效的 API Key"
                            showingAlert = true
                            return
                        }
                        KeychainService.shared.saveAPIKey(apiKeyInput)
                        self.storedKey = apiKeyInput
                        self.apiKeyInput = ""
                    }
                }
            }

            Section(header: Text("日程通知")) {
                Toggle("为 AI 建议安排提醒", isOn: $scheduleNotificationsEnabled)
                Stepper(value: $eventNotifyMinutesBefore, in: 0...60) {
                    Text("提前提醒：\(eventNotifyMinutesBefore) 分钟")
                }
                .disabled(!scheduleNotificationsEnabled)
                Text("完成一次刷新后，将为当天未过期的建议安排本地通知。").font(.footnote).foregroundColor(.secondary)
            }

            Section(header: Text("日记提醒")) {
                Toggle("开启每日提醒", isOn: $diaryNotificationsEnabled)
                    .onChange(of: diaryNotificationsEnabled) { _, enabled in
                        if enabled {
                            NotificationService.shared.requestAuthorization { granted in
                                if granted {
                                    NotificationService.shared.scheduleDiaryReminder(at: diaryReminderDate)
                                } else {
                                    alertMessage = "未开启通知权限，请到系统设置授予。"
                                    showingAlert = true
                                }
                            }
                        } else {
                            NotificationService.shared.cancelDiaryReminder()
                        }
                    }
                DatePicker("提醒时间", selection: .constant(diaryReminderDate), displayedComponents: .hourAndMinute)
                    .onChange(of: diaryReminderHour) { _, _ in rescheduleDiary() }
                    .onChange(of: diaryReminderMinute) { _, _ in rescheduleDiary() }
                    .environment(\.locale, Locale(identifier: "zh_CN"))
            }

            Section(header: Text("健康数据")) {
                Button("授予/重新授权 HealthKit") {
                    if #available(iOS 15.0, *) {
                        HealthService.shared.requestAuthorization { _ in }
                    }
                }
                .disabled(!isHealthAvailable)
                if !isHealthAvailable {
                    Text("此设备不支持 HealthKit。").font(.footnote).foregroundColor(.secondary)
                }
            }

            Section(header: Text("个性化")) {
                Picker("主题色", selection: $preferredTint) {
                    Text("系统默认").tag(0)
                    Text("蓝色").tag(1)
                    Text("绿色").tag(2)
                }
                Stepper(value: $preferredFontSize, in: 12...24) {
                    Text("字体大小：\(Int(preferredFontSize))")
                }
            }

            Section {
                Link("前往系统通知设置", destination: URL(string: UIApplication.openSettingsURLString)!)
            }
        }
        .navigationTitle("设置")
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            // 如果启用了日记提醒，确保安排一次
            if diaryNotificationsEnabled {
                NotificationService.shared.scheduleDiaryReminder(at: diaryReminderDate)
            }
        }
    }

    private var isHealthAvailable: Bool {
        if #available(iOS 15.0, *) {
            return HealthService.shared.isHealthDataAvailable
        }
        return false
    }

    /// 简单的掩码显示，避免完整暴露 API Key。
    private func mask(_ key: String) -> String {
        let prefix = key.prefix(3)
        let suffix = key.suffix(3)
        return "\(prefix)***\(suffix)"
    }

    private func rescheduleDiary() {
        guard diaryNotificationsEnabled else { return }
        NotificationService.shared.scheduleDiaryReminder(at: diaryReminderDate)
    }
}
#endif

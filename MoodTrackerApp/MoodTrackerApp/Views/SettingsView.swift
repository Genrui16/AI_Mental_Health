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
    @AppStorage("diaryNotificationsEnabled") private var diaryNotificationsEnabled: Bool = true
    @AppStorage("diaryReminderHour") private var diaryReminderHour: Int = 21
    @AppStorage("diaryReminderMinute") private var diaryReminderMinute: Int = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        Form {
            apiKeySection
            notificationSection
            privacySection
            Section {
                NavigationLink(destination: AboutView()) {
                    Text("关于")
                }
            }
        }
        .navigationTitle("设置")
        .alert("未开启通知权限", isPresented: $showingAlert) {
            Button("取消", role: .cancel) {}
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    /// API Key 管理
    private var apiKeySection: some View {
        Section(header: Text("OpenAI API Key")) {
            if let storedKey = storedKey, !storedKey.isEmpty {
                Text("当前 Key: \(mask(storedKey))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("尚未设置 API Key")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            SecureField("输入新的 API Key", text: $apiKeyInput)
            Button("保存") {
                KeychainService.shared.saveAPIKey(apiKeyInput)
                storedKey = apiKeyInput
                apiKeyInput = ""
            }
        }
    }

    /// 通知设置
    private var notificationSection: some View {
        Section(header: Text("通知")) {
            Toggle("日程提醒", isOn: $scheduleNotificationsEnabled)
                .onChange(of: scheduleNotificationsEnabled) { _, newValue in
                    if newValue {
                        NotificationService.shared.requestAuthorization { granted in
                            if !granted {
                                DispatchQueue.main.async {
                                    scheduleNotificationsEnabled = false
                                    alertMessage = "请在系统设置中开启通知权限以使用日程提醒"
                                    showingAlert = true
                                }
                            }
                        }
                    }
                }

            Toggle("日记提醒", isOn: $diaryNotificationsEnabled)
                .onChange(of: diaryNotificationsEnabled) { _, enabled in
                    if enabled {
                        NotificationService.shared.requestAuthorization { granted in
                            if granted {
                                let date = diaryReminderDate
                                NotificationService.shared.scheduleDiaryReminder(at: date)
                            } else {
                                DispatchQueue.main.async {
                                    diaryNotificationsEnabled = false
                                    alertMessage = "请在系统设置中开启通知权限以使用日记提醒"
                                    showingAlert = true
                                }
                            }
                        }
                    } else {
                        NotificationService.shared.cancelDiaryReminder()
                    }
                }

            if diaryNotificationsEnabled {
                DatePicker("提醒时间", selection: diaryReminderBinding, displayedComponents: .hourAndMinute)
            }
        }
    }

    /// 计算并绑定日记提醒时间
    private var diaryReminderDate: Date {
        get {
            var comps = DateComponents()
            comps.hour = diaryReminderHour
            comps.minute = diaryReminderMinute
            return Calendar.current.date(from: comps) ?? Date()
        }
        set {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            diaryReminderHour = comps.hour ?? 21
            diaryReminderMinute = comps.minute ?? 0
            NotificationService.shared.cancelDiaryReminder()
            if diaryNotificationsEnabled {
                NotificationService.shared.scheduleDiaryReminder(at: newValue)
            }
        }
    }

    private var diaryReminderBinding: Binding<Date> {
        Binding(
            get: { diaryReminderDate },
            set: { newValue in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                diaryReminderHour = comps.hour ?? 21
                diaryReminderMinute = comps.minute ?? 0
                NotificationService.shared.cancelDiaryReminder()
                if diaryNotificationsEnabled {
                    NotificationService.shared.scheduleDiaryReminder(at: newValue)
                }
            }
        )
    }

    /// 隐私与数据
    private var privacySection: some View {
        Section(header: Text("隐私与数据")) {
            Button("导出日记记录（敬请期待）") {}
                .disabled(true)
            Button("重置应用（敬请期待）", role: .destructive) {}
                .disabled(true)
        }
    }

    /// 简单的掩码显示，避免完整暴露 API Key。
    private func mask(_ key: String) -> String {
        let prefix = key.prefix(3)
        let suffix = key.suffix(3)
        return "\(prefix)***\(suffix)"
    }
}
#endif

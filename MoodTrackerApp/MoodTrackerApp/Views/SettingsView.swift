import SwiftUI

#if os(iOS)
/// 设置页，允许用户配置 API Key、通知和数据选项等偏好。
struct SettingsView: View {
    @State private var apiKeyInput: String = ""
    @State private var storedKey: String? = KeychainService.shared.getAPIKey()
    @AppStorage("scheduleNotificationsEnabled") private var scheduleNotificationsEnabled: Bool = true
    @AppStorage("diaryNotificationsEnabled") private var diaryNotificationsEnabled: Bool = true

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
            Toggle("日记提醒", isOn: $diaryNotificationsEnabled)
        }
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

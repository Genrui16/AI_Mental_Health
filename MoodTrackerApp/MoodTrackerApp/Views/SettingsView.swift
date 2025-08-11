import SwiftUI

#if os(iOS)
/// 设置页，允许用户配置 API Key 等偏好。
struct SettingsView: View {
    @State private var apiKey: String = KeychainService.shared.getAPIKey() ?? ""
    @AppStorage("scheduleNotificationsEnabled") private var notificationsEnabled: Bool = true

    var body: some View {
        Form {
            Section(header: Text("OpenAI API Key")) {
                SecureField("API Key", text: $apiKey)
                Button("保存") {
                    KeychainService.shared.saveAPIKey(apiKey)
                }
            }

            Section(header: Text("日程提醒")) {
                Toggle("重要计划提醒", isOn: $notificationsEnabled)
            }
        }
        .navigationTitle("设置")
    }
}
#endif

import SwiftUI

#if os(iOS)
/// 设置页，允许用户配置 API Key 等偏好。
struct SettingsView: View {
    @State private var apiKey: String = KeychainService.shared.getAPIKey() ?? ""

    var body: some View {
        Form {
            Section(header: Text("OpenAI API Key")) {
                SecureField("API Key", text: $apiKey)
                Button("保存") {
                    KeychainService.shared.saveAPIKey(apiKey)
                }
            }
        }
        .navigationTitle("设置")
    }
}
#endif

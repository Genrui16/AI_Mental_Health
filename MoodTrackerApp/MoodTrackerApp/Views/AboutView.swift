import SwiftUI

#if os(iOS)
/// 关于页面，展示应用基本信息。
struct AboutView: View {
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
                HStack {
                    Text("开发者")
                    Spacer()
                    Text("AI Mental Health Team")
                }
            }
            Section(header: Text("隐私政策")) {
                Text("应用所有数据仅存储在本地设备，不会上传至服务器。")
                    .font(.footnote)
            }
        }
        .navigationTitle("关于")
    }
}
#endif

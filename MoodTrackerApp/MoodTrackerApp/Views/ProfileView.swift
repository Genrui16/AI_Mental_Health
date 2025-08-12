#if os(iOS)
import SwiftUI

/// “我的”页面，提供健康数据同步、心情趋势、设置等入口。
struct ProfileView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: DiaryHistoryView()) {
                        Label("日记记录", systemImage: "book")
                    }
                    NavigationLink(destination: MoodTrendView(moodLogs: MoodLogStore.shared.loadLogs())) {
                        Label("心情趋势", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    NavigationLink(destination: HealthDataView()) {
                        Label("健康数据同步", systemImage: "heart.fill")
                    }
                }
                Section(header: Text("个性化")) {
                    NavigationLink(destination: SettingsView()) {
                        Label("设置", systemImage: "gearshape")
                    }
                }
                Section(header: Text("关于")) {
                    NavigationLink(destination: AboutView()) {
                        Label("关于本应用", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("我的")
        }
    }
}

// MARK: - 预览
#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
#endif
#endif

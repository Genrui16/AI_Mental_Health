#if os(iOS)
import SwiftUI

/// “我的”页面，提供健康数据同步、心情趋势等入口。
struct ProfileView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: HealthDataView()) {
                    Label("健康数据同步", systemImage: "heart.fill")
                }
                NavigationLink(destination: MoodTrendView()) {
                    Label("心情趋势", systemImage: "chart.line.uptrend.xyaxis")
                }
                // 可在此继续添加更多选项，例如设置、关于等
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

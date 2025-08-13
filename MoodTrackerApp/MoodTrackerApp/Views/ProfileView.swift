#if os(iOS)
import SwiftUI

/// “我的”页面，提供健康数据同步、心情趋势、设置等入口。
struct ProfileView: View {
    @State private var isAuthorized: Bool = false
    @State private var healthAvailable: Bool = {
        if #available(iOS 15.0, *) {
            return HealthService.shared.isHealthDataAvailable
        }
        return false
    }()
    @State private var stepPoints: [(Date, Double)] = []
    @State private var sleepPoints: [(Date, Double)] = []

    var body: some View {
        NavigationView {
            List {
                if #available(iOS 16.0, *), isAuthorized {
                    Section {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            NavigationLink(destination: HealthDataView()) {
                                MiniTrendCard(title: "近7日步数", points: stepPoints, unit: "步")
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: HealthDataView()) {
                                MiniTrendCard(title: "近7日睡眠", points: sleepPoints, unit: "分钟")
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }

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
        .task {
            guard healthAvailable else { return }
            HealthService.shared.requestAuthorization { success, _ in
                self.isAuthorized = success
                if success {
                    Task { await loadTrendData() }
                }
            }
        }
    }

    @available(iOS 15.0, *)
    private func loadTrendData() async {
        if let steps = try? await HealthService.shared.fetchDailySteps7D() {
            self.stepPoints = steps.map { ($0.0, Double($0.1)) }
        }
        if let sleeps = try? await HealthService.shared.fetchSleepMinutes7D() {
            self.sleepPoints = sleeps.map { ($0.0, Double($0.1)) }
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

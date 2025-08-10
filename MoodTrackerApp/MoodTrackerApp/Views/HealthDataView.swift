#if os(iOS)
import SwiftUI

/// 健康数据同步视图，用户可在此授权并查看从 Apple Health 获取的数据。
struct HealthDataView: View {
    @State private var isAuthorized: Bool = false
    @State private var stepCount: Double = 0
    @State private var sleepHours: Double = 0
    @State private var averageHeartRate: Double = 0
    @State private var errorMessage: String?
    @State private var showError: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isAuthorized {
                Text("今日步数：\(Int(stepCount)) 步")
                    .font(.headline)
                // 使用 specifier 避免复杂的字符串插值导致的编译错误
                Text("睡眠时长：\(sleepHours, specifier: "%.1f") 小时")
                Text("平均心率：\(Int(averageHeartRate)) 次/分")
                Button("重新同步数据") {
                    fetchData()
                }
            } else {
                Text("应用需要访问您的健康数据以提供更准确的建议。")
                Button("请求授权") {
                    requestAuthorization()
                }
            }
            Spacer()
        }
        .padding()
        .navigationTitle("健康数据")
        .onAppear {
            // 尝试在进入页面时请求授权并获取数据
            requestAuthorization()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("错误"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("确定")))
        }
    }

    /// 请求健康数据访问权限
    private func requestAuthorization() {
        HealthService.shared.requestAuthorization { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success {
                    self.fetchData()
                } else {
                    self.errorMessage = error?.localizedDescription ?? "授权失败或被拒绝"
                    self.showError = true
                }
            }
        }
    }

    /// 获取步数等数据
    private func fetchData() {
        HealthService.shared.fetchStepCount { count in
            DispatchQueue.main.async {
                self.stepCount = count
            }
        }
        HealthService.shared.fetchSleepAnalysis { hours in
            DispatchQueue.main.async {
                self.sleepHours = hours
            }
        }
        HealthService.shared.fetchHeartRate { rate in
            DispatchQueue.main.async {
                self.averageHeartRate = rate
            }
        }
    }
}

// MARK: - 预览
#if DEBUG
struct HealthDataView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HealthDataView()
        }
    }
}
#endif
#endif

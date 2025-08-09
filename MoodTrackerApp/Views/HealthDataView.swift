import SwiftUI

/// 健康数据同步视图，用户可在此授权并查看从 Apple Health 获取的数据。
struct HealthDataView: View {
    @State private var isAuthorized: Bool = false
    @State private var stepCount: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isAuthorized {
                Text("今日步数：\(Int(stepCount)) 步")
                    .font(.headline)
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
    }

    /// 请求健康数据访问权限
    private func requestAuthorization() {
        HealthService.shared.requestAuthorization { success in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success {
                    self.fetchData()
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

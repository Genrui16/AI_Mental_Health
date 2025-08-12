#if os(iOS)
import SwiftUI

/// 健康数据同步视图，用户可在此授权并查看从 Apple Health 获取的数据。
struct HealthDataView: View {
    @State private var isAuthorized: Bool = false
    @State private var healthAvailable: Bool = {
        if #available(iOS 15.0, *) {
            return HealthService.shared.isHealthDataAvailable
        }
        return false
    }()
    @State private var stepCount: Double = 0
    @State private var sleepHours: Double = 0
    @State private var averageHeartRate: Double = 0
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    /// 预留的异常提示信息，未来可用于根据健康数据给出本地建议。
    @State private var anomalyMessage: String?

    var body: some View {
        List {
            Section {
                HealthMetricRow(title: "步数", value: stepText, action: metricTapped)
                HealthMetricRow(title: "睡眠时长", value: sleepText, action: metricTapped)
                HealthMetricRow(title: "平均心率", value: heartText, action: metricTapped)
            }

            if let anomalyMessage = anomalyMessage {
                Section {
                    Text(anomalyMessage)
                        .foregroundColor(.red)
                }
            }

            if !healthAvailable {
                Section {
                    Text("此设备不支持健康数据。")
                        .font(.footnote)
                }
            } else if !isAuthorized {
                Section {
                    Text("应用需要访问您的健康数据以提供更准确的建议。")
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("健康数据")
        .toolbar {
            Button(isAuthorized ? "刷新" : "授权") {
                if isAuthorized {
                    fetchData()
                } else {
                    requestAuthorization()
                }
            }
        }
        .onAppear {
            if healthAvailable {
                requestAuthorization()
            }
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("错误"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("确定")))
        }
    }

    private var stepText: String {
        if isAuthorized { return "\(Int(stepCount)) 步" }
        return placeholderText
    }

    private var sleepText: String {
        if isAuthorized { return String(format: "%.1f 小时", sleepHours) }
        return placeholderText
    }

    private var heartText: String {
        if isAuthorized { return "\(Int(averageHeartRate)) 次/分" }
        return placeholderText
    }

    private var placeholderText: String {
        healthAvailable ? "– 未授权" : "– 不支持"
    }

    /// 请求健康数据访问权限
    private func requestAuthorization() {
        guard hasHealthUsageDescription else {
            errorMessage = "缺少 HealthKit 权限说明"
            showError = true
            return
        }
        guard #available(iOS 15.0, *) else {
            errorMessage = "当前系统版本不支持健康数据"
            showError = true
            return
        }
        HealthService.shared.requestAuthorization { success, error in
            self.isAuthorized = success
            if success {
                self.fetchData()
            } else {
                self.errorMessage = error?.localizedDescription ?? "授权失败或被拒绝"
                self.showError = true
            }
        }
    }

    /// 获取步数等数据
    private func fetchData() {
        guard #available(iOS 15.0, *) else { return }
        HealthService.shared.fetchStepCount { count in
            self.stepCount = count
        }
        HealthService.shared.fetchSleepAnalysis { hours in
            self.sleepHours = hours
        }
        HealthService.shared.fetchHeartRate { rate in
            self.averageHeartRate = rate
        }
    }

    /// 未授权时点击行再次请求授权。
    private func metricTapped() {
        if !isAuthorized && healthAvailable {
            requestAuthorization()
        }
    }

    private var hasHealthUsageDescription: Bool {
        Bundle.main.object(forInfoDictionaryKey: "NSHealthShareUsageDescription") != nil &&
        Bundle.main.object(forInfoDictionaryKey: "NSHealthUpdateUsageDescription") != nil
    }

    /// 行视图
    private struct HealthMetricRow: View {
        let title: String
        let value: String
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack {
                    Text(title)
                    Spacer()
                    Text(value)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
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

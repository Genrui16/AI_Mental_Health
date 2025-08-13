import SwiftUI

#if os(iOS)
/// 首次启动时显示的引导页，介绍应用的主要功能，并完成必要权限与 API Key 配置。
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var step: Int = 0

    // 权限
    @State private var healthGranted: Bool = false
    @State private var notificationsGranted: Bool = false

    // API Key
    @State private var apiKey: String = KeychainService.shared.getAPIKey() ?? ""
    @State private var showKeyError: Bool = false

    // 基线问题
    @AppStorage("onboardingMood") private var onboardingMood: Int = 3
    @AppStorage("onboardingSleep") private var onboardingSleep: Int = 3
    @AppStorage("onboardingStress") private var onboardingStress: Int = 3

    var body: some View {
        VStack {
            TabView(selection: $step) {
                welcomePage.tag(0)
                healthPage.tag(1)
                notifPage.tag(2)
                keyPage.tag(3)
                baselinePage.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut, value: step)

            HStack {
                if step > 0 { Button("上一步") { step -= 1 } }
                Spacer()
                if step < 4 {
                    Button("下一步") { step += 1 }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("完成") {
                        if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            showKeyError = true
                            step = 3
                            return
                        }
                        KeychainService.shared.saveAPIKey(apiKey)
                        // 默认安排一次日记提醒（可在设置中更改）
                        if notificationsGranted {
                            var comps = DateComponents()
                            comps.hour = 21; comps.minute = 0
                            let date = Calendar.current.date(from: comps) ?? Date()
                            NotificationService.shared.scheduleDiaryReminder(at: date)
                        }
                        hasSeenOnboarding = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .alert("需要 API Key", isPresented: $showKeyError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("请输入有效的 OpenAI API Key 以启用 AI 建议与聊天功能。你可以稍后在“设置”中修改。")
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
            Text("欢迎使用 MindSync")
                .font(.title).bold()
            Text("本应用可根据你的心情、睡眠与活动，为你生成个性化的日程建议，并提供心理日记与趋势分析。")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var healthPage: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill").font(.system(size: 60))
            Text("同步健康数据").font(.title3).bold()
            Text("授权读取步数、睡眠与心率，以便生成更贴合你的建议。")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            if #available(iOS 15.0, *) {
                Button(healthGranted ? "已授权" : "授权 HealthKit") {
                    HealthService.shared.requestAuthorization { granted, error in
                        healthGranted = granted
                        if let error = error {
                            // 这里可改为展示 alert；先简单打印
                            print("Health authorization error: \(error.localizedDescription)")
                        }
                    }
                }
                .disabled(healthGranted || !HealthService.shared.isHealthDataAvailable)
            } else {
                Text("需要 iOS 15+ 才能使用 HealthKit。").font(.footnote).foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private var notifPage: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.badge.fill").font(.system(size: 60))
            Text("开启提醒").font(.title3).bold()
            Text("为 AI 建议与日记设置本地通知，帮助你按时执行与记录。")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button(notificationsGranted ? "已授权" : "授权通知") {
                NotificationService.shared.requestAuthorization { granted in
                    notificationsGranted = granted
                }
            }
            .disabled(notificationsGranted == true)
        }
        .padding()
    }

    private var keyPage: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill").font(.system(size: 60))
            Text("配置 OpenAI API Key").font(.title3).bold()
            SecureField("请输入 API Key", text: $apiKey)
                .textContentType(.password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            Text("API Key 仅存储在本地 Keychain 中，用于向 OpenAI 发起请求。")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var baselinePage: some View {
        VStack(spacing: 16) {
            Image(systemName: "slider.horizontal.3").font(.system(size: 60))
            Text("建立你的基线").font(.title3).bold()
            VStack(alignment: .leading) {
                Text("当前心情：\(onboardingMood)")
                Slider(value: Binding(get: { Double(onboardingMood) }, set: { onboardingMood = Int($0) }), in: 1...10, step: 1)
                Text("昨晚睡眠：\(onboardingSleep) 小时").padding(.top, 8)
                Slider(value: Binding(get: { Double(onboardingSleep) }, set: { onboardingSleep = Int($0) }), in: 0...12, step: 1)
                Text("当前压力：\(onboardingStress)/10").padding(.top, 8)
                Slider(value: Binding(get: { Double(onboardingStress) }, set: { onboardingStress = Int($0) }), in: 1...10, step: 1)
            }
            .padding()
            Text("这些信息将用于初始化建议。你可在之后继续记录以便持续优化。")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
#endif

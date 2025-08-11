import SwiftUI

#if os(iOS)
/// 首次启动时显示的引导页，介绍应用的主要功能。
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    var body: some View {
        TabView {
            VStack(spacing: 20) {
                Image(systemName: "clock")
                    .font(.system(size: 60))
                Text("时间轴")
                    .font(.title)
                Text("查看 AI 建议与实际活动，规划你的日程。")
                    .multilineTextAlignment(.center)
            }
            .padding()

            VStack(spacing: 20) {
                Image(systemName: "book")
                    .font(.system(size: 60))
                Text("心理日记")
                    .font(.title)
                Text("记录心情，与 AI 对话或语音输入你的想法。")
                    .multilineTextAlignment(.center)
            }
            .padding()

            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                Text("健康数据")
                    .font(.title)
                Text("同步步数、睡眠等健康信息，了解身心状态。")
                    .multilineTextAlignment(.center)
                Button("开始使用") {
                    hasSeenOnboarding = true
                }
                .padding(.top, 30)
            }
            .padding()
        }
        .tabViewStyle(PageTabViewStyle())
    }
}
#endif

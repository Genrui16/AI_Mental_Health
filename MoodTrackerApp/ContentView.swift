#if os(iOS)
import SwiftUI

/// 主视图，包含底部标签栏用于在不同模块间切换。
struct ContentView: View {
    var body: some View {
        TabView {
            TimelineView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("时间轴")
                }

            DiaryView()
                .tabItem {
                    Image(systemName: "book")
                    Text("日记")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("我的")
                }
        }
    }
}

// MARK: - 预览
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
#endif

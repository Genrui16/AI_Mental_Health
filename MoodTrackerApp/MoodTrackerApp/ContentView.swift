//
//  ContentView.swift
//  MoodTrackerApp
//
//  Created by 刘根瑞 on 8/10/25.
//

import SwiftUI

/// 主视图，包含底部标签栏用于在不同模块间切换。
/// 该视图整合了时间轴、心理日记和个人中心等功能模块。
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

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif

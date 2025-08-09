import SwiftUI

/// 应用程序的入口点，启动用户界面。
@main
struct MoodTrackerApp: App {
    @StateObject private var appData = AppData()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appData)
        }
    }
}

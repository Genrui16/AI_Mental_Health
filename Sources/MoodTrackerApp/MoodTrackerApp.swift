import SwiftUI
import CoreData

/// 应用程序的入口点，启动用户界面。
@main
struct MoodTrackerApp: App {
    @StateObject private var appData = AppData()
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appData)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

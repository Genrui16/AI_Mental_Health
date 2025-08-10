#if os(iOS)
import SwiftUI
import CoreData

/// 应用程序的入口点，启动用户界面。
@main
struct MoodTrackerApp: App {
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
#endif

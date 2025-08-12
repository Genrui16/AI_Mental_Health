//
//  MoodTrackerAppApp.swift
//  MoodTrackerApp
//
//  Created by 刘根瑞 on 8/10/25.
//

import SwiftUI
import CoreData

@main
struct MoodTrackerAppApp: App {
    /// Core Data 持久化控制器，用于在应用生命周期内共享数据库上下文。
    private let persistenceController = PersistenceController.shared
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
                    // 将 Core Data 上下文注入环境，供各视图使用
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .onAppear {
                        MaintenanceService.run(context: persistenceController.container.viewContext)
                    }
            } else {
                OnboardingView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .onAppear {
                        MaintenanceService.run(context: persistenceController.container.viewContext)
                    }
            }
        }
    }
}

//
//  Habit_TrackerApp.swift
//  Habit Tracker
//
//  Created by Ignas Panavas on 5/8/25.
//

import SwiftUI

@main
struct Habit_TrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("isSetupComplete") var isSetupComplete: Bool = false
    @AppStorage("notion_db_name") var dbName: String = ""

    var body: some Scene {
            WindowGroup {
                if isSetupComplete {
                    HabitListView()  // or FirstPageViewer
                        .environmentObject(NotionManager())
                } else {
                    WelcomeView()
                }
            }
        }
}

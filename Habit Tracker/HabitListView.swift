//
//  HabitList.swift
//  Habit Tracker
//
//  Created by Ignas Panavas on 5/10/25.
//

import SwiftUI

struct HabitListView: View {
    @EnvironmentObject var notionManager: NotionManager

    var body: some View {
        NavigationView {
            if notionManager.isInitialized {
                List {
                    ForEach($notionManager.habits, id: \.id) { $block in
                        HabitRow(block: $block) {
                            let newValue = !(block.to_do?.checked ?? false)
                            block.to_do?.checked = newValue // ✅ Optimistically update

                            Task {
                                do {
                                    try await notionManager.toggleHabit(block: block)
                                } catch {
                                    print("❌ Failed to update habit. Reverting.")
                                    if var todo = block.to_do {
                                        todo.checked = !(todo.checked ?? false)
                                        block.to_do = todo // ✅ overwrite with updated version
                                    } // Optionally revert
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Daily Habits")
                .refreshable {
                    do {
                        try await notionManager
                            .refreshHabits()
                    } catch {
                        print("❌ Failed to load habits: \(error)")
                    }
                }
                .task {
                    do {
                        try await notionManager
                            .refreshHabits()
                    } catch {
                        print("❌ Failed to load habits: \(error)")
                    }
                }
            } else {
                ProgressView("Initializing Notion...")
                    .navigationTitle("Daily Habits")
            }
        }
    }
}


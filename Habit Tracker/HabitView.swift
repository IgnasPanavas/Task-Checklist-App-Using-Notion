//
//  HabitView.swift
//  Habit Tracker
//
//  Created by Ignas Panavas on 5/8/25.
//


import SwiftUI

struct HabitView: View {
    var habit: Habit
    
    @EnvironmentObject var notionManager: NotionManager
    @State private var pageContent: String = "Tap the button to load the first page."
    var body: some View {
        VStack(alignment: .leading) {
            HabitListView()
            
        }
    }
}


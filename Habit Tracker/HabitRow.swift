//
//  HabitRow.swift
//  Habit Tracker
//
//  Created by Ignas Panavas on 5/10/25.
//

import SwiftUI

struct HabitRow: View {
    @Binding var block: NotionBlock
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Text(block.to_do?.checked == true ? "☑️" : "⬜️")
            }
            .buttonStyle(PlainButtonStyle())

            Text(block.to_do?.rich_text.map(\.plain_text).joined() ?? "(no text)")
            Spacer()
        }
        .padding(.vertical, 4)
    }
}


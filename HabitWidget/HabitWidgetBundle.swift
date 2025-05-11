//
//  HabitWidgetBundle.swift
//  HabitWidget
//
//  Created by Ignas Panavas on 5/10/25.
//

import WidgetKit
import SwiftUI

@main
struct HabitWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitWidget()
        HabitWidgetControl()
        HabitWidgetLiveActivity()
    }
}

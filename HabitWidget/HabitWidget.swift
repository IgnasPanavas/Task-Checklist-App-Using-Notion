//
//  HabitWidget.swift
//  HabitWidget
//
//  Created by Ignas Panavas on 5/10/25.
//

import WidgetKit
import SwiftUI
import AppIntents

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let habits: [Habit]
}

struct Habit: Identifiable, Hashable {
    let id: String
    let title: String
    let checked: Bool
}


struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
            SimpleEntry(
                date: Date(),
                configuration: ConfigurationAppIntent(),
                habits: [
                    Habit(id: "demo", title: "Sample Habit", checked: false)
                ]
            )
        }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let defaults = UserDefaults(suiteName: "group.com.yourname.habittracker")
        let rawHabits = defaults?.array(forKey: "widgetHabits") as? [[String:Any]] ?? []

        // decode your Habit model
        let allHabits = rawHabits.compactMap { dict -> Habit? in
          guard let id      = dict["id"]    as? String,
                let title   = dict["title"] as? String,
                let checked = dict["checked"] as? Bool
          else { return nil }
          return Habit(id: id, title: title, checked: checked)
        }

        // only keep those that are still unchecked
        let unchecked = allHabits.filter { !$0.checked }

        return SimpleEntry(
          date:      Date(),
          configuration: configuration,
          habits:    unchecked
        )

    }
    func timeline(
        for configuration: ConfigurationAppIntent,
        in context: Context
    ) async -> Timeline<SimpleEntry> {
        let suite   = UserDefaults(suiteName: "group.com.yourname.habittracker")
        let raw     = suite?.array(forKey: "widgetHabits") as? [[String: Any]] ?? []
        let now     = Date().timeIntervalSince1970
        let delay: TimeInterval = 3.0

        // 1) Decode and decide which to show
        let displayHabits: [Habit] = raw.compactMap { dict in
            guard
                let id      = dict["id"]      as? String,
                let title   = dict["title"]   as? String,
                let checked = dict["checked"] as? Bool
            else { return nil }
            if !checked {
                // still unchecked → show
                return Habit(id: id, title: title, checked: false)
            }
            // if it *was* checked, only show it for `delay` seconds after that moment:
            if let ts = dict["checkedDate"] as? TimeInterval,
               now - ts < delay {
                return Habit(id: id, title: title, checked: true)
            }
            // otherwise hide it
            return nil
        }

        let entry = SimpleEntry(
            date: Date(),
            configuration: configuration,
            habits: displayHabits
        )

        // 2) Ask WidgetKit to call us again when any in-flight check might expire
        //    If there are no “in-flight” (i.e. recently checked) items, we can refresh later.
        let nextRefresh: Date
        if displayHabits.contains(where: { $0.checked }) {
            // schedule exactly when the oldest “in-flight” check crosses the 3 s mark
            let soonestExpiry = raw
                .compactMap { dict -> TimeInterval? in
                    guard
                      let checked = dict["checked"] as? Bool,
                      checked,
                      let ts = dict["checkedDate"] as? TimeInterval
                    else { return nil }
                    return ts + delay
                }
                .min() ?? now + delay

            nextRefresh = Date(timeIntervalSince1970: soonestExpiry)
        } else {
            // no pending removals — refresh in 15 minutes
            nextRefresh = Date().addingTimeInterval(15 * 60)
        }

        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }




//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct HabitWidgetEntryView: View {
    var entry: Provider.Entry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Habits")
                .font(.headline)

            ForEach(entry.habits.prefix(6)) { habit in
                let intent = {
                    let i = ToggleHabitIntent()
                    i.id = habit.id
                    return i
                }()

                HStack {
                    Button(intent: intent) {
                        Image(systemName: habit.checked ? "checkmark.circle.fill" : "circle")
                    }
                    .buttonStyle(.plain)

                    Text(habit.title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .padding()
    }
}

struct HabitWidget: Widget {
    let kind = "HabitWidget"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: Provider()
        ) { entry in
            HabitWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(.systemBackground)
                }
        }
        .supportedFamilies([.systemMedium, .systemLarge])
        .configurationDisplayName("Daily Habits")
        .description("Check off your habits from Notion right on your Home Screen.")
    }
}


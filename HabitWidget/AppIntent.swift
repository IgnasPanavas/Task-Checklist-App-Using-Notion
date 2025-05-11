//
//  AppIntent.swift
//  HabitWidget
//
//  Created by Ignas Panavas on 5/10/25.
//

import WidgetKit
import AppIntents

struct NotionBlock: Codable {
    let id: String
    let type: String

    let paragraph: ParagraphContent?
    let heading_1: HeadingContent?
    let heading_2: HeadingContent?
    let heading_3: HeadingContent?
    var to_do: ToDoContent?
    let bulleted_list_item: ListItemContent?

    struct ParagraphContent: Codable {
        let rich_text: [RichTextObject]
    }

    struct HeadingContent: Codable {
        let rich_text: [RichTextObject]
    }

    struct ListItemContent: Codable {
        let rich_text: [RichTextObject]
    }

    struct ToDoContent: Codable {
        let rich_text: [RichTextObject]
        var checked: Bool?
    }

    struct RichTextObject: Codable {
        let plain_text: String
    }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    // An example configurable parameter.
    @Parameter(title: "number of habits to display", default: 10)
    var numHabits: Int
}

struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Habit"

    @Parameter(title: "Habit ID")
    var id: String

    func perform() async throws -> some IntentResult {
        let suiteName = "group.com.yourname.habittracker"
        let defaults  = UserDefaults(suiteName: suiteName)!

        // ── 1) Load current data & queue
        var stored = defaults.array(forKey: "widgetHabits") as? [[String: Any]] ?? []
        var queue  = defaults.stringArray(forKey: "queuedRemovalQueue") ?? []

        // ── 2) Pop the oldest queued habit (if any) and remove it
        if let toRemove = queue.first {
            stored.removeAll { $0["id"] as? String == toRemove }
            queue.removeFirst()
        }

        // ── 3) Find & toggle the tapped habit
        if let idx = stored.firstIndex(where: { $0["id"] as? String == id }),
           let curr = stored[idx]["checked"] as? Bool {
            let next = !curr
            stored[idx]["checked"] = next

            if next {
                // just got checked → enqueue for NEXT removal
                queue.append(id)
            } else {
                // got unchecked → if it was in queue, drop it
                queue.removeAll { $0 == id }
            }
        }

        // ── 4) Persist everything back
        defaults.set(stored, forKey: "widgetHabits")
        defaults.set(queue,  forKey: "queuedRemovalQueue")

        // ── 5) Refresh the widget
        WidgetCenter.shared.reloadAllTimelines()

        // ── 6) (Optional) Dispatch your Notion PATCH
        Task { try? await patchNotionBlock(id: id, to: stored.first { $0["id"] as? String == id }?["checked"] as? Bool ?? false) }

        return .result()
    }

    
    // MARK: — helper to PATCH the to_do block
    private func patchNotionBlock(id: String, to checked: Bool) async throws {
        let token = Bundle.main.infoDictionary?["NOTION_SECRET"] as? String ?? ""
        let url = URL(string: "https://api.notion.com/v1/blocks/\(id)")!
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("Bearer \(token)",       forHTTPHeaderField: "Authorization")
        req.setValue("application/json",      forHTTPHeaderField: "Content-Type")
        req.setValue("2022-06-28",            forHTTPHeaderField: "Notion-Version")
        req.httpBody = try JSONSerialization
                        .data(withJSONObject: ["to_do": ["checked": checked]])
        
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
}




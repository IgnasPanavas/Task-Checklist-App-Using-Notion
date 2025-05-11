# HabitTracker 
A SwiftUI-based habit-tracking app that integrates with Notion and offers a home-screen widget with optimistic UI toggles and queued removals.
## Features
- **Notion Integration**: Sync habits stored as To-Do blocks in your Notion workspace via Notion API. 
- **Optimistic UI**: Instant feedback when checking/unchecking habits on the widget, even before network confirmation.
- **Queued Removals**: Checked habits are queued and removed in FIFO order on next interaction, ensuring smooth replacement without timers.
- **Home-Screen Widget**: A WidgetKit-powered medium/large widget displays up to 6 habits, filtering out already-completed items.
- **App Intents**: Uses the AppIntents API for tappable widget buttons (`ToggleHabitIntent`).
- **App Group Sharing**: Shared `UserDefaults` suite (`group.com.yourname.habittracker`) for data sync between main app and widget.
## Requirements 
- iOS 16.1+ (WidgetKit & App Intents)
- Xcode 15+
- Swift 5.8+
- A Notion integration and database with To-Do blocks for habits
- App Group capability enabled for both main app and widget extension
## Setup 
1. **Clone the repository**: ```bash git clone https://github.com/yourname/HabitTracker.git cd HabitTracker ``` 
2. **Configure Notion integration**:
  - Create a Notion integration and share your habits database with it.
  - Copy the **Integration Secret**.
3. **Add the secret**:
  - In the **Main App** target, under **Capabilities**, enable **App Groups** and add `group.com.yourname.habittracker`.
  - Store your `NOTION_SECRET` in the App Group’s `UserDefaults` (or shared Keychain): ```swift UserDefaults(suiteName: "group.com.yourname.habittracker")?.set("<YOUR_NOTION_SECRET>", forKey: "NOTION_SECRET") ```
4. **Configure the Widget**:
    - In the **Widget Extension**, enable the same App Group and ensure Info.plist has no hardcoded secret.
    - The widget reads habits and the queued-removal queue from the shared suite. 5. **Run**:
    - Build & run the **HabitTracker** scheme on a device or simulator.
    - Add the **HabitTracker Widget** to your home screen.
## Architecture 
**Main App**
- Manages initial fetch of habits from Notion via `/blocks` API.
- Saves habits array (`widgetHabits`) and `queuedRemovalQueue` in shared `UserDefaults`.
- Optionally triggers Live Activities via ActivityKit (if enabled).
**Widget Extension**
  - **`Provider`**: Implements `AppIntentTimelineProvider`.
    - `snapshot(for:in:)` & `timeline(for:in:)` filter out habits by `checked` flag and queue.
  - **`HabitWidgetEntryView`**: Renders up to 6 habits with tappable checkmark buttons.
  - **`ToggleHabitIntent`**
    - Pops oldest queued habit, toggles the tapped habit, updates queue.
    - Persists to shared defaults and reloads timeline immediately.
    - Dispatches Notion PATCH in the background. 
## Customization 
- **Filter count**: Change `.prefix(6)` in `HabitWidgetEntryView` to display more/less habits.
- **Widget families**: Adjust `.supportedFamilies([...])` in `HabitWidget`.
- **Database property**: Rename/override the Notion To-Do property key if your database uses a different name.
## Troubleshooting 
- **No habits appear**: Ensure `widgetHabits` is populated by launching the main app at least once.
- **Secret not found in widget**: Confirm App Group and Info.plist configuration; prefer shared defaults over Info.plist.
- **Taps not registering**: Verify the App Intents entitlement and that `ToggleHabitIntent` is included in the widget extension.
## License MIT © Ignas Panavas

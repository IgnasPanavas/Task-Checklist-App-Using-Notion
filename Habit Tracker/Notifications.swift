//
//  Notifications.swift
//  Habit Tracker
//
//  Created by Ignas Panavas on 5/10/25.
//

import UserNotifications

func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        if granted {
            print("✅ Permission granted")
        } else {
            print("❌ Permission denied: \(String(describing: error))")
        }
    }
}

func scheduleLocalNotification(
    title: String,
    body: String,
    at date: Date? = nil,
    inSeconds seconds: TimeInterval? = nil,
    repeats: Bool = false
) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let trigger: UNNotificationTrigger

    if let seconds = seconds {
        trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: repeats)
    } else if let date = date {
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
    } else {
        print("❌ Error: Must provide either `at` or `inSeconds`.")
        return
    }

    let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("❌ Failed to schedule notification: \(error)")
        } else {
            print("✅ Notification scheduled: \(title)")
        }
    }
}

func ScheduleDailyReminderNotification() {
    var components = DateComponents()
    components.hour = 9
    components.minute = 0
    if let date = Calendar.current.date(from: components) {
        scheduleLocalNotification(
            title: "Morning Check-in",
            body: "Have you done your first habit?",
            at: date,
            repeats: true
        )
    }
}

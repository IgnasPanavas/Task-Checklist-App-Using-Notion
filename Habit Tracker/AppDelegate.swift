//
//  AppDelegate.swift
//  Habit Tracker
//
//  Created by Ignas Panavas on 5/10/25.
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        requestNotificationPermission()
        return true
    }
}

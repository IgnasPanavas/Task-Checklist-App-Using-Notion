//
//  HabitObject.swift
//  Habit Tracker
//
//  Created by Ignas Panavas on 5/8/25.
//



import Foundation

public class Habit: Codable {
    public var name: String
    public var days: [Int]
    
    public init(name: String, days: [Int]) {
        self.name = name
        self.days = days
    }
}

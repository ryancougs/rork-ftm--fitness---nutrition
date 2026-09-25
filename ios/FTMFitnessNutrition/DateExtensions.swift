//
//  DateExtensions.swift
//  FTMFitnessNutrition
//

import Foundation

extension Date {
    /// Returns true if this date falls on the same calendar day as `otherDate`.
    func isSameDay(as otherDate: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: otherDate)
    }

    /// Returns a human-readable relative string like "Today", "Yesterday", "3 days ago", "Last week".
    var relativeDescription: String {
        let cal = Calendar.current
        if cal.isDateInToday(self) { return "Today" }
        if cal.isDateInYesterday(self) { return "Yesterday" }
        let dayDiff = cal.dateComponents([.day], from: self, to: Date()).day ?? 0
        if dayDiff < 7 { return "\(dayDiff) days ago" }
        if dayDiff < 14 { return "Last week" }
        let weekDiff = dayDiff / 7
        if weekDiff < 5 { return "\(weekDiff) weeks ago" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: self)
    }
}

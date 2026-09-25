//
//  CheckInReminder.swift
//  FTMFitnessNutrition
//

import UserNotifications

/// Schedules the weekly check-in nudge — positive framing, never guilt.
/// Fires every Sunday at 10:00 local time and repeats.
enum CheckInReminder {
    static func requestAndSchedule() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus != .denied else { return }
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = "Keep winning 💪"
        content.body = "Your weekly check-in is ready — two minutes to log how the week felt. Mason reads every one."
        content.sound = .default

        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 10
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_checkin", content: content, trigger: trigger)
        try? await center.add(request)
    }
}

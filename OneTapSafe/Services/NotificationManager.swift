//
//  NotificationManager.swift
//  OneTapSafe
//

import Foundation
import UserNotifications

final class NotificationManager: NSObject {
    
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        center.delegate = self
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            print(granted ? "✅ Notification authorization granted" : "❌ Notification authorization denied")
            return granted
        } catch {
            print("❌ Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    // MARK: - Daily Reminder
    
    func scheduleDailyReminder(at time: Date) {
        // Cancel existing reminder
        center.removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Safety Check-In"
        content.body = "Tap to confirm you're safe today"
        content.sound = .default
        content.categoryIdentifier = "CHECK_IN_CATEGORY"
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "dailyReminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule daily reminder: \(error)")
            } else {
                print("✅ Daily reminder scheduled for \(time)")
            }
        }
    }
    
    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
        print("✅ Daily reminder cancelled")
    }
    
    // MARK: - Test Notification
    
    func sendTestReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Safety Check-In"
        content.body = "Tap to confirm you're safe today"
        content.sound = .default
        content.categoryIdentifier = "CHECK_IN_CATEGORY"
        
        // Fire in 5 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "testReminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to send test reminder: \(error)")
            } else {
                print("✅ Test reminder will appear in 5 seconds")
            }
        }
    }
    
    // MARK: - Missed Check-In Alert
    
    func sendMissedCheckInNotification() {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Check-In Missed"
        content.body = "You haven't checked in today. Your emergency contacts will be notified soon."
        content.sound = .defaultCritical
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "missedCheckIn",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to send missed check-in notification: \(error)")
            }
        }
    }
    
    // MARK: - Contact Notification Sent
    
    func sendContactNotifiedAlert(contactName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Emergency Contact Notified"
        content.body = "\(contactName) has been notified that you missed your check-in"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    // MARK: - Setup
    
    func setupNotificationCategories() {
        let checkInAction = UNNotificationAction(
            identifier: "CHECK_IN_ACTION",
            title: "I'm OK",
            options: [.foreground]
        )
        
        let checkInCategory = UNNotificationCategory(
            identifier: "CHECK_IN_CATEGORY",
            actions: [checkInAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([checkInCategory])
        print("✅ Notification categories configured")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Live Activity should already be running proactively
        // No need to start it here
        completionHandler([.banner, .sound])
    }
    
    // Handle notification tap or action
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("🔔 Notification tapped: \(response.notification.request.identifier)")
        
        // Live Activity should already be running proactively
        // User can check in directly from Lock Screen Live Activity
        
        if response.actionIdentifier == "CHECK_IN_ACTION" {
            // User tapped "I'm OK" action button from notification
            print("🔔 User tapped 'I'm OK' action button")
            DataStore.shared.recordCheckIn(method: .notification)
            if #available(iOS 16.1, *) {
                LiveActivityManager.shared.endActivity()
            }
        }
        
        completionHandler()
    }
    
    // MARK: - Helper (deprecated - Live Activity now starts proactively)
    
    @available(*, deprecated, message: "Live Activity now starts proactively, not from notifications")
    private func startLiveActivityForReminder() {
        if #available(iOS 16.1, *) {
            // Calculate deadline (8 hours from now)
            let deadline = Calendar.current.date(byAdding: .hour, value: 8, to: Date()) ?? Date()
            LiveActivityManager.shared.startActivity(deadline: deadline, userName: "You")
            print("✅ Live Activity started from daily reminder")
        }
    }
}

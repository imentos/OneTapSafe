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
        // Cancel existing reminders
        center.removePendingNotificationRequests(withIdentifiers: ["dailyReminder", "deadlineCheck"])
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        
        // 1. Schedule the daily reminder notification
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
        
        // 2. Schedule deadline check notification (8 hours after reminder)
        // This ensures contacts get notified even if user doesn't open the app
        // IMPORTANT: Schedule for TODAY ONLY - not repeating
        // Next day's deadline will be scheduled when next check-in flow starts
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate today's deadline time (reminder time + 8 hours)
        guard let todayDeadline = calendar.date(
            bySettingHour: components.hour ?? 9,
            minute: components.minute ?? 0,
            second: 0,
            of: now
        ),
        let deadlineWithOffset = calendar.date(byAdding: .hour, value: 8, to: todayDeadline) else {
            print("❌ Failed to calculate deadline time")
            return
        }
        
        // Only schedule if deadline is in the future
        guard deadlineWithOffset > now else {
            print("ℹ️ Deadline time already passed today - will schedule tomorrow")
            return
        }
        
        let deadlineComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: deadlineWithOffset)
        let deadlineTrigger = UNCalendarNotificationTrigger(dateMatching: deadlineComponents, repeats: false)
        
        let deadlineRequest = UNNotificationRequest(
            identifier: "deadlineCheck",
            content: createMissedCheckInNotificationContent(),
            trigger: deadlineTrigger
        )
        
        center.add(deadlineRequest) { error in
            if let error = error {
                print("❌ Failed to schedule deadline check: \(error)")
            } else {
                print("✅ Deadline check scheduled for 8 hours after reminder")
            }
        }
    }
    
    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["dailyReminder", "deadlineCheck"])
        print("✅ Daily reminder and deadline check cancelled")
    }
    
    func cancelDeadlineNotification() {
        center.removePendingNotificationRequests(withIdentifiers: ["deadlineCheck"])
        print("✅ Deadline notification cancelled - user checked in")
    }
    
    // MARK: - Schedule Today's Deadline Only
    
    /// Schedules deadline notification for TODAY only (not repeating)
    /// Called when daily reminder fires to set today's deadline
    func scheduleTodayDeadlineNotification(reminderTime: Date) {
        // Cancel any existing deadline notification first
        center.removePendingNotificationRequests(withIdentifiers: ["deadlineCheck"])
        
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate today's deadline time (reminder time + 8 hours)
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        guard let todayDeadline = calendar.date(
            bySettingHour: components.hour ?? 9,
            minute: components.minute ?? 0,
            second: 0,
            of: now
        ),
        let deadlineWithOffset = calendar.date(byAdding: .hour, value: 8, to: todayDeadline) else {
            print("❌ Failed to calculate deadline time")
            return
        }
        
        // Only schedule if deadline is in the future
        guard deadlineWithOffset > now else {
            print("ℹ️ Deadline time already passed today - no notification needed")
            return
        }
        
        let deadlineComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: deadlineWithOffset)
        let deadlineTrigger = UNCalendarNotificationTrigger(dateMatching: deadlineComponents, repeats: false)
        
        let deadlineRequest = UNNotificationRequest(
            identifier: "deadlineCheck",
            content: createMissedCheckInNotificationContent(),
            trigger: deadlineTrigger
        )
        
        center.add(deadlineRequest) { error in
            if let error = error {
                print("❌ Failed to schedule today's deadline: \(error)")
            } else {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                print("✅ Today's deadline scheduled for \(formatter.string(from: deadlineWithOffset))")
            }
        }
    }
    
    // MARK: - Missed Check-In Notification Content
    
    private func createMissedCheckInNotificationContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Check-In Missed"
        content.body = "You haven't checked in today. Your emergency contacts will be notified soon."
        content.sound = .defaultCritical
        content.categoryIdentifier = "DEADLINE_CATEGORY"
        return content
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
    
    func scheduleTestDeadlineNotification(for deadline: Date) {
        // Cancel any existing deadline notification first
        center.removePendingNotificationRequests(withIdentifiers: ["deadlineCheck"])
        
        let calendar = Calendar.current
        let deadlineComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: deadline)
        let deadlineTrigger = UNCalendarNotificationTrigger(dateMatching: deadlineComponents, repeats: false)
        
        let deadlineRequest = UNNotificationRequest(
            identifier: "deadlineCheck",
            content: createMissedCheckInNotificationContent(),
            trigger: deadlineTrigger
        )
        
        center.add(deadlineRequest) { error in
            if let error = error {
                print("❌ Failed to schedule test deadline: \(error)")
            } else {
                let formatter = DateFormatter()
                formatter.timeStyle = .medium
                print("✅ Test deadline scheduled for \(formatter.string(from: deadline))")
            }
        }
    }
    
    // MARK: - Missed Check-In Alert (for manual triggers)
    
    func sendMissedCheckInNotification() {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "missedCheckIn",
            content: createMissedCheckInNotificationContent(),
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
        print("🔔 Notification will present: \(notification.request.identifier)")
        
        // START LIVE ACTIVITY when daily reminder notification appears
        if notification.request.identifier == "dailyReminder" {
            print("⏰ Daily reminder notification - starting Live Activity NOW")
            startLiveActivityForDailyReminder()
            
            // CRITICAL FIX: Only reschedule deadline if user hasn't checked in yet
            // This prevents rescheduling after user has already checked in
            if !DataStore.shared.hasCheckedInToday() {
                print("⏰ Rescheduling today's deadline since user hasn't checked in")
                let reminderTime = DataStore.shared.dailyReminderTime
                scheduleTodayDeadlineNotification(reminderTime: reminderTime)
            } else {
                print("✅ User already checked in today - skipping deadline reschedule")
            }
        }
        
        // Check if this is the deadline notification
        if notification.request.identifier == "deadlineCheck" {
            print("⏰ Deadline notification triggered - checking for missed check-in")
            
            // Double-check: if user already checked in, don't proceed
            if DataStore.shared.hasCheckedInToday() {
                print("✅ User already checked in today - suppressing alarm")
                completionHandler([]) // No banner, no sound
                return
            }
            
            CheckInCoordinator.shared.checkMissedCheckInStatus(fromScheduledNotification: true)
        }
        
        completionHandler([.banner, .sound])
    }
    
    // Handle notification tap or action
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("🔔 Notification tapped: \(response.notification.request.identifier)")
        
        // START LIVE ACTIVITY when user taps daily reminder
        if response.notification.request.identifier == "dailyReminder" {
            print("⏰ Daily reminder tapped - starting Live Activity NOW")
            startLiveActivityForDailyReminder()
            
            // CRITICAL FIX: Only reschedule deadline if user hasn't checked in yet
            // This prevents rescheduling after user has already checked in
            if !DataStore.shared.hasCheckedInToday() {
                print("⏰ Rescheduling today's deadline since user hasn't checked in")
                let reminderTime = DataStore.shared.dailyReminderTime
                scheduleTodayDeadlineNotification(reminderTime: reminderTime)
            } else {
                print("✅ User already checked in today - skipping deadline reschedule")
            }
        }
        
        // Check if this is the deadline notification
        if response.notification.request.identifier == "deadlineCheck" {
            print("⏰ Deadline notification tapped - checking for missed check-in")
            
            // Double-check: if user already checked in, don't proceed
            if DataStore.shared.hasCheckedInToday() {
                print("✅ User already checked in today - no action needed")
                completionHandler()
                return
            }
            
            CheckInCoordinator.shared.checkMissedCheckInStatus(fromScheduledNotification: true)
        }
        
        if response.actionIdentifier == "CHECK_IN_ACTION" {
            // User tapped "I'm OK" action button from notification
            print("🔔 User tapped 'I'm OK' action button")
            CheckInCoordinator.shared.handleCheckIn(method: .notification)
        }
        
        completionHandler()
    }
    
    // MARK: - Live Activity Helper
    
    private func startLiveActivityForDailyReminder() {
        if #available(iOS 16.1, *) {
            // Don't start if user already checked in
            guard !DataStore.shared.hasCheckedInToday() else {
                print("ℹ️ Already checked in today, no Live Activity needed")
                return
            }
            
            // Calculate deadline (8 hours from reminder time)
            let reminderTime = DataStore.shared.dailyReminderTime
            let calendar = Calendar.current
            let now = Date()
            
            // Get today's reminder time
            let todayReminder = calendar.date(
                bySettingHour: calendar.component(.hour, from: reminderTime),
                minute: calendar.component(.minute, from: reminderTime),
                second: 0,
                of: now
            ) ?? now
            
            let deadline = calendar.date(byAdding: .hour, value: 8, to: todayReminder) ?? now
            
            LiveActivityManager.shared.startActivity(deadline: deadline, userName: "You")
            print("✅ Live Activity started from daily reminder at 9:00 AM")
            print("   - Deadline: \(deadline)")
            print("   👉 LOCK YOUR PHONE to see it on Lock Screen")
        }
    }
}

//
//  CheckInCoordinator.swift
//  OneTapSafe
//

import Foundation
import UIKit
import ActivityKit
import Combine

/// Coordinates check-in logic, Live Activities, and notifications
final class CheckInCoordinator: ObservableObject {
    
    static let shared = CheckInCoordinator()
    
    @Published var isCheckInDue: Bool = false
    @Published var missedCheckIn: Bool = false
    
    private init() {}
    
    // MARK: - Start Daily Check-In
    
    func startDailyCheckIn() {
        // Calculate deadline (e.g., 8 hours from reminder time)
        let reminderTime = DataStore.shared.dailyReminderTime
        let deadline = Calendar.current.date(byAdding: .hour, value: 8, to: reminderTime) ?? Date()
        
        // Primary: Start Live Activity immediately (proactive approach)
        // This ensures Live Activity is already visible before reminder time
        // User will see countdown on Lock Screen without needing to open the app
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.startActivity(deadline: deadline)
            print("✅ Live Activity started proactively")
            print("   - Deadline: \(deadline)")
            print("   - User can check in from Lock Screen anytime")
        }
        
        // Fallback: Schedule notification as backup reminder
        // This fires at reminder time as an additional prompt
        // But Live Activity is already running by this point
        NotificationManager.shared.scheduleDailyReminder(at: reminderTime)
        
        isCheckInDue = true
        missedCheckIn = false
        
        print("✅ Daily check-in flow initiated")
        print("   - Primary: Live Activity (already visible)")
        print("   - Backup: Notification at \(reminderTime)")
    }
    
    // MARK: - Handle Check-In Completion
    
    func handleCheckIn(method: CheckInMethod) {
        print("\n🎯 handleCheckIn() called - method: \(method.rawValue)")
        DataStore.shared.recordCheckIn(method: method)
        
        // End Live Activity
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.endActivity()
        }
        
        // Cancel deadline notification - user has checked in, no need for alarm
        print("🔔 About to cancel deadline notification...")
        NotificationManager.shared.cancelDeadlineNotification()
        print("🔔 Deadline notification cancellation completed")
        
        isCheckInDue = false
        missedCheckIn = false
        
        // Log analytics event
        let hasContacts = !DataStore.shared.trustedContacts.isEmpty
        FirebaseManager.shared.logCheckIn(method: method, hasContacts: hasContacts)
        
        print("✅ Check-in completed via \(method.rawValue)")
    }
    
    // MARK: - Handle Missed Check-In
    
    func handleMissedCheckIn(fromScheduledNotification: Bool = false) {
        print("🔔 handleMissedCheckIn called (fromScheduledNotification: \(fromScheduledNotification))")
        
        guard !DataStore.shared.hasCheckedInToday() else {
            print("ℹ️ Check-in already completed today")
            return
        }
        
        // Don't notify again if already notified today
        guard !DataStore.shared.hasNotifiedContactsToday() else {
            print("ℹ️ Contacts already notified today - skipping")
            return
        }
        
        print("✅ Passed all guards - proceeding with missed check-in handling")
        
        missedCheckIn = true
        
        // Send user notification (skip if deadline notification already showed it)
        if !fromScheduledNotification {
            print("📱 Sending missed check-in notification to user...")
            NotificationManager.shared.sendMissedCheckInNotification()
        } else {
            print("ℹ️ Skipping user notification (already shown by scheduled notification)")
        }
        
        // Update Live Activity to show overdue
        if #available(iOS 16.1, *) {
            let deadline = Date() // Already passed
            LiveActivityManager.shared.updateActivity(deadline: deadline, isOverdue: true)
        }
        
        // Notify emergency contacts - use background task to ensure completion
        let missedCheckInTime = DataStore.shared.lastCheckInDate ?? Date()
        let contactsCount = DataStore.shared.trustedContacts.count
        
        print("📧 Preparing to notify \(contactsCount) emergency contact(s)...")
        
        // Request background execution time for critical notification
        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "EmergencyContactNotification") {
            // Cleanup if we run out of time
            print("⚠️ Background time expired before notifications completed")
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
        
        print("🔄 Starting background task for email sending...")
        
        // Send notifications in background task
        Task {
            await ContactNotifier.shared.notifyContacts(for: missedCheckInTime)
            print("✅ All emergency contact notifications sent successfully")
            
            // End background task
            if backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
        }
        
        // Mark that we've notified today
        DataStore.shared.markContactsNotified()
        
        // Log analytics event
        let hoursLate = Int(Date().timeIntervalSince(missedCheckInTime) / 3600)
        FirebaseManager.shared.logMissedCheckIn(hoursLate: hoursLate, contactsNotified: contactsCount)
        
        print("⚠️ Missed check-in handled - contacts being notified with background task support")
    }
    
    // MARK: - Check Status
    
    func checkMissedCheckInStatus(forceTest: Bool = false, fromScheduledNotification: Bool = false) {
        // Don't check on first app launch (no check-in history exists)
        guard DataStore.shared.lastCheckInDate != nil else {
            print("ℹ️ First app launch - skipping missed check-in check")
            return
        }
        
        // Check if user should have checked in today but hasn't
        let hasCheckedIn = DataStore.shared.hasCheckedInToday()
        
        // For testing: force notification ONLY if user hasn't checked in yet
        if forceTest {
            if hasCheckedIn {
                print("🧪 Test mode: User already checked in - skipping notification")
                print("✅ TEST PASSED: Emergency contacts will NOT be notified")
                return
            }
            print("🧪 Test mode: Forcing missed check-in notification")
            handleMissedCheckIn()
            return
        }
        
        // If called from scheduled notification, the notification firing IS the deadline
        // No need to check shouldHaveCheckedInByNow() - just verify user hasn't checked in
        if fromScheduledNotification {
            if !hasCheckedIn {
                print("⏰ Scheduled deadline notification - user hasn't checked in")
                handleMissedCheckIn(fromScheduledNotification: true)
            } else {
                print("✅ Scheduled deadline notification - user already checked in, skipping")
            }
            return
        }
        
        // For manual checks (app launch, etc), verify both conditions
        if !hasCheckedIn && shouldHaveCheckedInByNow() {
            handleMissedCheckIn(fromScheduledNotification: false)
        }
    }
    
    private func shouldHaveCheckedInByNow() -> Bool {
        let reminderTime = DataStore.shared.dailyReminderTime
        let calendar = Calendar.current
        
        // Get today's reminder time
        let todayReminder = calendar.date(
            bySettingHour: calendar.component(.hour, from: reminderTime),
            minute: calendar.component(.minute, from: reminderTime),
            second: 0,
            of: Date()
        ) ?? Date()
        
        // Add grace period (e.g., 8 hours)
        let deadline = calendar.date(byAdding: .hour, value: 8, to: todayReminder) ?? Date()
        
        return Date() > deadline
    }
}

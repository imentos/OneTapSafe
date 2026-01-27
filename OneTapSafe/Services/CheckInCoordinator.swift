//
//  CheckInCoordinator.swift
//  OneTapSafe
//

import Foundation
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
        
        // Primary: Start Live Activity (more prominent and interactive)
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.startActivity(deadline: deadline)
            print("✅ Live Activity started as primary check-in mechanism")
        }
        
        // Fallback: Send notification reminder (only if Live Activity fails)
        // This ensures users without Live Activities enabled still get reminders
        NotificationManager.shared.scheduleDailyReminder(at: reminderTime)
        
        isCheckInDue = true
        missedCheckIn = false
        
        print("✅ Daily check-in started with deadline: \(deadline)")
        print("   - Primary: Live Activity on Lock Screen")
        print("   - Fallback: Local notification")
    }
    
    // MARK: - Handle Check-In Completion
    
    func handleCheckIn(method: CheckInMethod) {
        DataStore.shared.recordCheckIn(method: method)
        
        // End Live Activity
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.endActivity()
        }
        
        isCheckInDue = false
        missedCheckIn = false
        
        print("✅ Check-in completed via \(method.rawValue)")
    }
    
    // MARK: - Handle Missed Check-In
    
    func handleMissedCheckIn() {
        guard !DataStore.shared.hasCheckedInToday() else {
            print("ℹ️ Check-in already completed today")
            return
        }
        
        // Don't notify again if already notified today
        guard !DataStore.shared.hasNotifiedContactsToday() else {
            print("ℹ️ Contacts already notified today - skipping")
            return
        }
        
        missedCheckIn = true
        
        // Send alert notification to user
        NotificationManager.shared.sendMissedCheckInNotification()
        
        // Update Live Activity to show overdue
        if #available(iOS 16.1, *) {
            let deadline = Date() // Already passed
            LiveActivityManager.shared.updateActivity(deadline: deadline, isOverdue: true)
        }
        
        // Notify emergency contacts
        let missedCheckInTime = DataStore.shared.lastCheckInDate ?? Date()
        ContactNotifier.shared.notifyContacts(for: missedCheckInTime)
        
        // Mark that we've notified today
        DataStore.shared.markContactsNotified()
        
        print("⚠️ Missed check-in handled - contacts notified")
    }
    
    // MARK: - Check Status
    
    func checkMissedCheckInStatus() {
        // Don't check on first app launch (no check-in history exists)
        guard DataStore.shared.lastCheckInDate != nil else {
            print("ℹ️ First app launch - skipping missed check-in check")
            return
        }
        
        // Check if user should have checked in today but hasn't
        let hasCheckedIn = DataStore.shared.hasCheckedInToday()
        
        if !hasCheckedIn && shouldHaveCheckedInByNow() {
            handleMissedCheckIn()
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

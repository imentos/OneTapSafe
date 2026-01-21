//
//  OneTapSafeApp.swift
//  OneTapSafe
//
//  Created by Kuo, Ray on 1/19/26.
//

import SwiftUI

@main
struct OneTapSafeApp: App {
    
    init() {
        // Setup notifications
        NotificationManager.shared.setupNotificationCategories()
        
        // Request authorization
        Task {
            await NotificationManager.shared.requestAuthorization()
        }
        
        // Check for missed check-ins on app launch
        CheckInCoordinator.shared.checkMissedCheckInStatus()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Schedule daily reminder if enabled
                    if DataStore.shared.reminderEnabled {
                        NotificationManager.shared.scheduleDailyReminder(
                            at: DataStore.shared.dailyReminderTime
                        )
                    }
                    
                    // Auto-start Live Activity if check-in needed
                    startLiveActivityIfNeeded()
                }
        }
    }
    
    @available(iOS 16.1, *)
    private func startLiveActivityIfNeeded() {
        // Don't check on first app launch (no check-in history exists)
        guard DataStore.shared.lastCheckInDate != nil else {
            print("ℹ️ First app launch - skipping Live Activity start")
            return
        }
        
        // Don't start if there's already an active Live Activity
        if LiveActivityManager.shared.hasActiveActivity() {
            print("ℹ️ Live Activity already active, skipping")
            return
        }
        
        // Only start if user hasn't checked in today
        guard !DataStore.shared.hasCheckedInToday() else {
            print("ℹ️ Already checked in today, no Live Activity needed")
            return
        }
        
        // Check if it's past reminder time today
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
        
        // Only start Live Activity if it's past reminder time
        guard now >= todayReminder else {
            print("ℹ️ Not yet reminder time, no Live Activity")
            return
        }
        
        // Calculate deadline (8 hours from reminder time)
        let deadline = calendar.date(byAdding: .hour, value: 8, to: todayReminder) ?? now
        
        // Don't show if deadline has passed
        guard now < deadline else {
            print("⚠️ Deadline passed, handling as missed check-in")
            CheckInCoordinator.shared.handleMissedCheckIn()
            return
        }
        
        // Start Live Activity
        LiveActivityManager.shared.startActivity(deadline: deadline, userName: "You")
        print("✅ Auto-started Live Activity - check-in needed today")
    }
}


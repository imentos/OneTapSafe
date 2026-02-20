//
//  OneTapSafeApp.swift
//  OneTapSafe
//
//  Created by Kuo, Ray on 1/19/26.
//

import SwiftUI
import Firebase

@main
struct OneTapSafeApp: App {
    
    init() {
        // Initialize Firebase Analytics
        FirebaseApp.configure()
        print("🔥 Firebase configured successfully")
        
        // Setup notifications as fallback
        NotificationManager.shared.setupNotificationCategories()
        
        // Request notification authorization (fallback only)
        Task {
            await NotificationManager.shared.requestAuthorization()
        }
        
        // Check for missed check-ins on app launch
        CheckInCoordinator.shared.checkMissedCheckInStatus()
        
        // Log app launch event
        FirebaseManager.shared.logAppLaunch()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // PROACTIVE LIVE ACTIVITY STRATEGY:
                    // Live Activity starts BEFORE notification fires, so it's already
                    // visible on Lock Screen when reminder time arrives.
                    // User doesn't need to tap notification to see check-in UI.
                    
                    // 1. First launch: Start demo Live Activity immediately
                    startLiveActivityOnFirstLaunch()
                    
                    // 2. Schedule backup notification (fires at reminder time)
                    if DataStore.shared.reminderEnabled {
                        NotificationManager.shared.scheduleDailyReminder(
                            at: DataStore.shared.dailyReminderTime
                        )
                    }
                    
                    // 3. Auto-restart Live Activity if app opens and check-in is due
                    startLiveActivityIfNeeded()
                }
        }
    }
    
    @available(iOS 16.1, *)
    private func startLiveActivityOnFirstLaunch() {
        // On first launch, immediately start Live Activity to demonstrate the feature
        guard DataStore.shared.lastCheckInDate == nil else {
            return // Not first launch
        }
        
        print("🎉 First app launch - starting Live Activity demo")
        
        // Calculate deadline (8 hours from now)
        let deadline = Calendar.current.date(byAdding: .hour, value: 8, to: Date()) ?? Date()
        
        // Start Live Activity
        LiveActivityManager.shared.startActivity(deadline: deadline, userName: "You")
    }
    
    @available(iOS 16.1, *)
    private func startLiveActivityIfNeeded() {
        // Don't check on first app launch (handled by startLiveActivityOnFirstLaunch)
        guard DataStore.shared.lastCheckInDate != nil else {
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


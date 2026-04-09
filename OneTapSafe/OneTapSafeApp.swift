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
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Initialize Firebase Analytics
        FirebaseApp.configure()
        print("🔥 Firebase configured successfully")
        
        // Clean up orphaned Live Activities from previous sessions
        // This must happen BEFORE checking missed check-ins
        if #available(iOS 16.1, *) {
            Task {
                // Only clean up if user has already checked in today
                if DataStore.shared.hasCheckedInToday() {
                    await LiveActivityManager.shared.endAllActivities()
                    print("🧹 Cleaned up orphaned Live Activities (user already checked in)")
                }
            }
        }
        
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

                    // Only start Live Activity proactively if onboarding is already done
                    if DataStore.shared.hasCompletedOnboarding {
                        // 1. First launch: Start demo Live Activity immediately
                        startLiveActivityOnFirstLaunch()
                    }

                    // 2. Schedule backup notification (fires at reminder time)
                    if DataStore.shared.reminderEnabled {
                        NotificationManager.shared.scheduleDailyReminder(
                            at: DataStore.shared.dailyReminderTime
                        )
                    }

                    if DataStore.shared.hasCompletedOnboarding {
                        // 3. Auto-restart Live Activity if app opens and check-in is due
                        startLiveActivityIfNeeded()
                    }
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // CRITICAL: Cancel deadline notification when app becomes active
            // This handles the case where CheckInIntent (Live Activity button) 
            // opens the app after recording check-in
            if newPhase == .active {
                print("📱 App became active - checking for check-in status")
                if DataStore.shared.hasCheckedInToday() {
                    print("✅ User checked in - cancelling deadline notification")
                    NotificationManager.shared.cancelDeadlineNotification()
                }
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
        
        // If user has checked in today, cleanup everything
        if DataStore.shared.hasCheckedInToday() {
            // ALWAYS cancel deadline notification when checked in
            // (Live Activity may have already been ended by CheckInIntent)
            NotificationManager.shared.cancelDeadlineNotification()
            
            // End Live Activity if still active
            if LiveActivityManager.shared.hasActiveActivity() {
                print("✅ Check-in completed - ending Live Activity and cancelling notifications")
                LiveActivityManager.shared.endActivity()
            } else {
                print("✅ Already checked in today - deadline notification cancelled")
            }
            return
        }
        
        // Don't start if there's already an active Live Activity
        if LiveActivityManager.shared.hasActiveActivity() {
            print("ℹ️ Live Activity already active, skipping")
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


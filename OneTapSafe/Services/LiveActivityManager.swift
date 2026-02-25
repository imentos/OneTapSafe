//
//  LiveActivityManager.swift
//  OneTapSafe
//

import Foundation
import ActivityKit

@available(iOS 16.1, *)
final class LiveActivityManager {
    
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<CheckInActivityAttributes>?
    
    private init() {}
    
    // MARK: - Activity Management
    
    func startActivity(deadline: Date, userName: String = "You") {
        // End ALL existing activities first (including orphaned ones from previous sessions)
        Task {
            await endAllActivities()
            
            let authInfo = ActivityAuthorizationInfo()
            print("📊 Live Activity Authorization Status:")
            print("   - Enabled: \(authInfo.areActivitiesEnabled)")
            print("   - Frequent Pushes Enabled: \(authInfo.frequentPushesEnabled)")
            
            guard authInfo.areActivitiesEnabled else {
                print("⚠️ Live Activities not enabled")
                print("   → User needs to: Settings > OneTap OK > Enable Live Activities")
                print("   → Fallback: Local notifications will be used instead")
                return
            }
            
            let attributes = CheckInActivityAttributes(userName: userName)
            let contentState = CheckInActivityAttributes.ContentState(
                deadline: deadline,
                isOverdue: false
            )
            
            do {
                currentActivity = try Activity<CheckInActivityAttributes>.request(
                    attributes: attributes,
                    contentState: contentState,
                    pushType: nil
                )
                print("✅ Live Activity started successfully!")
                print("   - Activity ID: \(currentActivity?.id ?? "unknown")")
                print("   - Activity State: \(String(describing: currentActivity?.activityState))")
                print("   - Deadline: \(deadline)")
                print("👉 LOCK YOUR PHONE to see the Live Activity on your Lock Screen")
                print("   You can check in by tapping 'I'm OK' button directly from Lock Screen")
            } catch {
                print("❌ Failed to start Live Activity: \(error)")
                print("   - Error details: \(error.localizedDescription)")
                print("   → Fallback: Local notifications will be used instead")
            }
        }
    }
    
    func updateActivity(deadline: Date, isOverdue: Bool) {
        guard let activity = currentActivity else {
            print("⚠️ No active Live Activity to update")
            return
        }
        
        let contentState = CheckInActivityAttributes.ContentState(
            deadline: deadline,
            isOverdue: isOverdue
        )
        
        Task {
            await activity.update(using: contentState)
            print("✅ Live Activity updated - Overdue: \(isOverdue)")
        }
    }
    
    func endActivity() {
        Task {
            // End ALL activities, not just currentActivity
            // This ensures we clean up orphaned activities from previous sessions
            await endAllActivities()
        }
    }
    
    func hasActiveActivity() -> Bool {
        // Check if ANY activity exists, not just currentActivity
        // This catches orphaned activities from previous sessions
        let allActivities = Activity<CheckInActivityAttributes>.activities
        let hasActivity = !allActivities.isEmpty
        
        if hasActivity {
            print("ℹ️ Found \(allActivities.count) active Live Activity/Activities")
            // Update currentActivity reference if we don't have one
            if currentActivity == nil && !allActivities.isEmpty {
                currentActivity = allActivities.first
                print("ℹ️ Restored reference to existing Live Activity")
            }
        } else {
            print("ℹ️ No active Live Activities found")
        }
        
        return hasActivity
    }
    
    func endAllActivities() async {
        for activity in Activity<CheckInActivityAttributes>.activities {
            await activity.end(dismissalPolicy: .immediate)
        }
        currentActivity = nil
        print("✅ All Live Activities ended (\(Activity<CheckInActivityAttributes>.activities.count) total)")
    }
    
    // MARK: - Status
    
    var isActivityActive: Bool {
        currentActivity != nil && currentActivity?.activityState == .active
    }
}

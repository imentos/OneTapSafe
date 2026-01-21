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
        // End any existing activity first
        endActivity()
        
        let authInfo = ActivityAuthorizationInfo()
        print("📊 Live Activity Authorization Status:")
        print("   - Enabled: \(authInfo.areActivitiesEnabled)")
        print("   - Frequent Pushes Enabled: \(authInfo.frequentPushesEnabled)")
        
        guard authInfo.areActivitiesEnabled else {
            print("❌ Live Activities not enabled - Go to Settings > One Tap Safe > Enable Live Activities")
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
            print("✅ Live Activity started with deadline: \(deadline)")
            print("   - Activity ID: \(currentActivity?.id ?? "unknown")")
            print("   - Activity State: \(String(describing: currentActivity?.activityState))")
            print("👉 LOCK YOUR PHONE to see the Live Activity on lock screen")
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
            print("   - Error details: \(error.localizedDescription)")
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
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
            currentActivity = nil
            print("✅ Live Activity ended")
        }
    }
    
    func hasActiveActivity() -> Bool {
        guard let activity = currentActivity else {
            return false
        }
        
        // Check if activity is still active (not ended)
        let isActive = activity.activityState == .active
        print("ℹ️ Checking Live Activity status: \(isActive ? "Active" : "Not Active")")
        return isActive
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

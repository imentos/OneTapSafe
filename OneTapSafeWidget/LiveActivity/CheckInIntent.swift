//
//  CheckInIntent.swift
//  OneTapSafe
//

import Foundation
import AppIntents

struct CheckInIntent: AppIntent {
    static var title: LocalizedStringResource = "Check In"
    static var description = IntentDescription("Confirm you're safe")
    
    // Open app when intent runs - this is more reliable for Live Activities
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        print("🎯 CheckInIntent: Button tapped!")
        
        // Record check-in and end activity
        await MainActor.run {
            print("🎯 Recording check-in...")
            DataStore.shared.recordCheckIn(method: .liveActivity)
            print("🎯 Check-in recorded!")
        }
        
        // End Live Activity (with proper async/await)
        if #available(iOS 16.1, *) {
            print("🎯 Ending all Live Activities...")
            await LiveActivityManager.shared.endAllActivities()
            print("🎯 All activities ended!")
        }
        
        return .result()
    }
}

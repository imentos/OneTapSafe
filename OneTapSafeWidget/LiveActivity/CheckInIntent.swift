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
        print("🎯 CheckInIntent: Button tapped from Live Activity!")
        
        // Record check-in directly via DataStore (shared via App Groups)
        await MainActor.run {
            DataStore.shared.recordCheckIn(method: .liveActivity)
            print("✅ Check-in recorded via Live Activity!")
            
            // End the Live Activity immediately
            if #available(iOS 16.1, *) {
                LiveActivityManager.shared.endActivity()
                print("✅ Live Activity ended")
            }
        }
        
        // App will open automatically (openAppWhenRun = true) and handle:
        // - OneTapSafeApp.startLiveActivityIfNeeded() checks hasCheckedInToday()
        // - Cancels deadline notification if check-in is complete
        // This provides the emergency contact protection
        
        return .result()
    }
}

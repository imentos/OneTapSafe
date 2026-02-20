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
        // Widget extensions can't access main app's CheckInCoordinator
        await MainActor.run {
            DataStore.shared.recordCheckIn(method: .liveActivity)
            print("🎯 Check-in recorded! App will handle notification cancellation.")
        }
        
        // Note: Deadline notification cancellation happens when user opens the app
        // or when notification checks hasCheckedInToday() before delivery
        
        return .result()
    }
}

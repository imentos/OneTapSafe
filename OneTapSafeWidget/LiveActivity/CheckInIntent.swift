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
        
        // Use CheckInCoordinator to properly handle check-in
        // This ensures deadline notification gets cancelled
        await MainActor.run {
            CheckInCoordinator.shared.handleCheckIn(method: .liveActivity)
            print("✅ Check-in completed via coordinator!")
        }
        
        // App will open and verify cleanup
        
        return .result()
    }
}

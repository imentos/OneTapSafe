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
        
        // Use coordinator to properly handle check-in (cancels deadline notification)
        await MainActor.run {
            print("🎯 Handling check-in through coordinator...")
            CheckInCoordinator.shared.handleCheckIn(method: .liveActivity)
            print("🎯 Check-in completed!")
        }
        
        return .result()
    }
}

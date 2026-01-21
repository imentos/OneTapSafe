//
//  CheckIn.swift
//  OneTapSafe
//

import Foundation

struct CheckIn: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let method: CheckInMethod
    
    init(id: UUID = UUID(), timestamp: Date = Date(), method: CheckInMethod = .liveActivity) {
        self.id = id
        self.timestamp = timestamp
        self.method = method
    }
}

enum CheckInMethod: String, Codable {
    case liveActivity = "Live Activity"
    case notification = "Notification"
    case app = "In App"
    case siri = "Siri"
}

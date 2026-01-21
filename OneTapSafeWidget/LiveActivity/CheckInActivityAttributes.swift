//
//  CheckInActivityAttributes.swift
//  OneTapSafe
//

import Foundation
import ActivityKit
import SwiftUI

struct CheckInActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var deadline: Date
        var isOverdue: Bool
    }
    
    // Static properties that don't change
    var userName: String
}

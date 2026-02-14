//
//  Contact.swift
//  OneTapSafe
//

import Foundation

struct TrustedContact: Identifiable, Codable {
    let id: UUID
    var name: String
    var phoneNumber: String?
    var email: String
    var notificationMethod: NotificationMethod
    
    init(id: UUID = UUID(), name: String, phoneNumber: String? = nil, email: String, notificationMethod: NotificationMethod = .email) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.notificationMethod = notificationMethod
    }
}

enum NotificationMethod: String, Codable, CaseIterable {
    case sms = "Text Message"
    case email = "Email"
    case both = "Both"
}

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
    var consentStatus: ConsentStatus
    var verificationCode: String?
    var dateAdded: Date
    
    init(id: UUID = UUID(), name: String, phoneNumber: String? = nil, email: String, notificationMethod: NotificationMethod = .email, consentStatus: ConsentStatus = .pending, verificationCode: String? = nil, dateAdded: Date = Date()) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.notificationMethod = notificationMethod
        self.consentStatus = consentStatus
        self.verificationCode = verificationCode
        self.dateAdded = dateAdded
    }
    
    var isVerified: Bool {
        consentStatus == .verified
    }
    
    static func generateVerificationCode() -> String {
        String(format: "%06d", Int.random(in: 0...999999))
    }
}

enum ConsentStatus: String, Codable {
    case pending = "Pending Verification"
    case verified = "Verified"
}

enum NotificationMethod: String, Codable, CaseIterable {
    case sms = "Text Message"
    case email = "Email"
    case both = "Both"
}

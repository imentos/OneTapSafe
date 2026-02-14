//
//  ContactNotifier.swift
//  OneTapSafe
//

import Foundation
import MessageUI

final class ContactNotifier {
    
    static let shared = ContactNotifier()
    
    // Configuration for automated notifications
    private let automatedNotificationsEnabled = true
    private let emailServerURL = "https://onetapsafe-email-server-production.up.railway.app/api/send-alert"
    
    private init() {}
    
    // MARK: - Notify Contacts
    
    func notifyContacts(for missedCheckIn: Date) {
        let contacts = DataStore.shared.trustedContacts
        
        print("📞 Notifying contacts - Found \(contacts.count) contact(s)")
        
        guard !contacts.isEmpty else {
            print("⚠️ No contacts to notify")
            return
        }
        
        // Use automated server-based notifications if available
        if automatedNotificationsEnabled {
            sendAutomatedNotifications(contacts: contacts, missedCheckIn: missedCheckIn)
        } else {
            // Fallback to manual URL scheme (opens Messages/Mail apps)
            sendManualNotifications(contacts: contacts, missedCheckIn: missedCheckIn)
        }
    }
    
    // MARK: - Automated Notifications (Server-based)
    
    private func sendAutomatedNotifications(contacts: [TrustedContact], missedCheckIn: Date) {
        let userName = "OneTap OK User" // Could be customized in settings later
        
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        let missedTimeString = formatter.string(from: missedCheckIn)
        
        for contact in contacts {
            print("📞 Sending automated notification to: \(contact.name)")
            
            // Send emails (now always available since email is required)
            sendEmailNotification(
                to: contact.email,
                contactName: contact.name,
                userName: userName,
                missedCheckIn: missedTimeString
            )
            
            // For SMS, check if phone number is available
            if contact.notificationMethod == .sms || contact.notificationMethod == .both {
                if let phoneNumber = contact.phoneNumber, !phoneNumber.isEmpty {
                    sendSMS(to: contact, missedCheckIn: missedCheckIn)
                }
            }
        }
    }
    
    private func sendEmailNotification(to email: String, contactName: String, userName: String, missedCheckIn: String) {
        guard let url = URL(string: emailServerURL) else {
            print("❌ Invalid email server URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: String] = [
            "email": email,
            "contactName": contactName,
            "userName": userName,
            "missedCheckIn": missedCheckIn
        ]
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Failed to send email to \(contactName): \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("✅ Email sent successfully to \(contactName)")
                        DispatchQueue.main.async {
                            NotificationManager.shared.sendContactNotifiedAlert(contactName: contactName)
                        }
                    } else {
                        print("❌ Server error \(httpResponse.statusCode) sending email to \(contactName)")
                    }
                }
            }.resume()
        } catch {
            print("❌ Failed to encode email payload: \(error)")
        }
    }
    
    // MARK: - Manual Notifications (URL Schemes)
    
    private func sendManualNotifications(contacts: [TrustedContact], missedCheckIn: Date) {
        for contact in contacts {
            print("📞 Processing contact: \(contact.name) - Method: \(contact.notificationMethod.rawValue)")
            
            switch contact.notificationMethod {
            case .sms:
                if let phoneNumber = contact.phoneNumber, !phoneNumber.isEmpty {
                    sendSMS(to: contact, missedCheckIn: missedCheckIn)
                }
            case .email:
                sendEmail(to: contact, email: contact.email, missedCheckIn: missedCheckIn)
            case .both:
                if let phoneNumber = contact.phoneNumber, !phoneNumber.isEmpty {
                    sendSMS(to: contact, missedCheckIn: missedCheckIn)
                }
                sendEmail(to: contact, email: contact.email, missedCheckIn: missedCheckIn)
            }
            
            NotificationManager.shared.sendContactNotifiedAlert(contactName: contact.name)
        }
    }
    
    private func fallbackToManualNotifications() {
        print("⚠️ Falling back to manual notification method")
        let contacts = DataStore.shared.trustedContacts
        let missedCheckIn = DataStore.shared.lastCheckInDate ?? Date()
        sendManualNotifications(contacts: contacts, missedCheckIn: missedCheckIn)
    }
    
    // MARK: - SMS
    
    private func sendSMS(to contact: TrustedContact, missedCheckIn: Date) {
        guard let phoneNumber = contact.phoneNumber, !phoneNumber.isEmpty else {
            print("⚠️ No phone number for contact: \(contact.name)")
            return
        }
        
        let message = createAlertMessage(missedCheckIn: missedCheckIn)
        
        // Clean phone number (remove any formatting)
        let cleanPhone = phoneNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
        // Build SMS URL with proper encoding
        let urlString = "sms:\(cleanPhone)?body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        print("📱 Opening SMS URL: \(urlString)")
        
        if let url = URL(string: urlString) {
            #if os(iOS)
            DispatchQueue.main.async {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url) { success in
                        if success {
                            print("✅ SMS notification prepared for \(contact.name)")
                        } else {
                            print("❌ Failed to open Messages app")
                        }
                    }
                } else {
                    print("❌ Cannot open SMS URL - Messages app not available")
                }
            }
            #endif
        } else {
            print("❌ Invalid SMS URL")
        }
    }
    
    // MARK: - Email
    
    private func sendEmail(to contact: TrustedContact, email: String, missedCheckIn: Date) {
        // Note: This requires MFMailComposeViewController which needs UI integration
        // For now, we'll open Mail app with pre-filled content
        let subject = "⚠️ Safety Check-In Missed"
        let body = createAlertMessage(missedCheckIn: missedCheckIn)
        
        let mailto = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: mailto) {
            #if os(iOS)
            DispatchQueue.main.async {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                    print("✅ Email notification prepared for \(contact.name)")
                }
            }
            #endif
        }
    }
    
    // MARK: - Message Creation
    
    private func createAlertMessage(missedCheckIn: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return """
        ⚠️ SAFETY ALERT
        
        Your contact has not completed their daily safety check-in as of \(formatter.string(from: Date())).
        
        Last successful check-in: \(formatter.string(from: missedCheckIn))
        
        Please reach out to confirm they are safe.
        
        - Sent by OneTap OK
        """
    }
}

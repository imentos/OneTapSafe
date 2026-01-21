//
//  ContactNotifier.swift
//  OneTapSafe
//

import Foundation
import MessageUI

final class ContactNotifier {
    
    static let shared = ContactNotifier()
    
    // Configuration for automated notifications
    private let automatedNotificationsEnabled = false
    private let notificationWebhookURL = "https://your-server.com/api/notify" // TODO: Replace with actual server
    
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
        let message = createAlertMessage(missedCheckIn: missedCheckIn)
        
        // Prepare notification requests for all contacts
        var notificationRequests: [[String: Any]] = []
        
        for contact in contacts {
            print("📞 Preparing automated notification for: \(contact.name)")
            
            var request: [String: Any] = [
                "contactName": contact.name,
                "message": message,
                "timestamp": ISO8601DateFormatter().string(from: missedCheckIn)
            ]
            
            switch contact.notificationMethod {
            case .sms:
                request["type"] = "sms"
                request["phone"] = contact.phoneNumber
            case .email:
                request["type"] = "email"
                request["email"] = contact.email ?? ""
            case .both:
                // Send both SMS and email
                notificationRequests.append([
                    "contactName": contact.name,
                    "type": "sms",
                    "phone": contact.phoneNumber,
                    "message": message,
                    "timestamp": ISO8601DateFormatter().string(from: missedCheckIn)
                ])
                if let email = contact.email {
                    request["type"] = "email"
                    request["email"] = email
                }
            }
            
            notificationRequests.append(request)
        }
        
        // Send to server
        sendToServer(notificationRequests)
        
        // Notify user
        for contact in contacts {
            NotificationManager.shared.sendContactNotifiedAlert(contactName: contact.name)
        }
    }
    
    private func sendToServer(_ requests: [[String: Any]]) {
        guard let url = URL(string: notificationWebhookURL) else {
            print("❌ Invalid webhook URL")
            fallbackToManualNotifications()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "notifications": requests,
            "userId": UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Failed to send notifications: \(error.localizedDescription)")
                    self.fallbackToManualNotifications()
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("✅ Automated notifications sent successfully")
                    } else {
                        print("❌ Server error: \(httpResponse.statusCode)")
                        self.fallbackToManualNotifications()
                    }
                }
            }.resume()
        } catch {
            print("❌ Failed to encode notification payload: \(error)")
            fallbackToManualNotifications()
        }
    }
    
    // MARK: - Manual Notifications (URL Schemes)
    
    private func sendManualNotifications(contacts: [TrustedContact], missedCheckIn: Date) {
        for contact in contacts {
            print("📞 Processing contact: \(contact.name) - Method: \(contact.notificationMethod.rawValue)")
            
            switch contact.notificationMethod {
            case .sms:
                sendSMS(to: contact, missedCheckIn: missedCheckIn)
            case .email:
                if let email = contact.email {
                    sendEmail(to: contact, email: email, missedCheckIn: missedCheckIn)
                }
            case .both:
                sendSMS(to: contact, missedCheckIn: missedCheckIn)
                if let email = contact.email {
                    sendEmail(to: contact, email: email, missedCheckIn: missedCheckIn)
                }
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
        let message = createAlertMessage(missedCheckIn: missedCheckIn)
        
        // Clean phone number (remove any formatting)
        let cleanPhone = contact.phoneNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
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
        
        - Sent by One Tap Safe
        """
    }
}

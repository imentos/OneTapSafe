//
//  ContactNotifier.swift
//  OneTapSafe
//

import Foundation
import MessageUI

final class ContactNotifier {
    
    static let shared = ContactNotifier()
    
    // Configuration for Resend API
    private let resendAPIKey = "re_UqtXCbNP_KJc9zLe2pvyvpj14U6pwLtRv"  // Same key from ShowUpBooster
    
    private init() {}
    
    // MARK: - Notify Contacts
    
    func notifyContacts(for missedCheckIn: Date) {
        let allContacts = DataStore.shared.trustedContacts
        let contacts = allContacts.filter { $0.isVerified }
        
        print("📞 Notifying contacts - Found \(contacts.count) verified contact(s) out of \(allContacts.count) total")
        
        guard !contacts.isEmpty else {
            print("⚠️ No verified contacts to notify")
            return
        }
        
        let userName = DataStore.shared.userName
        
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        let missedTimeString = formatter.string(from: missedCheckIn)
        
        for contact in contacts {
            print("📞 Sending notification to: \(contact.name)")
            
            // Send email via Resend API
            Task {
                await sendEmailViaResend(
                    to: contact.email,
                    contactName: contact.name,
                    userName: userName,
                    missedCheckIn: missedTimeString
                )
            }
            
            // For SMS, check if phone number is available
            if contact.notificationMethod == .sms || contact.notificationMethod == .both {
                if let phoneNumber = contact.phoneNumber, !phoneNumber.isEmpty {
                    sendSMS(to: contact, missedCheckIn: missedCheckIn)
                }
            }
        }
    }
    
    // MARK: - Emergency Alert
    
    func sendEmergencyAlert() {
        let allContacts = DataStore.shared.trustedContacts
        let contacts = allContacts.filter { $0.isVerified }
        
        print("🚨 EMERGENCY: Sending alert to \(contacts.count) verified contact(s) out of \(allContacts.count) total")
        
        guard !contacts.isEmpty else {
            print("⚠️ No verified contacts to notify for emergency")
            return
        }
        
        let userName = DataStore.shared.userName
        
        for contact in contacts {
            print("🚨 Sending emergency alert to: \(contact.name)")
            
            // Send emergency email
            Task {
                await sendEmergencyEmailViaResend(
                    to: contact.email,
                    contactName: contact.name,
                    userName: userName
                )
            }
            
            // Send SMS if available
            if contact.notificationMethod == .sms || contact.notificationMethod == .both {
                if let phoneNumber = contact.phoneNumber, !phoneNumber.isEmpty {
                    sendEmergencySMS(to: contact)
                }
            }
        }
    }
    
    // MARK: - Resend API Email Sending
    
    private func sendEmailViaResend(to email: String, contactName: String, userName: String, missedCheckIn: String) async {
        print("📧 [OneTapOK] Starting email notification via Resend API...")
        
        guard let url = URL(string: "https://api.resend.com/emails") else {
            print("❌ [OneTapOK] Invalid Resend API URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(resendAPIKey)", forHTTPHeaderField: "Authorization")
        
        let emailSubject = "⚠️ \(userName) Missed Daily Check-In - OneTap OK"
        
        let emailPayload: [String: Any] = [
            "from": "OneTap OK <notifications@northpoleapps.online>",
            "to": [email],
            "subject": emailSubject,
            "html": """
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <h2 style="color: #d32f2f;">⚠️ Missed Check-In Alert</h2>
                    
                    <p>Hi <strong>\(contactName)</strong>,</p>
                    
                    <p>This is an automated safety alert from <strong>OneTap OK</strong>.</p>
                    
                    <div style="background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0;">
                        <strong>\(userName)</strong> has missed their daily safety check-in.
                    </div>
                    
                    <p><strong>Expected check-in:</strong> \(missedCheckIn)<br>
                    <strong>Current time:</strong> \(Date().formatted(date: .abbreviated, time: .shortened))</p>
                    
                    <p>This message was sent because you are listed as an emergency contact.</p>
                    
                    <p><strong>Please reach out to \(userName) to ensure they are safe.</strong></p>
                    
                    <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
                    
                    <p style="font-size: 12px; color: #666;">
                        OneTap OK - Automated Safety Check-In System<br>
                        Do not reply to this email.
                    </p>
                </div>
            """
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: emailPayload)
            
            print("📧 [OneTapOK] Sending email to Resend API...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
                print("📧 [OneTapOK] Resend API response status: \(httpResponse.statusCode)")
                print("📧 [OneTapOK] Resend API response body: \(responseBody)")
                
                if (200...299).contains(httpResponse.statusCode) {
                    print("✅ [OneTapOK] Email sent successfully to \(contactName)")
                    DispatchQueue.main.async {
                        NotificationManager.shared.sendContactNotifiedAlert(contactName: contactName)
                    }
                } else {
                    print("⚠️ [OneTapOK] Email notification failed with status \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("⚠️ [OneTapOK] Failed to send email notification: \(error.localizedDescription)")
        }
    }
    
    private func sendEmergencyEmailViaResend(to email: String, contactName: String, userName: String) async {
        print("📧 [OneTapOK] Sending EMERGENCY email via Resend API...")
        
        guard let url = URL(string: "https://api.resend.com/emails") else {
            print("❌ [OneTapOK] Invalid Resend API URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(resendAPIKey)", forHTTPHeaderField: "Authorization")
        
        let emailSubject = "🚨 EMERGENCY ALERT - \(userName) needs immediate help"
        
        let emailPayload: [String: Any] = [
            "from": "OneTap OK <notifications@northpoleapps.online>",
            "to": [email],
            "subject": emailSubject,
            "html": """
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 3px solid #d32f2f;">
                    <div style="background: #d32f2f; color: white; padding: 20px; text-align: center;">
                        <h1 style="margin: 0; font-size: 28px;">🚨 EMERGENCY ALERT</h1>
                    </div>
                    
                    <div style="padding: 30px;">
                        <p style="font-size: 16px;">Hi <strong>\(contactName)</strong>,</p>
                        
                        <div style="background: #ffebee; border-left: 6px solid #d32f2f; padding: 20px; margin: 20px 0;">
                            <p style="margin: 0; font-size: 18px; color: #d32f2f; font-weight: bold;">
                                \(userName) has triggered an EMERGENCY ALERT
                            </p>
                        </div>
                        
                        <p><strong>Alert time:</strong> \(Date().formatted(date: .abbreviated, time: .shortened))</p>
                        
                        <div style="background: #fff3cd; border: 2px solid #ff9800; padding: 20px; margin: 20px 0; text-align: center;">
                            <p style="margin: 0; font-size: 16px; font-weight: bold; color: #d32f2f;">
                                ⚠️ THIS IS AN URGENT REQUEST FOR HELP ⚠️
                            </p>
                        </div>
                        
                        <p style="font-size: 16px; font-weight: bold;">
                            Please reach out to \(userName) IMMEDIATELY to ensure they are safe.
                        </p>
                    </div>
                    
                    <div style="background: #f5f5f5; padding: 20px; text-align: center;">
                        <p style="font-size: 12px; color: #666; margin: 0;">
                            OneTap OK - Automated Safety Check-In System<br>
                            Do not reply to this email.
                        </p>
                    </div>
                </div>
            """
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: emailPayload)
            
            print("📧 [OneTapOK] Sending emergency email to Resend API...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
                print("📧 [OneTapOK] Resend API response status: \(httpResponse.statusCode)")
                print("📧 [OneTapOK] Resend API response body: \(responseBody)")
                
                if (200...299).contains(httpResponse.statusCode) {
                    print("✅ [OneTapOK] Emergency email sent successfully to \(contactName)")
                    DispatchQueue.main.async {
                        NotificationManager.shared.sendContactNotifiedAlert(contactName: contactName)
                    }
                } else {
                    print("⚠️ [OneTapOK] Emergency email failed with status \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("⚠️ [OneTapOK] Failed to send emergency email: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Consent Request Email
    
    func sendConsentRequest(to email: String, contactName: String, verificationCode: String, userName: String) async {
        print("📧 [OneTapOK] Sending consent request email via Resend API...")
        
        guard let url = URL(string: "https://api.resend.com/emails") else {
            print("❌ [OneTapOK] Invalid Resend API URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(resendAPIKey)", forHTTPHeaderField: "Authorization")
        
        let emailSubject = "OneTap OK: Consent Request - Verify Your Contact"
        
        let emailPayload: [String: Any] = [
            "from": "OneTap OK <notifications@northpoleapps.online>",
            "to": [email],
            "subject": emailSubject,
            "html": """
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; background: white;">
                    <div style="background: linear-gradient(135deg, #34C759 0%, #30D158 100%); padding: 30px; text-align: center;">
                        <h1 style="color: white; margin: 0; font-size: 28px;">OneTap OK</h1>
                        <p style="color: white; margin: 10px 0 0 0; font-size: 16px;">Emergency Contact Consent Request</p>
                    </div>
                    
                    <div style="padding: 30px; color: #333;">
                        <p>Hi \(contactName),</p>
                        
                        <p><strong>\(userName)</strong> is adding you as an emergency contact in the OneTap OK app. This app helps people stay safe with daily safety check-ins.</p>
                        
                        <div style="background: #f8f9fa; border-left: 4px solid #34C759; padding: 20px; margin: 20px 0;">
                            <p style="margin: 0 0 10px 0; font-weight: bold; color: #34C759;">Your Verification Code:</p>
                            <p style="margin: 0; font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #333; font-family: 'Courier New', monospace;">
                                \(verificationCode)
                            </p>
                        </div>
                        
                        <h3 style="color: #34C759;">What This Means:</h3>
                        <p>If you consent to be an emergency contact for \(userName), you will receive notifications if:</p>
                        <ul style="line-height: 1.8;">
                            <li>\(userName) misses their daily safety check-in</li>
                            <li>\(userName) triggers an emergency alert</li>
                        </ul>
                        
                        <h3 style="color: #34C759;">How to Consent:</h3>
                        <p>If you agree to be an emergency contact for \(userName), <strong>share this verification code (\(verificationCode))</strong> with them. They will enter it in the app to complete the verification.</p>
                        
                        <div style="background: #fff3cd; border: 2px solid #ffc107; padding: 15px; margin: 20px 0; border-radius: 8px;">
                            <p style="margin: 0; font-size: 14px; color: #856404;">
                                <strong>⚠️ Important:</strong> Only share this code if you consent to receive emergency notifications. If you don't want to be an emergency contact, simply ignore this email and do not share the code.
                            </p>
                        </div>
                        
                        <p style="font-size: 14px; color: #666;">
                            You can always ask to be removed as an emergency contact at any time.
                        </p>
                    </div>
                    
                    <div style="background: #f5f5f5; padding: 20px; text-align: center;">
                        <p style="font-size: 12px; color: #666; margin: 0;">
                            OneTap OK - Automated Safety Check-In System<br>
                            Do not reply to this email.
                        </p>
                    </div>
                </div>
            """
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: emailPayload)
            
            print("📧 [OneTapOK] Sending consent request to Resend API...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
                print("📧 [OneTapOK] Resend API response status: \(httpResponse.statusCode)")
                print("📧 [OneTapOK] Resend API response body: \(responseBody)")
                
                if (200...299).contains(httpResponse.statusCode) {
                    print("✅ [OneTapOK] Consent request sent successfully to \(contactName)")
                } else {
                    print("⚠️ [OneTapOK] Consent request failed with status \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("⚠️ [OneTapOK] Failed to send consent request: \(error.localizedDescription)")
        }
    }
    
    // MARK: - SMS
    
    private func sendEmergencySMS(to contact: TrustedContact) {
        guard let phoneNumber = contact.phoneNumber, !phoneNumber.isEmpty else {
            print("⚠️ No phone number for contact: \(contact.name)")
            return
        }
        
        let message = """
        🚨 EMERGENCY ALERT
        
        Your contact has triggered an emergency alert from OneTap OK at \(Date().formatted(date: .abbreviated, time: .shortened)).
        
        Please reach out IMMEDIATELY.
        
        - Sent by OneTap OK
        """
        
        // Clean phone number (remove any formatting)
        let cleanPhone = phoneNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
        // Build SMS URL with proper encoding
        let urlString = "sms:\(cleanPhone)?body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        print("📱 Opening SMS URL for emergency: \(urlString)")
        
        if let url = URL(string: urlString) {
            #if os(iOS)
            DispatchQueue.main.async {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url) { success in
                        if success {
                            print("✅ Emergency SMS prepared for \(contact.name)")
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

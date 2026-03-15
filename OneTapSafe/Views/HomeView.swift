//
//  HomeView.swift
//  OneTapSafe
//

import SwiftUI
import ActivityKit

struct HomeView: View {
    @StateObject private var dataStore = DataStore.shared
    @State private var showingCheckInSuccess = false
    @State private var showLiveActivityBanner = false
    @State private var showingEmergencyConfirmation = false
    @State private var showingEmergencySuccess = false
    @State private var showNamePrompt = false
    @State private var tempUserName = ""
    
    var hasCheckedInToday: Bool {
        dataStore.hasCheckedInToday()
    }
    
    var hasVerifiedContacts: Bool {
        dataStore.trustedContacts.contains { $0.isVerified }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Live Activity Setup Banner (if not enabled)
                    if #available(iOS 16.1, *), showLiveActivityBanner {
                        LiveActivitySetupBanner()
                    }
                    
                    // Status Card
                    StatusCard(hasCheckedIn: hasCheckedInToday)
                    
                    // Check-In Button
                    if !hasCheckedInToday {
                        CheckInButton {
                            checkIn()
                        }
                    }
                    
                    // Quick Info
                    QuickInfoSection()
                    
                    // Emergency Alert Button
                    if hasVerifiedContacts {
                        EmergencyAlertButton {
                            checkUserNameAndShowEmergencyConfirmation()
                        }
                    }
                    
                    // Contact Summary
                    ContactSummaryCard()
                }
                .padding()
            }
            .navigationTitle("OneTap OK")
            .alert("Check-In Recorded", isPresented: $showingCheckInSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your safety check-in has been recorded. See you tomorrow!")
            }
            .alert("Send Emergency Alert?", isPresented: $showingEmergencyConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Send Alert", role: .destructive) {
                    sendEmergencyAlert()
                }
            } message: {
                Text("This will immediately notify all your emergency contacts. Only use this if you need urgent help.")
            }
            .alert("Emergency Alert Sent", isPresented: $showingEmergencySuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your emergency contacts have been notified and will reach out to you immediately.")
            }
            .alert("Enter Your Name", isPresented: $showNamePrompt) {
                TextField("Your name", text: $tempUserName)
                Button("Cancel", role: .cancel) {
                    tempUserName = ""
                }
                Button("Save & Continue") {
                    if !tempUserName.trimmingCharacters(in: .whitespaces).isEmpty {
                        dataStore.updateUserName(tempUserName.trimmingCharacters(in: .whitespaces))
                        showingEmergencyConfirmation = true
                    }
                    tempUserName = ""
                }
            } message: {
                Text("Your name will appear in emergency alerts sent to your contacts. This helps them know who needs help.")
            }
            .onAppear {
                checkLiveActivityStatus()
                FirebaseManager.shared.logHomeViewed()
            }
        }
    }
    
    @available(iOS 16.1, *)
    private func checkLiveActivityStatus() {
        let authInfo = ActivityAuthorizationInfo()
        showLiveActivityBanner = !authInfo.areActivitiesEnabled
    }
    
    private func checkIn() {
        CheckInCoordinator.shared.handleCheckIn(method: .app)
        showingCheckInSuccess = true
    }
    
    private func checkUserNameAndShowEmergencyConfirmation() {
        if !dataStore.isUserNameValid() {
            tempUserName = dataStore.userName
            showNamePrompt = true
        } else {
            showingEmergencyConfirmation = true
        }
    }
    
    private func sendEmergencyAlert() {
        ContactNotifier.shared.sendEmergencyAlert()
        showingEmergencySuccess = true
        FirebaseManager.shared.logEvent(name: "emergency_alert_sent")
    }
}

// MARK: - Live Activity Setup Banner

@available(iOS 16.1, *)
struct LiveActivitySetupBanner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Live Activities")
                        .font(.headline)
                    Text("Check in directly from your Lock Screen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(8)
            }
            
            Text("Go to Settings > OneTap OK > Enable Live Activities")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Status Card

struct StatusCard: View {
    let hasCheckedIn: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasCheckedIn ? "checkmark.shield.fill" : "shield.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(hasCheckedIn ? .green : .orange)
            
            Text(hasCheckedIn ? "You're All Set!" : "Check-In Needed")
                .font(.title2)
                .bold()
            
            Text(hasCheckedIn ? "You've checked in today" : "Tap below to confirm you're safe")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(hasCheckedIn ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        )
    }
}

// MARK: - Check-In Button

struct CheckInButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "hand.thumbsup.fill")
                    .font(.title3)
                Text("I'm OK")
                    .font(.title3)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(16)
        }
    }
}

// MARK: - Emergency Alert Button

struct EmergencyAlertButton: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: action) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                    Text("Emergency Alert")
                        .font(.title3)
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            
            Text("Sends immediate alert to all emergency contacts")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Quick Info

struct QuickInfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How It Works")
                .font(.headline)
            
            InfoRow(icon: "lock.shield.fill", text: "Check in daily from your Lock Screen")
            InfoRow(icon: "bell.fill", text: "Get reminded at your preferred time")
            InfoRow(icon: "person.2.fill", text: "Contacts notified if you miss check-in")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Contact Summary

struct ContactSummaryCard: View {
    @StateObject private var dataStore = DataStore.shared
    
    var verifiedContacts: [TrustedContact] {
        dataStore.trustedContacts.filter { $0.isVerified }
    }
    
    var pendingContacts: [TrustedContact] {
        dataStore.trustedContacts.filter { !$0.isVerified }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Emergency Contacts")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    ContactsView()
                } label: {
                    Text("Manage")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
            
            if dataStore.trustedContacts.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("No contacts added yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                // Show verified contacts
                if !verifiedContacts.isEmpty {
                    ForEach(verifiedContacts.prefix(3)) { contact in
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text(contact.name)
                                .font(.subheadline)
                            Spacer()
                            Text(contact.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                // Show pending contacts warning
                if !pendingContacts.isEmpty {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(pendingContacts.count) contact\(pendingContacts.count == 1 ? "" : "s") pending verification")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("Tap Manage to verify")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if dataStore.trustedContacts.count > 3 {
                    Text("+\(dataStore.trustedContacts.count - 3) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    HomeView()
}

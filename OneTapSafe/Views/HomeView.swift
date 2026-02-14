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
    
    var hasCheckedInToday: Bool {
        dataStore.hasCheckedInToday()
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
            .onAppear {
                checkLiveActivityStatus()
            }
        }
    }
    
    @available(iOS 16.1, *)
    private func checkLiveActivityStatus() {
        let authInfo = ActivityAuthorizationInfo()
        showLiveActivityBanner = !authInfo.areActivitiesEnabled
    }
    
    private func checkIn() {
        dataStore.recordCheckIn(method: .app)
        showingCheckInSuccess = true
        
        // End Live Activity if active
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.endActivity()
        }
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
                ForEach(dataStore.trustedContacts.prefix(3)) { contact in
                    HStack {
                        Image(systemName: "person.circle.fill")
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

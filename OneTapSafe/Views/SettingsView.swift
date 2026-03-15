//
//  SettingsView.swift
//  OneTapSafe
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingResetAlert = false
    @State private var showPaywall = false
    @State private var versionTapCount = 0
    @State private var showDebugSection = false
    @State private var editedUserName = ""
    @State private var isEditingName = false
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Pro Status / Upgrade Section - DISABLED FOR NOW
                // TODO: Re-enable when ready to monetize
                /*
                if subscriptionManager.isPro {
                    Section {
                        HStack {
                            Image(systemName: "star.circle.fill")
                                .foregroundStyle(.green.gradient)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("OneTap OK Pro")
                                    .font(.headline)
                                Text("You have access to all premium features")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    Section {
                        Button(action: { showPaywall = true }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.green)
                                        Text("Upgrade to Pro")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }
                                    Text("Unlimited contacts & premium features")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                */
                                Section(\"Your Profile\") {
                    HStack {
                        Text(\"Your Name\")
                        Spacer()
                        Text(dataStore.userName)
                            .foregroundColor(.secondary)
                        Button(action: {
                            editedUserName = dataStore.userName
                            isEditingName = true
                        }) {
                            Text(\"Edit\")
                                .font(.subheadline)
                        }
                    }
                    
                    Text(\"This name will appear in emergency alerts sent to your contacts\")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                                Section("Daily Reminder") {
                    Toggle("Enable Reminder", isOn: Binding(
                        get: { dataStore.reminderEnabled },
                        set: { enabled in
                            dataStore.toggleReminder(enabled)
                            if enabled {
                                Task {
                                    await NotificationManager.shared.requestAuthorization()
                                    NotificationManager.shared.scheduleDailyReminder(at: dataStore.dailyReminderTime)
                                }
                            } else {
                                NotificationManager.shared.cancelDailyReminder()
                            }
                        }
                    ))
                    
                    if dataStore.reminderEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: Binding(
                                get: { dataStore.dailyReminderTime },
                                set: { time in
                                    dataStore.updateReminderTime(time)
                                    NotificationManager.shared.scheduleDailyReminder(at: time)
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
                
                if showDebugSection {
                    Section("Testing") {
                        if #available(iOS 16.1, *) {
                            Button {
                                testLiveActivity()
                            } label: {
                                Label("Test Live Activity", systemImage: "play.circle.fill")
                            }
                        } else {
                            Text("Live Activities require iOS 16.1+")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Button {
                            testNotification()
                        } label: {
                            Label("Test Notification (5 sec)", systemImage: "bell.fill")
                        }
                        
                        Button {
                            testDeadlineFlow()
                        } label: {
                            Label("Test Deadline Flow (10 sec)", systemImage: "timer")
                        }
                        
                        Button(role: .destructive) {
                            testMissedCheckIn()
                        } label: {
                            Label("Test Missed Check-In", systemImage: "exclamationmark.triangle.fill")
                        }
                        
                        Button {
                            clearTodayCheckIn()
                        } label: {
                            Label("Clear Today's Check-In", systemImage: "arrow.counterclockwise")
                        }
                    }
                }
                
                Section("About") {
                    Button(action: handleVersionTap) {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(appVersion)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Link("Privacy Policy", destination: URL(string: "https://amazing-grade-53d.notion.site/Privacy-Policy-for-One-Tap-OK-2f041a36ce8d80408074e2de77426830")!)
                }
                
                if showDebugSection {
                    Section {
                        Button(role: .destructive) {
                            showingResetAlert = true
                        } label: {
                            Text("Reset All Data")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    dataStore.resetAllData()
                }
            } message: {
                Text("This will delete all check-in history and contacts. This action cannot be undone.")
            }
            .alert("Edit Your Name", isPresented: $isEditingName) {
                TextField("Name", text: $editedUserName)
                Button("Cancel", role: .cancel) {
                    editedUserName = ""
                }
                Button("Save") {
                    if !editedUserName.trimmingCharacters(in: .whitespaces).isEmpty {
                        dataStore.updateUserName(editedUserName.trimmingCharacters(in: .whitespaces))
                    }
                    editedUserName = ""
                }
            } message: {
                Text("Enter your name as you'd like it to appear in emergency alerts")
            }
        }
    }
    
    private func handleVersionTap() {
        versionTapCount += 1
        
        if versionTapCount >= 7 {
            withAnimation {
                showDebugSection = true
            }
            versionTapCount = 0
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            print("🔓 Debug mode unlocked!")
        }
    }
    
    @available(iOS 16.1, *)
    private func testLiveActivity() {
        let deadline = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        LiveActivityManager.shared.startActivity(deadline: deadline, userName: "Test User")
    }
    
    private func testNotification() {
        NotificationManager.shared.sendTestReminder()
    }
    
    private func testMissedCheckIn() {
        print("🧪 Testing missed check-in flow...")
        
        // Reset notification date for testing
        DataStore.shared.lastNotificationDate = nil
        UserDefaults.standard.removeObject(forKey: "lastNotificationDate")
        
        // Use last check-in date or yesterday if none exists
        let lastCheckIn = DataStore.shared.lastCheckInDate ?? Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        
        // Trigger missed check-in notification with forceTest flag
        CheckInCoordinator.shared.checkMissedCheckInStatus(forceTest: true)
        
        print("🧪 Check your email for notifications from emergency contacts")
    }
    
    private func testDeadlineFlow() {
        print("\n🧪 ========== TEST DEADLINE FLOW START ==========")
        print("🧪 Current time: \(Date())")
        
        // Clear today's check-in
        DataStore.shared.lastCheckInDate = nil
        UserDefaults.standard.removeObject(forKey: "lastCheckInDate")
        print("🧪 Cleared today's check-in")
        
        // Schedule deadline notification for 10 seconds from now
        let deadline = Calendar.current.date(byAdding: .second, value: 10, to: Date())!
        print("🧪 Scheduling deadline for: \(deadline)")
        NotificationManager.shared.scheduleTestDeadlineNotification(for: deadline)
        
        print("🧪 ========================================")
        print("🧪 NEXT STEP: Go to Home tab and tap 'Check In'")
        print("🧪 Watch the console for cancellation logs")
        print("🧪 If notification still appears after 10 seconds, there's a bug")
        print("🧪 ========================================\n")
    }
    
    private func clearTodayCheckIn() {
        print("🧪 Clearing today's check-in...")
        
        DataStore.shared.lastCheckInDate = nil
        UserDefaults.standard.removeObject(forKey: "lastCheckInDate")
        
        // Also end any active Live Activity
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.endActivity()
        }
        
        print("✅ Today's check-in cleared. You can now check in again.")
    }
}

#Preview {
    SettingsView()
}

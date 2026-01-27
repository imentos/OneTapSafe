//
//  SettingsView.swift
//  OneTapSafe
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var dataStore = DataStore.shared
    @State private var showingResetAlert = false
    @State private var versionTapCount = 0
    @State private var showDebugSection = false
    
    var body: some View {
        NavigationStack {
            Form {
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
                        
                        Button(role: .destructive) {
                            testMissedCheckIn()
                        } label: {
                            Label("Test Missed Check-In", systemImage: "exclamationmark.triangle.fill")
                        }
                    }
                }
                
                Section("About") {
                    Button(action: handleVersionTap) {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
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
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    dataStore.resetAllData()
                }
            } message: {
                Text("This will delete all check-in history and contacts. This action cannot be undone.")
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
        
        // Trigger missed check-in notification
        CheckInCoordinator.shared.handleMissedCheckIn()
        
        print("🧪 Check your Messages app for SMS from emergency contacts")
    }
}

#Preview {
    SettingsView()
}

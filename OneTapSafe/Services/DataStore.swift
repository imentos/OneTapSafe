//
//  DataStore.swift
//  OneTapSafe
//

import Foundation
import Combine

/// Local-first data storage using UserDefaults
final class DataStore: ObservableObject {
    
    static let shared = DataStore()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    
    private enum Keys {
        static let checkInHistory = "checkInHistory"
        static let trustedContacts = "trustedContacts"
        static let dailyReminderTime = "dailyReminderTime"
        static let lastCheckInDate = "lastCheckInDate"
        static let reminderEnabled = "reminderEnabled"
        static let lastNotificationDate = "lastNotificationDate"
    }
    
    // MARK: - Published Properties
    
    @Published var checkInHistory: [CheckIn] = []
    @Published var trustedContacts: [TrustedContact] = []
    @Published var dailyReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @Published var lastCheckInDate: Date?
    @Published var reminderEnabled: Bool = true
    @Published var lastNotificationDate: Date?
    
    // MARK: - Initialization
    
    private init() {
        loadData()
    }
    
    // MARK: - Data Management
    
    private func loadData() {
        // Load check-in history
        if let data = defaults.data(forKey: Keys.checkInHistory),
           let history = try? JSONDecoder().decode([CheckIn].self, from: data) {
            checkInHistory = history
        }
        
        // Load trusted contacts
        if let data = defaults.data(forKey: Keys.trustedContacts),
           let contacts = try? JSONDecoder().decode([TrustedContact].self, from: data) {
            trustedContacts = contacts
        }
        
        // Load reminder time
        if let timeInterval = defaults.object(forKey: Keys.dailyReminderTime) as? TimeInterval {
            dailyReminderTime = Date(timeIntervalSince1970: timeInterval)
        }
        
        // Load last check-in date
        if let timeInterval = defaults.object(forKey: Keys.lastCheckInDate) as? TimeInterval {
            lastCheckInDate = Date(timeIntervalSince1970: timeInterval)
        }
        
        // Load reminder enabled
        reminderEnabled = defaults.bool(forKey: Keys.reminderEnabled)
        if defaults.object(forKey: Keys.reminderEnabled) == nil {
            reminderEnabled = true // Default to enabled
        }
        
        // Load last notification date
        if let timeInterval = defaults.object(forKey: Keys.lastNotificationDate) as? TimeInterval {
            lastNotificationDate = Date(timeIntervalSince1970: timeInterval)
        }
    }
    
    // MARK: - Check-In
    
    func recordCheckIn(method: CheckInMethod = .app) {
        let checkIn = CheckIn(timestamp: Date(), method: method)
        checkInHistory.insert(checkIn, at: 0) // Most recent first
        
        // Keep only last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        checkInHistory = checkInHistory.filter { $0.timestamp > thirtyDaysAgo }
        
        lastCheckInDate = Date()
        lastNotificationDate = nil // Reset notification flag when checking in
        
        saveCheckInHistory()
        saveLastCheckInDate()
        defaults.removeObject(forKey: Keys.lastNotificationDate)
    }
    
    func getRecentCheckIns(days: Int = 7) -> [CheckIn] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return checkInHistory.filter { $0.timestamp > startDate }
    }
    
    func hasCheckedInToday() -> Bool {
        guard let lastCheckIn = lastCheckInDate else { return false }
        return Calendar.current.isDateInToday(lastCheckIn)
    }
    
    func hasNotifiedContactsToday() -> Bool {
        guard let lastNotification = lastNotificationDate else { return false }
        return Calendar.current.isDateInToday(lastNotification)
    }
    
    func markContactsNotified() {
        lastNotificationDate = Date()
        defaults.set(lastNotificationDate?.timeIntervalSince1970, forKey: Keys.lastNotificationDate)
    }
    
    // MARK: - Contacts
    
    func addContact(_ contact: TrustedContact) {
        trustedContacts.append(contact)
        saveContacts()
        
        // Log analytics event
        FirebaseManager.shared.logContactAdded(method: contact.method, totalContacts: trustedContacts.count)
    }
    
    func updateContact(_ contact: TrustedContact) {
        if let index = trustedContacts.firstIndex(where: { $0.id == contact.id }) {
            trustedContacts[index] = contact
            saveContacts()
        }
    }
    
    func deleteContact(_ contact: TrustedContact) {
        trustedContacts.removeAll { $0.id == contact.id }
        saveContacts()
        
        // Log analytics event
        FirebaseManager.shared.logContactRemoved(method: contact.method, totalContacts: trustedContacts.count)
    }
    
    // MARK: - Settings
    
    func updateReminderTime(_ time: Date) {
        dailyReminderTime = time
        defaults.set(time.timeIntervalSince1970, forKey: Keys.dailyReminderTime)
        
        // Log analytics event
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        FirebaseManager.shared.logReminderTimeChanged(hour: components.hour ?? 9, minute: components.minute ?? 0)
    }
    
    func toggleReminder(_ enabled: Bool) {
        reminderEnabled = enabled
        defaults.set(enabled, forKey: Keys.reminderEnabled)
    }
    
    // MARK: - Persistence
    
    private func saveCheckInHistory() {
        if let data = try? JSONEncoder().encode(checkInHistory) {
            defaults.set(data, forKey: Keys.checkInHistory)
        }
    }
    
    private func saveContacts() {
        if let data = try? JSONEncoder().encode(trustedContacts) {
            defaults.set(data, forKey: Keys.trustedContacts)
        }
    }
    
    private func saveLastCheckInDate() {
        if let date = lastCheckInDate {
            defaults.set(date.timeIntervalSince1970, forKey: Keys.lastCheckInDate)
        }
    }
    
    // MARK: - Debug
    
    func resetAllData() {
        checkInHistory = []
        trustedContacts = []
        lastCheckInDate = nil
        
        defaults.removeObject(forKey: Keys.checkInHistory)
        defaults.removeObject(forKey: Keys.trustedContacts)
        defaults.removeObject(forKey: Keys.lastCheckInDate)
    }
}

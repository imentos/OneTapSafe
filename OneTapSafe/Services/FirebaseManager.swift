//
//  FirebaseManager.swift
//  OneTap OK
//
//  Analytics tracking manager for Firebase Analytics
//

import Foundation
import FirebaseAnalytics

class FirebaseManager {
    static let shared = FirebaseManager()
    private init() {}
    
    // MARK: - Analytics Events
    
    /// Log app launch event
    func logAppLaunch() {
        Analytics.logEvent("app_launch", parameters: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    /// Log when user completes check-in
    func logCheckIn(method: CheckInMethod, hasContacts: Bool) {
        Analytics.logEvent("check_in_completed", parameters: [
            "method": method.rawValue,
            "has_contacts": hasContacts,
            "timestamp": Date().timeIntervalSince1970
        ])
        print("📊 Analytics: Check-in completed via \(method.rawValue)")
    }
    
    /// Log when user misses check-in
    func logMissedCheckIn(hoursLate: Int, contactsNotified: Int) {
        Analytics.logEvent("missed_check_in", parameters: [
            "hours_late": hoursLate,
            "contacts_notified": contactsNotified,
            "timestamp": Date().timeIntervalSince1970
        ])
        print("📊 Analytics: Missed check-in (\(hoursLate) hours late)")
    }
    
    /// Log when emergency contact is added
    func logContactAdded(method: NotificationMethod, totalContacts: Int) {
        Analytics.logEvent("contact_added", parameters: [
            "notification_method": method.rawValue,
            "total_contacts": totalContacts
        ])
        print("📊 Analytics: Contact added (\(method.rawValue))")
    }
    
    /// Log when emergency contact is removed
    func logContactRemoved(method: NotificationMethod, totalContacts: Int) {
        Analytics.logEvent("contact_removed", parameters: [
            "notification_method": method.rawValue,
            "total_contacts": totalContacts
        ])
    }
    
    /// Log when reminder time is changed
    func logReminderTimeChanged(hour: Int, minute: Int) {
        Analytics.logEvent("reminder_time_changed", parameters: [
            "hour": hour,
            "minute": minute
        ])
        print("📊 Analytics: Reminder time changed to \(hour):\(minute)")
    }
    
    /// Log when Live Activity is started
    func logLiveActivityStarted() {
        Analytics.logEvent("live_activity_started", parameters: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    /// Log when Live Activity is dismissed
    func logLiveActivityDismissed(method: String) {
        Analytics.logEvent("live_activity_dismissed", parameters: [
            "method": method  // "check_in", "manual", "expired"
        ])
    }
    
    /// Log notification permission status
    func logNotificationPermission(granted: Bool) {
        Analytics.logEvent("notification_permission", parameters: [
            "granted": granted
        ])
    }
    
    /// Log settings screen view
    func logSettingsViewed() {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: "settings",
            AnalyticsParameterScreenClass: "SettingsView"
        ])
    }
    
    /// Log home screen view
    func logHomeViewed() {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: "home",
            AnalyticsParameterScreenClass: "HomeView"
        ])
    }
    
    /// Log history screen view
    func logHistoryViewed() {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: "history",
            AnalyticsParameterScreenClass: "HistoryView"
        ])
    }
    
    /// Generic log event method for custom events
    func logEvent(name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
        print("📊 Analytics: \(name)")
    }
    
    // MARK: - User Properties
    
    /// Set user properties for segmentation
    func setUserProperties(contactCount: Int, notificationsEnabled: Bool) {
        Analytics.setUserProperty("\(contactCount)", forName: "contact_count")
        Analytics.setUserProperty(notificationsEnabled ? "enabled" : "disabled", forName: "notifications_status")
    }
    
    /// Update contact count property
    func updateContactCount(_ count: Int) {
        Analytics.setUserProperty("\(count)", forName: "contact_count")
    }
}



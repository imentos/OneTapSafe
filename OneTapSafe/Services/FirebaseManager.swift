//
//  FirebaseManager.swift
//  OneTap OK
//
//  Centralized Firebase service manager for analytics, crashlytics, and remote config
//

import Foundation
import Firebase
import FirebaseAnalytics
import FirebaseCrashlytics

/// Centralized Firebase manager for analytics and crash reporting
final class FirebaseManager {
    
    static let shared = FirebaseManager()
    
    private init() {}
    
    // MARK: - Configuration
    
    func configure() {
        #if DEBUG
        // Enable debug logging in development
        FirebaseConfiguration.shared.setLoggerLevel(.debug)
        #endif
        
        FirebaseApp.configure()
        print("🔥 Firebase configured successfully")
    }
    
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
    func logContactAdded(method: ContactMethod, totalContacts: Int) {
        Analytics.logEvent("contact_added", parameters: [
            "method": method.rawValue,
            "total_contacts": totalContacts
        ])
        print("📊 Analytics: Contact added (\(method.rawValue))")
    }
    
    /// Log when emergency contact is removed
    func logContactRemoved(method: ContactMethod, totalContacts: Int) {
        Analytics.logEvent("contact_removed", parameters: [
            "method": method.rawValue,
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
    
    // MARK: - Crashlytics
    
    /// Log non-fatal error
    func logError(_ error: Error, context: String) {
        let nsError = error as NSError
        let userInfo = nsError.userInfo.merging(["context": context]) { _, new in new }
        let enhancedError = NSError(domain: nsError.domain, code: nsError.code, userInfo: userInfo)
        
        Crashlytics.crashlytics().record(error: enhancedError)
        print("⚠️ Crashlytics: Error logged - \(context): \(error.localizedDescription)")
    }
    
    /// Log custom message for debugging crashes
    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
    
    /// Set custom key for crash context
    func setCustomKey(_ key: String, value: Any) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
    
    /// Set user identifier (use anonymized ID, not PII)
    func setUserIdentifier(_ identifier: String) {
        Crashlytics.crashlytics().setUserID(identifier)
        Analytics.setUserID(identifier)
    }
    
    // MARK: - Remote Config (Future)
    
    // TODO: Add Remote Config methods when needed
    /*
    func fetchRemoteConfig(completion: @escaping (Bool) -> Void) {
        let remoteConfig = RemoteConfig.remoteConfig()
        remoteConfig.fetch(withExpirationDuration: 3600) { status, error in
            if status == .success {
                remoteConfig.activate()
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func getGracePeriodHours() -> Int {
        return RemoteConfig.remoteConfig()["grace_period_hours"].numberValue.intValue
    }
    
    func shouldShowPaywall() -> Bool {
        return RemoteConfig.remoteConfig()["show_paywall"].boolValue
    }
    */
}

// MARK: - Contact Method Extension

extension ContactMethod {
    var rawValue: String {
        switch self {
        case .sms:
            return "sms"
        case .email:
            return "email"
        case .call:
            return "call"
        }
    }
}

//
//  FirebaseManager.swift
//  OneTap OK
//
//  Centralized Firebase service manager for analytics, crashlytics, and remote config
//

import Foundation

#if canImport(Firebase)
import Firebase
import FirebaseAnalytics
import FirebaseCrashlytics
#endif

/// Centralized Firebase manager for analytics and crash reporting
final class FirebaseManager {
    
    static let shared = FirebaseManager()
    
    private init() {}
    
    // MARK: - Configuration
    
    func configure() {
        #if canImport(Firebase)
        #if DEBUG
        // Enable debug logging in development
        FirebaseConfiguration.shared.setLoggerLevel(.debug)
        #endif
        
        FirebaseApp.configure()
        print("🔥 Firebase configured successfully")
        #else
        print("⚠️ Firebase SDK not installed - analytics disabled")
        print("   See FIREBASE_SETUP.md for setup instructions")
        #endif
    }
    
    // MARK: - Analytics Events
    
    /// Log app launch event
    func logAppLaunch() {
        #if canImport(Firebase)
        Analytics.logEvent("app_launch", parameters: [
            "timestamp": Date().timeIntervalSince1970
        ])
        #endif
    }
    
    /// Log when user completes check-in
    func logCheckIn(method: CheckInMethod, hasContacts: Bool) {
        #if canImport(Firebase)
        Analytics.logEvent("check_in_completed", parameters: [
            "method": method.rawValue,
            "has_contacts": hasContacts,
            "timestamp": Date().timeIntervalSince1970
        ])
        print("📊 Analytics: Check-in completed via \(method.rawValue)")
        #endif
    }
    
    /// Log when user misses check-in
    func logMissedCheckIn(hoursLate: Int, contactsNotified: Int) {
        #if canImport(Firebase)
        Analytics.logEvent("missed_check_in", parameters: [
            "hours_late": hoursLate,
            "contacts_notified": contactsNotified,
            "timestamp": Date().timeIntervalSince1970
        ])
        print("📊 Analytics: Missed check-in (\(hoursLate) hours late)")
        #endif
    }
    
    /// Log when emergency contact is added
    func logContactAdded(method: NotificationMethod, totalContacts: Int) {
        #if canImport(Firebase)
        Analytics.logEvent("contact_added", parameters: [
            "notification_method": method.rawValue,
            "total_contacts": totalContacts
        ])
        print("📊 Analytics: Contact added (\(method.rawValue))")
        #endif
    }
    
    /// Log when emergency contact is removed
    func logContactRemoved(method: NotificationMethod, totalContacts: Int) {
        #if canImport(Firebase)
        Analytics.logEvent("contact_removed", parameters: [
            "notification_method": method.rawValue,
            "total_contacts": totalContacts
        ])
        #endif
    }
    
    /// Log when reminder time is changed
    func logReminderTimeChanged(hour: Int, minute: Int) {
        #if canImport(Firebase)
        Analytics.logEvent("reminder_time_changed", parameters: [
            "hour": hour,
            "minute": minute
        ])
        print("📊 Analytics: Reminder time changed to \(hour):\(minute)")
        #endif
    }
    
    /// Log when Live Activity is started
    func logLiveActivityStarted() {
        #if canImport(Firebase)
        Analytics.logEvent("live_activity_started", parameters: [
            "timestamp": Date().timeIntervalSince1970
        ])
        #endif
    }
    
    /// Log when Live Activity is dismissed
    func logLiveActivityDismissed(method: String) {
        #if canImport(Firebase)
        Analytics.logEvent("live_activity_dismissed", parameters: [
            "method": method  // "check_in", "manual", "expired"
        ])
        #endif
    }
    
    /// Log notification permission status
    func logNotificationPermission(granted: Bool) {
        #if canImport(Firebase)
        Analytics.logEvent("notification_permission", parameters: [
            "granted": granted
        ])
        #endif
    }
    
    /// Log settings screen view
    func logSettingsViewed() {
        #if canImport(Firebase)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: "settings",
            AnalyticsParameterScreenClass: "SettingsView"
        ])
        #endif
    }
    
    /// Log home screen view
    func logHomeViewed() {
        #if canImport(Firebase)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: "home",
            AnalyticsParameterScreenClass: "HomeView"
        ])
        #endif
    }
    
    /// Log history screen view
    func logHistoryViewed() {
        #if canImport(Firebase)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: "history",
            AnalyticsParameterScreenClass: "HistoryView"
        ])
        #endif
    }
    
    // MARK: - User Properties
    
    /// Set user properties for segmentation
    func setUserProperties(contactCount: Int, notificationsEnabled: Bool) {
        #if canImport(Firebase)
        Analytics.setUserProperty("\(contactCount)", forName: "contact_count")
        Analytics.setUserProperty(notificationsEnabled ? "enabled" : "disabled", forName: "notifications_status")
        #endif
    }
    
    /// Update contact count property
    func updateContactCount(_ count: Int) {
        #if canImport(Firebase)
        Analytics.setUserProperty("\(count)", forName: "contact_count")
        #endif
    }
    
    // MARK: - Crashlytics
    
    /// Log non-fatal error
    func logError(_ error: Error, context: String) {
        #if canImport(Firebase)
        let nsError = error as NSError
        let userInfo = nsError.userInfo.merging(["context": context]) { _, new in new }
        let enhancedError = NSError(domain: nsError.domain, code: nsError.code, userInfo: userInfo)
        
        Crashlytics.crashlytics().record(error: enhancedError)
        print("⚠️ Crashlytics: Error logged - \(context): \(error.localizedDescription)")
        #endif
    }
    
    /// Log custom message for debugging crashes
    func log(_ message: String) {
        #if canImport(Firebase)
        Crashlytics.crashlytics().log(message)
        #endif
    }
    
    /// Set custom key for crash context
    func setCustomKey(_ key: String, value: Any) {
        #if canImport(Firebase)
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        #endif
    }
    
    /// Set user identifier (use anonymized ID, not PII)
    func setUserIdentifier(_ identifier: String) {
        #if canImport(Firebase)
        Crashlytics.crashlytics().setUserID(identifier)
        Analytics.setUserID(identifier)
        #endif
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



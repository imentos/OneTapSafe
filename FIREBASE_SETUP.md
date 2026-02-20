# Firebase Setup Guide for OneTap OK

This guide walks you through adding Firebase to OneTap OK for analytics, crash reporting, and remote configuration.

## Prerequisites

- Active Apple Developer account
- Xcode 15.0+
- Bundle ID: `com.yourcompany.onetapok` (or your actual bundle ID)

---

## Step 1: Create Firebase Project

### 1.1 Go to Firebase Console
- Visit: https://console.firebase.google.com/
- Click "Add project" or "Create a project"

### 1.2 Project Setup
- **Project name:** `OneTap OK` or `OneTapSafe`
- **Google Analytics:** Enable (recommended)
- **Analytics location:** Select your country
- Accept terms and click "Create project"

### 1.3 Add iOS App
1. Click the iOS icon to add an iOS app
2. **iOS bundle ID:** Enter your app's bundle ID (e.g., `com.yourcompany.onetapok`)
3. **App nickname (optional):** "OneTap OK iOS"
4. **App Store ID (optional):** Leave blank initially, add after publishing

---

## Step 2: Download Configuration File

### 2.1 Download GoogleService-Info.plist
1. In Firebase Console → Your iOS app → Download `GoogleService-Info.plist`
2. **IMPORTANT:** This file contains API keys and should NOT be committed to Git

### 2.2 Add to Xcode Project
1. Drag `GoogleService-Info.plist` into Xcode project
2. **Target:** Check "OneTapSafe" (main app target)
3. **Copy items if needed:** ✅ Checked
4. **Add to targets:** Select "OneTapSafe"
5. Click "Finish"

### 2.3 Verify Location
- File should be in: `OneTapSafe/GoogleService-Info.plist`
- Appears in Xcode project navigator under "OneTapSafe" folder

---

## Step 3: Add Firebase SDK via Swift Package Manager

### 3.1 Add Package Dependency
1. Xcode → File → Add Package Dependencies...
2. **Search:** `https://github.com/firebase/firebase-ios-sdk`
3. **Version:** Select "Up to Next Major Version" with latest (e.g., 10.0.0+)
4. Click "Add Package"

### 3.2 Select Products
Select these Firebase products:
- ✅ **FirebaseAnalytics** - Core analytics
- ✅ **FirebaseAnalyticsSwift** - Swift-friendly analytics
- ✅ **FirebaseCrashlytics** - Crash reporting
- ✅ **FirebaseRemoteConfig** - Feature flags and A/B testing
- ✅ **FirebaseMessaging** (optional) - Push notifications (future)
- ✅ **FirebaseAuth** (optional) - User authentication (future)

**Target:** OneTapSafe (main app)

Click "Add Package"

---

## Step 4: Initialize Firebase in App

### 4.1 Update OneTapSafeApp.swift

The app initialization has already been added. Verify it looks like this:

```swift
import SwiftUI
import Firebase

@main
struct OneTapSafeApp: App {
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        print("🔥 Firebase initialized")
        
        // Existing initialization code...
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 4.2 Verify Import
Make sure these imports are at the top of files using Firebase:
```swift
import Firebase
import FirebaseAnalytics
import FirebaseCrashlytics
```

---

## Step 5: Enable Crashlytics

### 5.1 Add Run Script Phase
1. Xcode → Select "OneTapSafe" target
2. Build Phases → Click "+" → New Run Script Phase
3. **Name:** "Run Firebase Crashlytics"
4. **Script:**
```bash
"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
```

5. **Input Files:** Add this line
```
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}
```

6. **Output Files:** Add this line
```
${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}
```

### 5.2 Enable Debug Symbols
1. Xcode → Select "OneTapSafe" target
2. Build Settings → Search "Debug Information Format"
3. **Debug:** DWARF with dSYM File
4. **Release:** DWARF with dSYM File

---

## Step 6: Update Info.plist (if needed)

### 6.1 Add Firebase Configuration (Usually Automatic)
Firebase typically reads from `GoogleService-Info.plist` automatically. If you need manual configuration:

1. Open `Info.plist`
2. Add these keys (usually not needed):
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

---

## Step 7: Analytics Events Setup

### 7.1 Track Key Events

**App Launch:**
```swift
Analytics.logEvent("app_launch", parameters: nil)
```

**Check-In Completed:**
```swift
Analytics.logEvent("check_in_completed", parameters: [
    "method": method.rawValue,  // "app", "notification", "liveActivity"
    "has_contacts": dataStore.trustedContacts.count > 0
])
```

**Contact Added:**
```swift
Analytics.logEvent("contact_added", parameters: [
    "method": contact.method.rawValue,  // "sms", "email", "call"
    "total_contacts": dataStore.trustedContacts.count
])
```

**Missed Check-In:**
```swift
Analytics.logEvent("missed_check_in", parameters: [
    "hours_late": hoursLate,
    "contacts_notified": contactsCount
])
```

**Settings Changed:**
```swift
Analytics.logEvent("settings_updated", parameters: [
    "reminder_time": reminderTime,
    "notifications_enabled": notificationsEnabled
])
```

### 7.2 User Properties
```swift
Analytics.setUserProperty("\(contactCount)", forName: "contact_count")
Analytics.setUserProperty(userType, forName: "user_type")  // "free", "premium"
```

---

## Step 8: Remote Config for Feature Flags

### 8.1 Set Default Values
```swift
let defaults: [String: NSObject] = [
    "grace_period_hours": 8 as NSObject,
    "max_contacts_free": 3 as NSObject,
    "show_paywall": false as NSObject,
    "enable_live_activity": true as NSObject
]
RemoteConfig.remoteConfig().setDefaults(defaults)
```

### 8.2 Fetch and Activate
```swift
RemoteConfig.remoteConfig().fetch(withExpirationDuration: 3600) { status, error in
    if status == .success {
        RemoteConfig.remoteConfig().activate()
        print("🔥 Remote Config fetched successfully")
    }
}
```

### 8.3 Get Values
```swift
let gracePeriod = RemoteConfig.remoteConfig()["grace_period_hours"].numberValue.intValue
let showPaywall = RemoteConfig.remoteConfig()["show_paywall"].boolValue
```

---

## Step 9: Crashlytics Testing

### 9.1 Force a Test Crash
Add this to test Crashlytics (remove after testing):
```swift
Button("Test Crash") {
    fatalError("Test crash for Crashlytics")
}
```

### 9.2 Verify in Firebase Console
1. Run app → tap crash button → app crashes
2. Reopen app (logs are sent on next launch)
3. Firebase Console → Crashlytics → See crash report within 5 minutes

### 9.3 Log Non-Fatal Errors
```swift
let error = NSError(domain: "com.onetapok", code: 100, userInfo: [
    NSLocalizedDescriptionKey: "Failed to send SMS"
])
Crashlytics.crashlytics().record(error: error)
```

---

## Step 10: Privacy & App Store Requirements

### 10.1 Update Privacy Policy
Add to `PRIVACY_POLICY.md`:
```markdown
## Analytics & Crash Reporting

We use Firebase Analytics and Crashlytics to improve app performance:
- **Analytics:** Anonymous usage data (screen views, button taps, check-in events)
- **Crashlytics:** Crash reports and error logs (no personal data)
- **Data collected:** Device model, OS version, app version, anonymized user ID
- **Data NOT collected:** Names, phone numbers, email addresses, location

You can opt out of analytics in iOS Settings → Privacy → Analytics & Improvements.
```

### 10.2 App Store Connect - Data Collection
When submitting to App Store:
- **Do you collect data?** YES
- **Data types:**
  - ✅ Crash Data (used for app functionality)
  - ✅ Performance Data (used for app functionality)
  - ✅ Other Diagnostic Data (used for analytics)
- **Linked to user?** NO
- **Used for tracking?** NO

---

## Step 11: Testing & Verification

### 11.1 Debug Mode (Development)
Add this to enable Firebase debug logging:
```swift
// In AppDelegate or App init
#if DEBUG
FirebaseConfiguration.shared.setLoggerLevel(.debug)
#endif
```

### 11.2 Verify Events in Firebase Console
1. Firebase Console → Analytics → DebugView
2. Run app on physical device or simulator
3. Events should appear in real-time (30-60 seconds delay)

### 11.3 Test Checklist
- [ ] Firebase initialized on app launch
- [ ] Analytics events logged (check DebugView)
- [ ] Crashlytics test crash appears in console
- [ ] Remote Config values fetched
- [ ] GoogleService-Info.plist in .gitignore
- [ ] No Firebase errors in Xcode console

---

## Step 12: Production Considerations

### 12.1 Environment Variables
Use different Firebase projects for development vs. production:
- **Development:** `OneTapOK-Dev`
- **Production:** `OneTapOK-Prod`

Use build configurations to swap `GoogleService-Info.plist` files.

### 12.2 Analytics Opt-Out
Allow users to disable analytics:
```swift
Analytics.setAnalyticsCollectionEnabled(userConsent)
```

### 12.3 Performance Monitoring (Optional)
Add `FirebasePerformance` for:
- App startup time tracking
- Network request monitoring
- Custom trace spans

---

## Common Issues & Solutions

### Issue: "FirebaseApp.configure() must be called before..."
**Solution:** Ensure `FirebaseApp.configure()` is in `init()` of your `@main` App struct

### Issue: "GoogleService-Info.plist not found"
**Solution:** 
1. Verify file is in Xcode project navigator
2. Check "Target Membership" → OneTapSafe is checked
3. Clean build folder (Cmd+Shift+K)

### Issue: "No events in Firebase Console"
**Solution:**
1. Wait 5-10 minutes for data processing
2. Enable DebugView (see Step 11.1)
3. Check internet connection
4. Verify `GoogleService-Info.plist` has correct API key

### Issue: Crashlytics not showing crashes
**Solution:**
1. Verify Run Script is in Build Phases
2. Crash logs upload on NEXT app launch (reopen app after crash)
3. Check Firebase Console → Crashlytics after 5 minutes

---

## Security Best Practices

### ✅ DO:
- Add `GoogleService-Info.plist` to `.gitignore`
- Use different Firebase projects for dev/prod
- Enable App Check (prevent API abuse)
- Monitor Firebase usage/costs in console
- Rotate API keys periodically

### ❌ DON'T:
- Commit `GoogleService-Info.plist` to Git (contains API keys)
- Hardcode Firebase config values in code
- Share Firebase project credentials publicly
- Use production Firebase in debug builds

---

## Next Steps

1. **Set up Analytics dashboards** in Firebase Console
2. **Create Remote Config parameters** for feature flags
3. **Set up A/B testing** for paywall experiments
4. **Enable Performance Monitoring** for app speed insights
5. **Set up Cloud Messaging** for future push notifications
6. **Create BigQuery export** for advanced analytics (optional)

---

## Firebase Services Roadmap for OneTap OK

### Phase 1: Core (Current)
- ✅ Firebase Analytics
- ✅ Firebase Crashlytics
- ✅ Remote Config for feature flags

### Phase 2: Engagement (Future)
- 🔜 Cloud Messaging (push notifications)
- 🔜 A/B Testing for paywalls
- 🔜 Dynamic Links for sharing

### Phase 3: Backend (Optional)
- 🔜 Cloud Firestore (backup contacts)
- 🔜 Cloud Functions (server-side logic)
- 🔜 Firebase Auth (user accounts)

---

## Resources

- [Firebase iOS SDK Documentation](https://firebase.google.com/docs/ios/setup)
- [Firebase Analytics Events](https://firebase.google.com/docs/analytics/events)
- [Crashlytics Documentation](https://firebase.google.com/docs/crashlytics)
- [Remote Config Guide](https://firebase.google.com/docs/remote-config)
- [Firebase Console](https://console.firebase.google.com/)

---

## Support

**Questions?** Check:
1. Firebase Console → Support tab
2. Stack Overflow: [firebase] [ios] tags
3. Firebase Slack Community

**Last Updated:** February 19, 2026 🔥

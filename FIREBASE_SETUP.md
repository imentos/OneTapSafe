# Firebase Analytics Setup for OneTap OK

Simple guide to add Firebase Analytics to track user behavior and app usage.

## Step 1: Create Firebase Project

1. Go to https://console.firebase.google.com/
2. Click "Add project"
3. **Project name:** `OneTap OK`
4. **Enable Google Analytics:** ✅ Yes
5. Click "Create project"

## Step 2: Add iOS App

1. In Firebase Console, click iOS icon
2. **iOS bundle ID:** Enter your bundle ID (e.g., `com.yourname.onetapok`)
3. **App nickname:** "OneTap OK iOS"
4. Click "Register app"
5. **Download `GoogleService-Info.plist`**

## Step 3: Add Configuration File to Xcode

1. Drag `GoogleService-Info.plist` from Downloads into Xcode
2. **✅ Check:** "Copy items if needed"
3. **✅ Check:** "OneTapSafe" target
4. Click "Finish"

**Important:** This file is already in `.gitignore` - don't commit it to Git!

## Step 4: Add Firebase SDK

1. In Xcode: **File → Add Package Dependencies...**
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Version: "Up to Next Major Version" (12.0.0+)
4. Click "Add Package"
5. **Select only:**
   - ✅ **FirebaseAnalytics**
   - ✅ **FirebaseAnalyticsSwift** (optional, Swift-friendly API)
6. Target: **OneTapSafe**
7. Click "Add Package"

## Step 5: Initialize Firebase

Already done in `OneTapSafeApp.swift`:

```swift
import SwiftUI
import Firebase

@main
struct OneTapSafeApp: App {
    init() {
        FirebaseApp.configure()
        print("🔥 Firebase configured")
        // ... rest of init
    }
}
```

## Step 6: Test Analytics

### Enable Debug Mode

1. Xcode → **Product → Scheme → Edit Scheme...**
2. Select "Run" → "Arguments" tab
3. Add launch argument: `-FIRDebugEnabled`
4. Click "Close"

### View Events in Console

1. Run app (⌘R)
2. Firebase Console → **Analytics → DebugView**
3. Your device should appear within 30 seconds
4. See events streaming in real-time

### Test Events

Your app already tracks:
- `app_launch` - When app opens
- `check_in_completed` - When user checks in
- `missed_check_in` - When check-in is missed
- `contact_added` / `contact_removed` - Contact management
- `reminder_time_changed` - Settings changes
- `screen_view` - Screen navigation

## Analytics Events Reference

### Core Events

```swift
// App launch
FirebaseManager.shared.logAppLaunch()

// Check-in completed
FirebaseManager.shared.logCheckIn(method: .liveActivity, hasContacts: true)

// Missed check-in
FirebaseManager.shared.logMissedCheckIn(hoursLate: 2, contactsNotified: 3)

// Contact management
FirebaseManager.shared.logContactAdded(method: .sms, totalContacts: 2)
FirebaseManager.shared.logContactRemoved(method: .email, totalContacts: 1)

// Settings
FirebaseManager.shared.logReminderTimeChanged(hour: 9, minute: 0)

// Screen views
FirebaseManager.shared.logHomeViewed()
FirebaseManager.shared.logSettingsViewed()
```

## Viewing Analytics Data

### Real-Time (DebugView)
- Firebase Console → Analytics → **DebugView**
- See events as they happen (requires `-FIRDebugEnabled`)
- Great for testing

### Production Dashboard
- Firebase Console → Analytics → **Dashboard**
- Data appears after **24-48 hours**
- Shows DAU, retention, user engagement

### Custom Reports
- Firebase Console → Analytics → **Events**
- See all tracked events
- Click event name for detailed breakdown
- Filter by date, user properties, etc.

## Key Metrics to Monitor

- **Daily Active Users (DAU)** - How many users open app daily
- **Retention** - % of users who return (D1, D7, D30)
- **Check-in completion rate** - `check_in_completed` / daily users
- **Missed check-ins** - How often users forget
- **Contact adoption** - % of users with contacts added

## Troubleshooting

### Events not showing in DebugView
- Wait 30-60 seconds after launching app
- Verify `-FIRDebugEnabled` in launch arguments
- Check internet connection
- Look for "🔥 Firebase configured" in Xcode console

### `GoogleService-Info.plist not found`
- Verify file is in Xcode project navigator
- Check file's Target Membership (right panel)
- Ensure "OneTapSafe" target is checked

### Build errors
- Clean build folder: ⇧⌘K
- Reset package caches: File → Packages → Reset Package Caches
- Restart Xcode

## Privacy & App Store

### Privacy Policy
Add to your privacy policy:
```
We use Firebase Analytics to understand app usage and improve user experience.
Data collected: device type, iOS version, app version, anonymized usage patterns.
No personal information (names, emails, contacts) is collected.
```

### App Store Privacy Labels
When submitting:
- **Data Used to Track You:** None
- **Data Linked to You:** None
- **Data Not Linked to You:** 
  - ✅ Usage Data
  - ✅ Diagnostics

## Disable Debug Mode for Release

Before App Store submission:
1. **Product → Scheme → Edit Scheme...**
2. Remove `-FIRDebugEnabled` argument
3. Build for release: **Product → Archive**

---

## Quick Links

- **Firebase Console:** https://console.firebase.google.com/
- **DebugView:** Firebase Console → Analytics → DebugView
- **Events:** Firebase Console → Analytics → Events
- **Documentation:** https://firebase.google.com/docs/analytics/get-started?platform=ios

---

**That's it!** Firebase Analytics is now tracking user behavior in your app. 📊

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

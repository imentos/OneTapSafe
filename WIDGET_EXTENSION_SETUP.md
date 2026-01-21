# Live Activity Widget Extension Setup

## Problem
Live Activities are active in code but not showing on lock screen because they need to be in a **Widget Extension**, not the main app target.

## Solution: Create Widget Extension

### Step 1: Add Widget Extension Target

1. In Xcode, go to **File > New > Target**
2. Search for **"Widget Extension"**
3. Click **Next**
4. Name it: **"OneTapSafeWidget"**
5. Uncheck **"Include Configuration Intent"**
6. Click **Finish**
7. Click **Activate** when prompted

### Step 2: Move Live Activity Files to Widget Extension

**Move these files to the Widget Extension target:**

1. `CheckInActivityAttributes.swift`
2. `CheckInLiveActivity.swift`

**Keep in BOTH targets (Main App + Widget):**
- `CheckInIntent.swift` (App Intent needs to be in both)

**How to move:**
1. Select the file in Xcode
2. Open **File Inspector** (right panel)
3. Under **Target Membership**, check both:
   - ✅ OneTapSafe (main app)
   - ✅ OneTapSafeWidget (widget extension)

### Step 3: Update Widget Extension Bundle

Edit `OneTapSafeWidget.swift` (created by Xcode):

```swift
import WidgetKit
import SwiftUI

@main
struct OneTapSafeWidgetBundle: WidgetBundle {
    var body: some Widget {
        CheckInLiveActivity()
    }
}
```

### Step 4: Setup App Groups (for data sharing)

1. Select **OneTapSafe** target > **Signing & Capabilities**
2. Click **+ Capability** > **App Groups**
3. Click **+** and add: `group.com.yourcompany.onetapsafe`
4. Select **OneTapSafeWidget** target > **Signing & Capabilities**
5. Click **+ Capability** > **App Groups**
6. Check the **same group**: `group.com.yourcompany.onetapsafe`

### Step 5: Update DataStore to use App Groups

In `DataStore.swift`, change:

```swift
private let defaults = UserDefaults(suiteName: "group.com.yourcompany.onetapsafe")!
```

Instead of:
```swift
private let defaults = UserDefaults.standard
```

### Step 6: Add Info.plist to Widget Extension

Make sure `OneTapSafeWidget/Info.plist` has:

```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

### Step 7: Rebuild and Test

1. **Clean Build Folder**: Product > Clean Build Folder (⇧⌘K)
2. **Build**: ⌘B
3. **Run** on device
4. Tap "Test Live Activity"
5. **Lock phone**
6. Should now see Live Activity on lock screen!

## Why This Is Needed

Live Activities are rendered by **WidgetKit**, which runs in a separate process from your main app. They need their own Widget Extension target to display on the lock screen.

The main app can **start/stop** Live Activities, but the **UI rendering** happens in the Widget Extension.

## Quick Check

After setup, you should see in Xcode:
```
OneTapSafe/
  ├── OneTapSafe (main app)
  └── OneTapSafeWidget (widget extension)
      ├── OneTapSafeWidget.swift
      ├── CheckInLiveActivity.swift
      ├── CheckInActivityAttributes.swift
      └── Info.plist
```

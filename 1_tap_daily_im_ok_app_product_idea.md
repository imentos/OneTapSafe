# One Tap Safe (iOS)

## One‑Line Pitch
A privacy‑first iOS app that lets users confirm they're safe with **one tap per day**, directly from **Lock Screen / Dynamic Island using Live Activities**, and alerts trusted contacts only if a check‑in is missed.

**App Name:** One Tap Safe  
**Subtitle:** Lock Screen Daily Check-In

---

## Problem
- People living alone, elderly users, travelers, and busy professionals want **peace of mind** without constant tracking.
- Existing safety apps are often:
  - Too complex
  - GPS‑heavy (privacy concerns)
  - Annoying to use daily

Users want something **simple, respectful, and reliable**.

---

## Core Solution
A daily reminder + Live Activity with a **single “I’m OK” button**.

- Tap once → check‑in completed
- Missed check‑in → notify selected contacts
- No location tracking by default
- No medical claims

---

## Key Differentiator
### Live Activities + App Intents
- Check‑in **without opening the app**
- Works from:
  - Lock Screen
  - Dynamic Island
- Also supported via:
  - Notification action button
  - Siri / Shortcuts (optional)

Most competitors do **not** use Live Activities.

---

## Target Users
- Elderly living alone
- Adult children caring for parents
- Solo travelers
- People with anxiety who want reassurance
- Families wanting lightweight daily safety

---

## MVP Feature Set (Phase 1)
- Daily scheduled reminder
- Live Activity with:
  - “I’m OK” button
  - Countdown / deadline
- Missed check‑in detection
- Notify 1 trusted contact
- Basic history (last 7 days)
- Local‑first storage (App Group)

---

## Nice‑to‑Have (Phase 2)
- Multiple contacts
- Escalation rules (contact A → B)
- Custom schedules
- Widgets
- Apple Watch quick check‑in
- Family dashboard

---

## Monetization
**Free**
- 1 contact
- Standard daily reminder

**Paid (Subscription)**
- Multiple contacts
- Missed check‑in escalation
- History & analytics
- Custom schedules

Expected pricing:
- $2.99–$4.99 / month
- Family plan option

---

## ASO Strategy
### Core Keywords
- one tap safe
- one tap check in
- lock screen check in
- daily safety check
- safety check app
- elderly check in
- live activity check in

### App Store Positioning
- "One Tap from Your Lock Screen"
- "Peace of mind without unlocking"
- “No GPS. No ads. No complexity.”

---

## Apple Review Safety Notes
- Avoid medical or emergency claims
- User‑initiated alerts only
- No automatic emergency services
- Clear privacy messaging

---

## Technical Notes
- Live Activities lifecycle ~8 hours
- AppIntent handles button tap
- Fallback via notification action
- Background sync via BGTask or next launch

---

## Why This Is a Strong Idea
- Proven market demand
- Simple MVP
- Strong ASO intent
- Differentiated UX using modern iOS APIs
- Emotionally resonant but review‑safe

---

## Next Steps
- Validate keywords in ASO tools
- Design Live Activity UI states
- Build MVP in 2–3 weeks
- Launch with privacy‑first messaging


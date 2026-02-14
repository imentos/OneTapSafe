# OneTap OK - Paywall Implementation Plan

## Monetization Strategy

### Free Tier (Forever Free)
- ✅ 1 emergency contact maximum
- ✅ Email notifications (unlimited via SendGrid)
- ✅ Daily check-in reminders
- ✅ 7-day history
- ✅ Basic Live Activity widgets

### Premium Tier - "OneTap OK Pro"

**Pricing:**
- Monthly: $1.99/month
- Annual: $14.99/year (37% savings)
- Lifetime: $29.99 one-time

**Premium Features:**
- ✅ **Unlimited contacts** (vs 1 free) - IMPLEMENTED
- ⏳ **Multiple check-ins per day** (morning, noon, night) - TODO
- ⏳ **30-day history** (vs 7 days free) - TODO
- ⏳ **Custom check-in messages** - TODO
- ⏳ **Emergency panic button** (instant alert) - TODO
- ⏳ **Location sharing** in alerts (GPS coordinates via email) - TODO
- ⏳ **Check-in scheduling** (different times each day) - TODO
- ⏳ **Priority support** - TODO

**Currently Implemented:**
- ✅ Unlimited emergency contacts
- ✅ Email notifications via SendGrid
- ✅ Daily check-in system
- ✅ Contact limit gating (1 free, unlimited Pro)
- ✅ Paywall UI with 3 pricing tiers
- ✅ StoreKit 2 integration

---

## Implementation Roadmap

### Phase 1: Core Infrastructure (Day 1-2)
- [ ] Create `SubscriptionManager.swift` (StoreKit 2)
- [ ] Define Product IDs in code
- [ ] Add subscription products in App Store Connect:
  - `com.onetapok.monthly` - $1.99/month
  - `com.onetapok.annual` - $14.99/year
  - `com.onetapok.lifetime` - $29.99 one-time
- [ ] Create StoreKit Configuration file for testing

### Phase 2: Paywall UI (Day 2-3)
- [ ] Create `PaywallView.swift` with 3 pricing tiers
- [ ] Design premium feature showcase
- [ ] Add "Restore Purchases" button
- [ ] Add "Terms & Privacy" links
- [ ] Implement close/dismiss logic

### Phase 3: Feature Gating (Day 3-4)
- [ ] Gate contact limit (2 free, unlimited pro)
- [ ] Update `AddContactView.swift` with contact limit check
- [ ] Add "Upgrade to Pro" banner when limit reached
- [ ] Gate multiple daily check-ins
- [ ] Gate 30-day history (vs 7-day free)
- [ ] Add "Pro" badges on premium features

### Phase 4: User Experience (Day 4-5)
- [ ] Show paywall on 3rd contact add attempt
- [ ] Add "Upgrade" button in Settings
- [ ] Add "Pro" indicator in navigation bar for subscribers
- [ ] Implement graceful degradation (pro features → free tier)
- [ ] Add celebration animation on purchase

### Phase 5: Testing & Polish (Day 5-6)
- [ ] Test with StoreKit sandbox
- [ ] Test restore purchases flow
- [ ] Test subscription renewal
- [ ] Test family sharing (optional)
- [ ] Test on iPhone and iPad
- [ ] Add analytics events (purchase, paywall_shown, etc.)

### Phase 6: App Store Setup (Day 6-7)
- [ ] Create subscription products in App Store Connect
- [ ] Set up subscription groups
- [ ] Configure pricing in all territories
- [ ] Add subscription marketing copy
- [ ] Submit for review

---

## Technical Implementation Details

### Product IDs
```swift
enum SubscriptionProduct: String {
    case monthly = "com.onetapok.monthly"
    case annual = "com.onetapok.annual"
    case lifetime = "com.onetapok.lifetime"
}
```

### Feature Gates
```swift
enum PremiumFeature {
    case unlimitedContacts  // Free: 1, Pro: ∞
    case multipleCheckIns   // Free: 1/day, Pro: 3/day
    case extendedHistory    // Free: 7 days, Pro: 30 days
    case customMessages     // Pro only
    case panicButton        // Pro only
    case locationSharing    // Pro only
    case scheduling         // Pro only
}
```

### Contact Limit Logic
```swift
// In DataStore.swift
var canAddContact: Bool {
    let isPro = SubscriptionManager.shared.isPro
    return isPro || trustedContacts.count < 1
}
```

---

## Paywall Triggers

1. **On 2nd contact add** - Primary conversion point
2. **Settings → "Upgrade to Pro"** - User-initiated
3. **History view when trying to see 8+ days** - Feature discovery
4. **Multiple check-in attempt** - Feature discovery
5. **First app launch (optional)** - Soft intro, dismissible

---

## Marketing Copy

### Paywall Headline
**"Keep Everyone Safe with OneTap OK Pro"**

### Feature Bullets
- 📇 Unlimited Emergency Contacts
- ⏰ Multiple Daily Check-Ins
- 📍 Location Sharing in Alerts
- 🚨 Instant Panic Button
- 📊 30-Day Safety History
- ✨ Custom Check-In Messages

### Social Proof
"Join 10,000+ users staying safe with OneTap OK"

---

## Privacy & Legal

- [ ] Update Privacy Policy URL
- [ ] Update Terms of Service URL
- [ ] Add subscription terms:
  - Auto-renewal info
  - Cancellation policy
  - Refund policy
- [ ] Add restore purchases disclaimer

---

## Analytics Events to Track

```swift
// Track these events
- paywall_shown(trigger: String)
- paywall_dismissed
- purchase_started(product: String)
- purchase_completed(product: String, revenue: Double)
- purchase_failed(error: String)
- purchase_restored
- premium_feature_tapped(feature: String, isPro: Bool)
```

---

## App Store Connect Setup Checklist

### Subscription Group
- [ ] Group Name: "OneTap OK Premium"
- [ ] Display Name: "Pro Features"

### Monthly Product
- [ ] Product ID: `com.onetapok.monthly`
- [ ] Reference Name: "OneTap OK Pro Monthly"
- [ ] Price: $1.99 USD
- [ ] Subscription Duration: 1 Month
- [ ] Free Trial: 7 days (optional)

### Annual Product
- [ ] Product ID: `com.onetapok.annual`
- [ ] Reference Name: "OneTap OK Pro Annual"
- [ ] Price: $14.99 USD
- [ ] Subscription Duration: 1 Year
- [ ] Free Trial: 7 days (optional)

### Lifetime Product
- [ ] Product ID: `com.onetapok.lifetime`
- [ ] Reference Name: "OneTap OK Pro Lifetime"
- [ ] Price: $29.99 USD
- [ ] Type: Non-Consumable

---

## Testing Plan

### Sandbox Test Accounts
- [ ] Create 2-3 sandbox accounts in App Store Connect
- [ ] Test monthly subscription
- [ ] Test annual subscription
- [ ] Test lifetime purchase
- [ ] Test restore purchases
- [ ] Test expired subscription
- [ ] Test canceled subscription

### Edge Cases
- [ ] No internet connection
- [ ] Payment declined
- [ ] App killed during purchase
- [ ] Multiple devices with same account
- [ ] Downgrade from Pro to Free

---

## Future Enhancements (Post-Launch)

### Version 1.1
- [ ] SMS notifications via Twilio (when business entity ready)
- [ ] Family sharing (share Pro with 5 family members)
- [ ] Premium Pro tier: $4.99/month with SMS

### Version 1.2
- [ ] Push notifications to contacts (they need the app)
- [ ] Shared safety circles (group check-ins)
- [ ] Emergency contact app (separate app for contacts)

---

## Success Metrics

### Target Conversion Rates
- Paywall shown → Purchase: 3-5%
- Free trial → Paid: 40-50%
- Annual vs Monthly: 60/40 split

### Revenue Goals
- Month 1: $100 (50 subscribers)
- Month 3: $500 (250 subscribers)
- Month 6: $2,000 (1,000 subscribers)
- Year 1: $5,000+ (2,500+ subscribers)

---

## Next Steps

1. ✅ **Review this plan** - Make any changes needed
2. **Implement Phase 1** - Start with SubscriptionManager
3. **Create paywall UI** - Design in Xcode
4. **Gate features** - Add contact limits
5. **Test thoroughly** - Use sandbox accounts
6. **Submit to App Store** - With subscriptions enabled

---

*Last Updated: February 13, 2026*

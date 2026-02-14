# Twilio Integration Plan for OneTapSafe

## Overview
Add automatic SMS alerts via Twilio to enable true automatic emergency contact notifications when users miss check-ins.

## 📊 Cost Analysis

### Twilio Costs
- **Phone Number**: $1.15/month (one-time, shared across all users)
- **SMS (US)**: $0.0079 per message
- **SMS (International)**: $0.05-$0.15 per message

### Revenue Model
**Premium Subscription**: $2.99/month
- Revenue after Apple 30% cut: **$2.09**
- Average Twilio cost per user: **~$0.10/month** (assumes 90% check-in rate)
- **Profit per user**: **~$1.99/month**

### Realistic Cost Scenarios
- 90% check-in rate: 3 missed/month = $0.024/month
- 95% check-in rate: 1-2 missed/month = $0.008-$0.016/month
- 100% check-in rate: 0 missed/month = $0/month

**Key Insight**: You only pay when SMS is actually sent (missed check-in)

---

## 🎯 Implementation Phases

### Phase 1: Twilio Setup
**Duration**: 30 minutes

1. **Create Twilio Account**
   - Sign up at https://www.twilio.com/
   - Verify email and phone
   - Get free trial credits ($15-20)

2. **Get Credentials**
   - Account SID (from Console Dashboard)
   - Auth Token (from Console Dashboard)
   - Buy phone number ($1.15/month)

3. **Test with Twilio Console**
   - Send test SMS from dashboard
   - Verify delivery to your phone

---

### Phase 2: Backend Server
**Duration**: 2-3 hours

**Option A: Simple Node.js Server (Recommended for MVP)**

```javascript
// server.js
const express = require('express');
const twilio = require('twilio');

const app = express();
app.use(express.json());

const client = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

app.post('/api/send-alert', async (req, res) => {
  const { phoneNumber, message, userName } = req.body;
  
  try {
    const result = await client.messages.create({
      body: message,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: phoneNumber
    });
    
    console.log(`✅ SMS sent to ${phoneNumber}: ${result.sid}`);
    res.json({ success: true, messageSid: result.sid });
  } catch (error) {
    console.error('❌ Twilio error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

**Dependencies** (`package.json`):
```json
{
  "name": "onetapsafe-server",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.2",
    "twilio": "^4.19.0",
    "dotenv": "^16.3.1"
  }
}
```

**Environment Variables** (`.env`):
```env
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=+1234567890
PORT=3000
```

**Deployment Options**:
- **Railway.app**: Free tier, easy deploy from GitHub
- **Render.com**: Free tier, auto-deploy
- **Heroku**: $5-7/month (no free tier anymore)
- **AWS Lambda**: Pay per use (~$0-1/month)

---

### Phase 3: iOS App Changes
**Duration**: 2-3 hours

#### 1. Update ContactNotifier.swift

**Current Code** (lines 13-14):
```swift
private let automatedNotificationsEnabled = false
private let notificationWebhookURL = "https://your-server.com/api/notify"
```

**New Code**:
```swift
private let automatedNotificationsEnabled = true
private let notificationWebhookURL = "https://your-server.railway.app/api/send-alert"
```

#### 2. Update Server Request Format

**Modify `sendToServer()` method** (line 92+):
```swift
private func sendToServer(_ requests: [[String: Any]]) {
    guard let url = URL(string: notificationWebhookURL) else {
        print("❌ Invalid webhook URL")
        fallbackToManualNotifications()
        return
    }
    
    for request in requests {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Format for backend
        let payload: [String: Any] = [
            "phoneNumber": request["phone"] as? String ?? "",
            "message": request["message"] as? String ?? "",
            "userName": DataStore.shared.userName ?? "User"
        ]
        
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    print("❌ Server error: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    print("✅ SMS sent successfully via server")
                } else {
                    print("❌ Server returned error")
                }
            }.resume()
        } catch {
            print("❌ Failed to encode request: \(error)")
        }
    }
}
```

#### 3. Add Subscription Check

**New Method in ContactNotifier**:
```swift
private func canSendAutomatedAlerts() -> Bool {
    // TODO: Check if user has active premium subscription
    // For now, check subscription status
    return SubscriptionManager.shared.isPremium
}

func notifyContacts(for missedCheckIn: Date) {
    let contacts = DataStore.shared.trustedContacts
    
    guard !contacts.isEmpty else {
        print("⚠️ No contacts to notify")
        return
    }
    
    // Use automated if premium subscriber
    if canSendAutomatedAlerts() && automatedNotificationsEnabled {
        sendAutomatedNotifications(contacts: contacts, missedCheckIn: missedCheckIn)
    } else {
        // Fallback to manual (free tier)
        sendManualNotifications(contacts: contacts, missedCheckIn: missedCheckIn)
    }
}
```

---

### Phase 4: Subscription/Paywall
**Duration**: 3-4 hours

#### 1. Create SubscriptionManager.swift

```swift
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isPremium = false
    @Published var products: [Product] = []
    
    private let productID = "com.onetapsafe.premium.monthly"
    
    init() {
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: [productID])
        } catch {
            print("❌ Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                await checkSubscriptionStatus()
                return true
            case .unverified:
                return false
            }
        case .pending, .userCancelled:
            return false
        @unknown default:
            return false
        }
    }
    
    func checkSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID {
                isPremium = true
                return
            }
        }
        isPremium = false
    }
    
    func restorePurchases() async {
        try? await AppStore.sync()
        await checkSubscriptionStatus()
    }
}
```

#### 2. Create PaywallView.swift

```swift
import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        
                        Text("Go Premium")
                            .font(.title.bold())
                        
                        Text("Get automatic SMS alerts when you miss check-ins")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "bell.badge.fill", title: "Automatic SMS Alerts", description: "Emergency contacts get instant text messages")
                        FeatureRow(icon: "person.3.fill", title: "Up to 5 Contacts", description: "Add multiple emergency contacts")
                        FeatureRow(icon: "clock.arrow.circlepath", title: "Extended History", description: "90 days of check-in history")
                        FeatureRow(icon: "message.badge.fill", title: "Custom Messages", description: "Personalize emergency messages")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Pricing
                    if let product = subscriptionManager.products.first {
                        Button {
                            Task {
                                try? await subscriptionManager.purchase(product)
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Text("Start Premium")
                                    .font(.headline)
                                Text("\(product.displayPrice)/month")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                    }
                    
                    // Restore
                    Button("Restore Purchases") {
                        Task {
                            await subscriptionManager.restorePurchases()
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    
                    Text("Free tier includes manual notifications via Messages app")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}
```

#### 3. Update SettingsView.swift

Add premium button:
```swift
Section("Premium") {
    if SubscriptionManager.shared.isPremium {
        Label("Premium Active", systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
    } else {
        Button {
            showingPaywall = true
        } label: {
            HStack {
                Label("Upgrade to Premium", systemImage: "star.fill")
                Spacer()
                Text("$2.99/mo")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
.sheet(isPresented: $showingPaywall) {
    PaywallView()
}
```

---

### Phase 5: App Store Connect Setup
**Duration**: 1 hour

1. **Create In-App Purchase**
   - Log in to App Store Connect
   - Go to your app → Features → In-App Purchases
   - Click "+" to create new subscription
   - Select "Auto-Renewable Subscription"

2. **Subscription Details**
   - **Reference Name**: OneTapSafe Premium Monthly
   - **Product ID**: `com.onetapsafe.premium.monthly`
   - **Subscription Group**: Create new "Premium"
   - **Duration**: 1 Month
   - **Price**: $2.99 (or your choice)

3. **Localization**
   - **Display Name**: Premium
   - **Description**: Automatic SMS alerts and up to 5 emergency contacts

4. **Review Information**
   - Screenshot showing premium features
   - Review notes explaining Twilio integration

---

### Phase 6: Testing Plan
**Duration**: 2-3 hours

#### Server Testing
1. Deploy server to Railway/Render
2. Test endpoint with Postman/curl:
```bash
curl -X POST https://your-server.railway.app/api/send-alert \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+1234567890",
    "message": "Test alert from OneTapSafe",
    "userName": "Test User"
  }'
```
3. Verify SMS received on test phone

#### iOS Testing
1. **TestFlight Testing**
   - Upload build with subscription
   - Test subscription flow in sandbox
   - Verify free tier shows manual notifications
   - Verify premium tier triggers server call

2. **Sandbox Testing**
   - Create sandbox test account in App Store Connect
   - Sign out of App Store on device
   - Test purchase with sandbox account
   - Verify subscription status

3. **Integration Testing**
   - Miss a check-in as free user → verify manual notification
   - Purchase premium subscription
   - Miss a check-in as premium user → verify automatic SMS
   - Check Twilio logs for delivery

#### Edge Cases
- [ ] No internet connection
- [ ] Server is down (fallback to manual)
- [ ] Invalid phone number
- [ ] International phone numbers
- [ ] Subscription expires
- [ ] Restore purchases

---

## 📋 Implementation Checklist

### Backend
- [ ] Create Twilio account
- [ ] Get Account SID, Auth Token, Phone Number
- [ ] Create Node.js server with `/api/send-alert` endpoint
- [ ] Test locally with curl
- [ ] Deploy to Railway/Render
- [ ] Test production endpoint
- [ ] Set up logging/monitoring

### iOS App
- [ ] Create SubscriptionManager.swift
- [ ] Create PaywallView.swift
- [ ] Update ContactNotifier.swift (enable automated mode)
- [ ] Update SettingsView.swift (add premium button)
- [ ] Add subscription check before sending
- [ ] Update Info.plist (StoreKit configuration)
- [ ] Test with sandbox account

### App Store Connect
- [ ] Create subscription product
- [ ] Set price to $2.99/month
- [ ] Add localization
- [ ] Submit for review
- [ ] Wait for approval

### Testing
- [ ] Test server with Postman
- [ ] Test free tier (manual notifications)
- [ ] Test premium purchase flow
- [ ] Test automatic SMS delivery
- [ ] Test edge cases (no internet, invalid number, etc.)
- [ ] TestFlight beta testing

### Launch
- [ ] Monitor Twilio costs daily
- [ ] Set up cost alerts in Twilio dashboard
- [ ] Monitor server logs
- [ ] Track conversion rate (free → premium)
- [ ] Gather user feedback

---

## 🚀 Deployment Options

### Recommended: Railway.app (Free Tier)
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Deploy
railway init
railway up
```

**Pros**: 
- Free tier available
- Easy GitHub integration
- Auto-deploy on push
- Simple environment variables

### Alternative: Render.com
- Free tier: 750 hours/month
- Auto-deploy from GitHub
- Web dashboard for logs

---

## 💰 Cost Monitoring

### Twilio Dashboard
- Set up usage alerts at $10, $25, $50
- Monitor daily SMS count
- Track delivery rates

### Server Costs
- Railway: Free tier (500 hours/month)
- If exceeds free tier: ~$5/month

### Break-Even Analysis
**Need 3 premium subscribers to break even**:
- 3 × $2.09 = $6.27/month revenue
- Phone: $1.15 + Server: $5 = $6.15/month costs

---

## 🔄 Future Enhancements

### Phase 2 Features
- [ ] Email alerts (free via SendGrid)
- [ ] Multiple check-in times per day
- [ ] Custom alert schedules
- [ ] Family plan (share subscription)
- [ ] Analytics dashboard

### Premium Tiers
- **Basic ($2.99/mo)**: 1 contact, SMS only
- **Premium ($4.99/mo)**: 5 contacts, SMS + Email
- **Family ($7.99/mo)**: 10 contacts, multiple users

---

## 📞 Support Resources

- **Twilio Docs**: https://www.twilio.com/docs/sms
- **StoreKit 2 Guide**: https://developer.apple.com/documentation/storekit
- **Railway Docs**: https://docs.railway.app/
- **Node.js Twilio SDK**: https://www.twilio.com/docs/libraries/node

---

## 🎯 Success Metrics

- **Technical**: 99% SMS delivery rate
- **Business**: 10% free → premium conversion
- **Cost**: < $0.20 average cost per premium user/month
- **User**: < 5% churn rate

---

**Status**: Ready to implement
**Estimated Total Time**: 10-12 hours
**First Milestone**: Working SMS from server (3 hours)

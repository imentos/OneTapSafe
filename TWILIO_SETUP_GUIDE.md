# Twilio SMS Setup Guide for OneTapSafe

Complete guide to set up automatic SMS text alerts for OneTapSafe using Twilio.

---

## 📱 Why Twilio SMS for OneTapSafe

- **Instant**: SMS arrives within seconds
- **High open rate**: 98% of SMS messages are read
- **Automatic**: No user interaction needed
- **Reliable**: 99.95% uptime guarantee

**Best for**: Premium users who want instant, reliable SMS alerts

---

## 💰 Cost Overview

### Twilio Pricing
- **Phone Number**: $1.15/month (US local number)
- **SMS Outbound**: $0.0079/message (US)
- **Free Trial**: $15.50 credit (test with ~1,900 messages)

### Example Costs
- 10 users × 1 alert/day = 300 messages/month = **$2.37 + $1.15 = $3.52/month**
- 100 users × 1 alert/day = 3,000 messages/month = **$23.70 + $1.15 = $24.85/month**

### Monetization Strategy
- Charge **$2.99/month** for SMS alerts
- Break-even at **3-4 paying subscribers**
- Every subscriber after that = profit!

---

## Step 1: Create Twilio Account (5 minutes)

1. **Go to**: https://www.twilio.com/try-twilio
2. **Sign up** with your email
3. **Verify email** (check inbox)
4. **Verify phone number** (receive SMS code)
5. **Complete questionnaire**:
   - Product: SMS
   - Use case: "Notifications & Alerts"
   - Programming language: JavaScript/Node.js
   - Purpose: "Safety check-in app alerts"

You'll get **$15.50 free credit** to test!

---

## Step 2: Get Phone Number (3 minutes)

1. **Log in to Twilio Console**: https://console.twilio.com/
2. **Click**: Get a Trial Number (or "Buy a Number" if verified)
3. **Accept the number** shown (e.g., +1-555-123-4567)
   - If you want a different area code, click "Choose a different number"
4. **Save the number** - you'll need it!

**Trial Limitations**:
- Can only send to verified phone numbers
- Messages include "Sent from your Twilio trial account"
- To remove limitations: Upgrade account (add credit card, no monthly fee)

---

## Step 3: Get API Credentials (2 minutes)

1. **Go to**: Console Dashboard (https://console.twilio.com/)
2. **Find** (right side):
   - **Account SID**: Starts with `AC...` (e.g., `ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`)
   - **Auth Token**: Click "Show" to reveal
3. **Copy both** - you'll need them!

**Security**: Treat these like passwords - never commit to GitHub!

---

## Step 4: Upgrade Account (Optional - Recommended)

To send to any phone number without trial restrictions:

1. **Go to**: Console → Account → General Settings
2. **Click**: "Upgrade account"
3. **Add credit card** (you'll only pay for usage, no monthly fee)
4. **Add $20** (lasts ~2,500 messages)

Now you can:
- Send to ANY phone number
- Remove "Twilio trial" from messages
- Use in production

---

## Step 5: Create Node.js Server (15 minutes)

### 5.1 Create Server Directory

```bash
mkdir onetapsafe-sms-server
cd onetapsafe-sms-server
npm init -y
```

### 5.2 Install Dependencies

```bash
npm install express twilio dotenv
```

### 5.3 Create `server.js`

```javascript
// server.js
const express = require('express');
const twilio = require('twilio');
require('dotenv').config();

const app = express();
app.use(express.json());

// Initialize Twilio client
const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const twilioPhoneNumber = process.env.TWILIO_PHONE_NUMBER;

const client = twilio(accountSid, authToken);

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ status: 'OneTapSafe SMS Server Running' });
});

// Send SMS alert endpoint
app.post('/api/send-sms', async (req, res) => {
  const { phoneNumber, contactName, userName, missedCheckIn } = req.body;
  
  // Validate required fields
  if (!phoneNumber || !contactName || !userName) {
    return res.status(400).json({ 
      success: false, 
      error: 'Missing required fields: phoneNumber, contactName, userName' 
    });
  }
  
  // Format phone number (ensure it has +1 for US)
  const formattedPhone = phoneNumber.startsWith('+') 
    ? phoneNumber 
    : `+1${phoneNumber.replace(/\D/g, '')}`;
  
  // Create SMS message
  const messageBody = `⚠️ SAFETY ALERT

Hi ${contactName},

${userName} has missed their daily check-in scheduled for today.

Expected: ${missedCheckIn || 'Today'}
Time: ${new Date().toLocaleString()}

Please reach out to ${userName} to ensure they are safe.

- OneTapSafe Alert System`;
  
  try {
    const message = await client.messages.create({
      body: messageBody,
      from: twilioPhoneNumber,
      to: formattedPhone
    });
    
    console.log(`✅ SMS sent to ${formattedPhone} (${contactName})`);
    console.log(`   Message SID: ${message.sid}`);
    
    res.json({ 
      success: true, 
      message: 'SMS sent successfully',
      messageSid: message.sid,
      to: formattedPhone
    });
  } catch (error) {
    console.error('❌ Twilio error:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message,
      code: error.code
    });
  }
});

// Test endpoint (for debugging)
app.post('/api/test-sms', async (req, res) => {
  const testPhone = req.body.phoneNumber || process.env.TEST_PHONE_NUMBER;
  
  if (!testPhone) {
    return res.status(400).json({ 
      success: false, 
      error: 'No phone number provided' 
    });
  }
  
  const formattedPhone = testPhone.startsWith('+') 
    ? testPhone 
    : `+1${testPhone.replace(/\D/g, '')}`;
  
  try {
    const message = await client.messages.create({
      body: '✅ OneTapSafe SMS test successful! Your server is working.',
      from: twilioPhoneNumber,
      to: formattedPhone
    });
    
    console.log(`✅ Test SMS sent to ${formattedPhone}`);
    console.log(`   Message SID: ${message.sid}`);
    
    res.json({ 
      success: true, 
      message: 'Test SMS sent',
      messageSid: message.sid 
    });
  } catch (error) {
    console.error('❌ Test SMS failed:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message,
      code: error.code
    });
  }
});

// Get message status endpoint (track delivery)
app.get('/api/message-status/:messageSid', async (req, res) => {
  try {
    const message = await client.messages(req.params.messageSid).fetch();
    res.json({
      sid: message.sid,
      status: message.status,
      to: message.to,
      from: message.from,
      dateCreated: message.dateCreated,
      dateSent: message.dateSent,
      errorCode: message.errorCode,
      errorMessage: message.errorMessage
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 OneTapSafe SMS Server running on port ${PORT}`);
  console.log(`📱 Twilio phone: ${twilioPhoneNumber}`);
  console.log(`🔐 Account SID: ${accountSid}`);
});
```

### 5.4 Create `.env` File

```bash
# .env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=+15551234567
TEST_PHONE_NUMBER=+15559876543
PORT=3000
```

Replace with your actual:
- **TWILIO_ACCOUNT_SID**: From Twilio Console
- **TWILIO_AUTH_TOKEN**: From Twilio Console
- **TWILIO_PHONE_NUMBER**: Your Twilio phone number (include +1)
- **TEST_PHONE_NUMBER**: Your personal phone number for testing

### 5.5 Create `.gitignore`

```bash
# .gitignore
node_modules/
.env
```

---

## Step 6: Test Locally (5 minutes)

### 6.1 Start Server

```bash
node server.js
```

You should see:
```
🚀 OneTapSafe SMS Server running on port 3000
📱 Twilio phone: +15551234567
🔐 Account SID: ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 6.2 Test SMS with curl

**Important**: If using trial account, verify your phone number first:
1. Go to: https://console.twilio.com/us1/develop/phone-numbers/manage/verified
2. Click "Add a new number" → Enter your phone → Verify with code

Now test:

```bash
curl -X POST http://localhost:3000/api/test-sms \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+15559876543"}'
```

Replace `+15559876543` with your phone number!

**Check your phone!** You should receive the test SMS within seconds.

### 6.3 Test Alert Endpoint

```bash
curl -X POST http://localhost:3000/api/send-sms \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+15559876543",
    "contactName": "Test Contact",
    "userName": "Test User",
    "missedCheckIn": "9:00 AM Today"
  }'
```

Check your phone for the formatted alert!

---

## Step 7: Deploy to Railway (Free Hosting) (10 minutes)

### 7.1 Push Code to GitHub

```bash
cd onetapsafe-sms-server
git init
git add .
git commit -m "Initial OneTapSafe SMS server with Twilio"

# Create new repo on GitHub: onetapsafe-sms-server
git remote add origin https://github.com/YOUR_USERNAME/onetapsafe-sms-server.git
git branch -M main
git push -u origin main
```

### 7.2 Deploy on Railway

1. **Go to**: https://railway.app/
2. **Click**: New Project → Deploy from GitHub repo
3. **Select**: `onetapsafe-sms-server`
4. **Wait** for deployment (2-3 minutes)
5. **Add environment variables**:
   - Click **Variables** tab
   - Add `TWILIO_ACCOUNT_SID` = your SID
   - Add `TWILIO_AUTH_TOKEN` = your token
   - Add `TWILIO_PHONE_NUMBER` = your Twilio number
6. **Get your URL**: Settings → Generate Domain
   - Copy URL (e.g., `https://onetapsafe-sms.up.railway.app`)

### 7.3 Test Production Server

```bash
curl -X POST https://onetapsafe-sms.up.railway.app/api/test-sms \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+15559876543"}'
```

Check your phone - SMS from production server!

---

## Step 8: Update OneTapSafe iOS App (15 minutes)

### 8.1 Create SubscriptionManager.swift

Create new file: `OneTapSafe/Managers/SubscriptionManager.swift`

```swift
import Foundation
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var hasSMSSubscription = false
    @Published var products: [Product] = []
    
    private let productID = "rkuo.OneTapSafe.sms.monthly" // Update with your actual ID
    
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
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                await checkSubscriptionStatus()
            case .unverified:
                throw SubscriptionError.verificationFailed
            }
        case .userCancelled:
            throw SubscriptionError.cancelled
        case .pending:
            throw SubscriptionError.pending
        @unknown default:
            throw SubscriptionError.unknown
        }
    }
    
    func checkSubscriptionStatus() async {
        var hasValidSubscription = false
        
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == productID {
                    hasValidSubscription = true
                }
            case .unverified:
                break
            }
        }
        
        hasSMSSubscription = hasValidSubscription
    }
    
    func restorePurchases() async {
        try? await AppStore.sync()
        await checkSubscriptionStatus()
    }
}

enum SubscriptionError: Error {
    case verificationFailed
    case cancelled
    case pending
    case unknown
}
```

### 8.2 Update ContactNotifier.swift

Add SMS server URL at the top:

```swift
class ContactNotifier {
    static let shared = ContactNotifier()
    
    // Email server (free)
    private let emailWebhookURL = "https://your-email-server.railway.app/api/send-alert"
    
    // SMS server (premium)
    private let smsWebhookURL = "https://your-sms-server.railway.app/api/send-sms"
    
    private let automatedNotificationsEnabled = true
    
    // ... rest of code
}
```

Update the notification method:

```swift
func notifyEmergencyContacts() {
    let contacts = DataStore.shared.emergencyContacts
    let userName = DataStore.shared.userName ?? "User"
    let hasSMSSubscription = SubscriptionManager.shared.hasSMSSubscription
    
    for contact in contacts {
        // Use SMS if user has subscription, otherwise use email
        if hasSMSSubscription && !contact.phoneNumber.isEmpty {
            sendSMS(to: contact, userName: userName)
        } else if !contact.email.isEmpty {
            sendEmail(to: contact, userName: userName)
        }
    }
}

private func sendSMS(to contact: EmergencyContact, userName: String) {
    guard let url = URL(string: smsWebhookURL) else { return }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let payload: [String: Any] = [
        "phoneNumber": contact.phoneNumber,
        "contactName": contact.name,
        "userName": userName,
        "missedCheckIn": ISO8601DateFormatter().string(from: Date())
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ SMS error: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                print("✅ SMS sent successfully to \(contact.phoneNumber)")
            }
        }.resume()
    } catch {
        print("❌ Failed to encode SMS request: \(error)")
    }
}

private func sendEmail(to contact: EmergencyContact, userName: String) {
    guard let url = URL(string: emailWebhookURL) else { return }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let payload: [String: Any] = [
        "email": contact.email,
        "contactName": contact.name,
        "userName": userName,
        "missedCheckIn": ISO8601DateFormatter().string(from: Date())
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Email error: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                print("✅ Email sent successfully to \(contact.email)")
            }
        }.resume()
    } catch {
        print("❌ Failed to encode email request: \(error)")
    }
}
```

### 8.3 Create PaywallView.swift

Create new file: `OneTapSafe/Views/PaywallView.swift`

```swift
import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        
                        Text("Upgrade to SMS Alerts")
                            .font(.title.bold())
                        
                        Text("Get instant text messages when someone misses their check-in")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "bolt.fill", title: "Instant Delivery", description: "SMS arrives within seconds")
                        FeatureRow(icon: "checkmark.shield.fill", title: "98% Open Rate", description: "Much higher than email")
                        FeatureRow(icon: "bell.badge.fill", title: "No App Required", description: "Works on any phone")
                        FeatureRow(icon: "lock.fill", title: "Reliable", description: "99.95% uptime guarantee")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Pricing
                    if let product = subscriptionManager.products.first {
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("SMS Alerts Pro")
                                        .font(.headline)
                                    Text("Monthly subscription")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(product.displayPrice)
                                    .font(.title2.bold())
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Button {
                                purchase(product)
                            } label: {
                                if isPurchasing {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Text("Subscribe Now")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isPurchasing)
                            
                            Text("Auto-renewable. Cancel anytime in App Store settings.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            
                            HStack(spacing: 16) {
                                Link("Privacy Policy", destination: URL(string: "https://imentos.github.io/onetapsafe-privacy.html")!)
                                Text("•")
                                Link("Terms of Use", destination: URL(string: "https://imentos.github.io/onetapsafe-terms.html")!)
                            }
                            .font(.caption)
                            .foregroundStyle(.blue)
                        }
                    } else {
                        ProgressView()
                    }
                    
                    // Restore purchases
                    Button("Restore Purchases") {
                        restorePurchases()
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                    
                    // Current option
                    Text("Currently using: **Email alerts** (free)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("SMS Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func purchase(_ product: Product) {
        isPurchasing = true
        
        Task {
            do {
                try await subscriptionManager.purchase(product)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isPurchasing = false
        }
    }
    
    private func restorePurchases() {
        isPurchasing = true
        
        Task {
            await subscriptionManager.restorePurchases()
            isPurchasing = false
            
            if subscriptionManager.hasSMSSubscription {
                dismiss()
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
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

### 8.4 Add Subscription to App Store Connect

1. **Go to**: App Store Connect → My Apps → OneTapSafe
2. **Click**: Features → In-App Purchases → Manage
3. **Click**: + (Create)
4. **Select**: Auto-Renewable Subscription
5. **Create Subscription Group**: "SMS Alerts"
6. **Fill in**:
   - **Reference Name**: SMS Alerts Monthly
   - **Product ID**: `rkuo.OneTapSafe.sms.monthly`
   - **Subscription Duration**: 1 Month
   - **Price**: $2.99 (or your choice)
7. **Localization**:
   - **Display Name**: SMS Alerts Pro
   - **Description**: Get instant SMS text messages when emergency contacts miss their check-in
8. **Review Information**: Add screenshot of PaywallView
9. **Click**: Save
10. **Wait** 1-2 hours for processing

---

## Step 9: Test End-to-End (10 minutes)

1. **Build and run** OneTapSafe on device
2. **Open Paywall** (add button in settings)
3. **Purchase subscription** (use sandbox tester)
4. **Set up check-in** with your phone number
5. **Miss the check-in**
6. **Check your phone** - SMS alert arrives instantly! 📱

---

## 🎯 Production Checklist

Before launching:

- [ ] Twilio account upgraded (remove trial limitations)
- [ ] Subscription configured in App Store Connect
- [ ] Server deployed to Railway with environment variables
- [ ] Privacy Policy updated to mention SMS/Twilio
- [ ] Terms of Use updated with subscription terms
- [ ] Tested on real device with real phone number
- [ ] Monitored Twilio usage dashboard
- [ ] Set up usage alerts in Twilio (prevent overspending)

---

## 💡 Cost Optimization Tips

1. **Combine with Email**: Offer email (free) + SMS (premium)
2. **Smart Notifications**: Only send if critical (e.g., 3+ hours overdue)
3. **Batch Alerts**: Group multiple missed check-ins into one message
4. **Usage Caps**: Limit to 1 SMS per user per day
5. **Monitor Twilio**: Set alerts if usage spikes

---

## 📊 Monetization Strategy

### Pricing Tiers

**Free Tier**:
- Manual notifications (MessageUI)
- Unlimited email alerts (SendGrid)

**Pro Tier ($2.99/month)**:
- Automatic SMS alerts (Twilio)
- Email + SMS combo
- Priority delivery

### Break-Even Analysis

- Monthly cost per user: $1.15 + ($0.0079 × 30) = $1.39
- Charge: $2.99/month
- Profit per user: $1.60/month
- Break-even: 3-4 subscribers

---

## 🔒 Security Best Practices

1. **Environment Variables**: Never commit API keys to Git
2. **Rate Limiting**: Prevent abuse (max 10 SMS/hour per user)
3. **Webhook Security**: Add authentication header to API calls
4. **Phone Validation**: Verify phone numbers before sending
5. **Error Handling**: Graceful fallback to email if SMS fails

---

## 📱 Alternative: Combine Email + SMS Server

You can run BOTH services on the same server:

```javascript
// Combined server.js
const express = require('express');
const sgMail = require('@sendgrid/mail');
const twilio = require('twilio');

// Both endpoints in one server
app.post('/api/send-alert', async (req, res) => {
  const { email, phoneNumber, hasSMSSubscription } = req.body;
  
  if (hasSMSSubscription && phoneNumber) {
    // Send SMS
    await sendSMS(phoneNumber, ...);
  } else if (email) {
    // Send email
    await sendEmail(email, ...);
  }
});
```

Benefits:
- Single deployment
- Easier to manage
- Unified logging

---

## 📝 Quick Reference

**Twilio Console**: https://console.twilio.com/
**Phone Numbers**: Console → Phone Numbers → Manage → Active Numbers
**Usage & Costs**: Console → Monitor → Usage
**Test Server**: `curl -X POST http://localhost:3000/api/test-sms`
**Message Logs**: Console → Monitor → Logs → Messaging

---

## ❓ Troubleshooting

### SMS not received

1. **Check trial restrictions**: Verify phone number in Twilio Console
2. **Check phone format**: Must include country code (+1 for US)
3. **Check Railway logs**: Click deployment → View Logs
4. **Check Twilio logs**: Console → Monitor → Logs → Messaging

### "Unverified number" error

- Your account is in trial mode
- Either: (1) Verify the recipient phone in Twilio, OR (2) Upgrade account

### "Invalid phone number" error

- Phone must be in E.164 format: `+15551234567`
- No spaces, dashes, or parentheses
- Must include country code

### High costs

- Check Twilio usage dashboard
- Set up usage alerts (Console → Account → Notifications)
- Consider email-first approach (SMS only for critical alerts)

---

## 🚀 Next Steps

1. **Set up SendGrid** first (email = free baseline)
2. **Deploy Twilio** for premium SMS feature
3. **Launch Free tier** with email alerts
4. **Promote Pro tier** with SMS benefits
5. **Monitor usage** and adjust pricing

---

**Status**: Ready to implement ✅
**Time to complete**: ~2 hours total
**Initial cost**: $15.50 free trial credit
**Production cost**: $1.39/user/month
**Revenue**: $2.99/month per subscriber
**Profit**: $1.60/month per subscriber 💰

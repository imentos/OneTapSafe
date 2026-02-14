# SendGrid Setup Guide for OneTapSafe

Complete guide to set up automatic email alerts for OneTapSafe using SendGrid (FREE).

---

## 📧 Why SendGrid for OneTapSafe

- **Free**: 100 emails/day forever
- **Automatic**: No user interaction needed
- **Reliable**: 99%+ delivery rate
- **Simple**: Easy API integration

**Perfect for**: Free tier automatic email alerts when users miss check-ins

---

## Step 1: Create SendGrid Account (5 minutes)

1. **Go to**: https://signup.sendgrid.com/
2. **Sign up** with your email
3. **Verify your email** (check inbox)
4. **Complete profile**:
   - Company: "OneTapSafe" or your name
   - Website: Your GitHub Pages URL or leave blank
   - Role: Developer
   - Team size: Just me
   - Purpose: "Transactional emails for safety app"

---

## Step 2: Get API Key (2 minutes)

1. **Log in to SendGrid Dashboard**
2. **Go to**: Settings → API Keys (left sidebar)
3. **Click**: "Create API Key"
4. **Name**: `OneTapSafe-Production`
5. **Permissions**: Full Access (or "Restricted Access" → Mail Send only)
6. **Click**: Create & View
7. **Copy the API key** (starts with `SG.`)
   
   ⚠️ **IMPORTANT**: Save this key! You can't see it again.

**Example key**: `SG.abc123xyz...` (keep this secret!)

---

## Step 3: Verify Sender Email (10 minutes)

SendGrid requires sender verification to prevent spam.

### Option A: Single Sender Verification (Easiest)

1. **Go to**: Settings → Sender Authentication → Single Sender Verification
2. **Click**: "Create New Sender"
3. **Fill in**:
   - From Name: `OneTapSafe`
   - From Email: `your-email@gmail.com` (your real email)
   - Reply To: Same as above
   - Company Address: Your address (required)
   - Nickname: `onetapsafe-alerts`
4. **Click**: Create
5. **Check your email** for verification link
6. **Click the link** to verify

Now you can send emails from `your-email@gmail.com`!

### Option B: Domain Authentication (Advanced - Better for production)

Skip for now - only needed if you have a custom domain.

---

## Step 4: Create Node.js Server (15 minutes)

### 4.1 Create Server Directory

```bash
mkdir onetapsafe-email-server
cd onetapsafe-email-server
npm init -y
```

### 4.2 Install Dependencies

```bash
npm install express @sendgrid/mail dotenv
```

### 4.3 Create `server.js`

```javascript
// server.js
const express = require('express');
const sgMail = require('@sendgrid/mail');
require('dotenv').config();

const app = express();
app.use(express.json());

// Set SendGrid API key
sgMail.setApiKey(process.env.SENDGRID_API_KEY);

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ status: 'OneTapSafe Email Server Running' });
});

// Send email alert endpoint
app.post('/api/send-alert', async (req, res) => {
  const { email, contactName, userName, missedCheckIn } = req.body;
  
  // Validate required fields
  if (!email || !contactName || !userName) {
    return res.status(400).json({ 
      success: false, 
      error: 'Missing required fields: email, contactName, userName' 
    });
  }
  
  // Create email message
  const msg = {
    to: email,
    from: process.env.SENDER_EMAIL, // Your verified SendGrid email
    subject: `⚠️ ${userName} Missed Daily Check-In`,
    text: `Hi ${contactName},

This is an automated safety alert from OneTapSafe.

${userName} has missed their daily safety check-in scheduled for today.

Check-in was expected at: ${missedCheckIn || 'today'}
Current time: ${new Date().toLocaleString()}

This message was sent because you are listed as an emergency contact.

Please reach out to ${userName} to ensure they are safe.

---
OneTapSafe - Automated Safety Check-In System
Do not reply to this email.`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #d32f2f;">⚠️ Missed Check-In Alert</h2>
        
        <p>Hi <strong>${contactName}</strong>,</p>
        
        <p>This is an automated safety alert from <strong>OneTapSafe</strong>.</p>
        
        <div style="background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0;">
          <strong>${userName}</strong> has missed their daily safety check-in.
        </div>
        
        <p><strong>Expected check-in:</strong> ${missedCheckIn || 'Today'}<br>
        <strong>Current time:</strong> ${new Date().toLocaleString()}</p>
        
        <p>This message was sent because you are listed as an emergency contact.</p>
        
        <p><strong>Please reach out to ${userName} to ensure they are safe.</strong></p>
        
        <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
        
        <p style="font-size: 12px; color: #666;">
          OneTapSafe - Automated Safety Check-In System<br>
          Do not reply to this email.
        </p>
      </div>
    `
  };
  
  try {
    await sgMail.send(msg);
    console.log(`✅ Email sent to ${email} (${contactName})`);
    res.json({ success: true, message: 'Email sent successfully' });
  } catch (error) {
    console.error('❌ SendGrid error:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Test endpoint (for debugging)
app.post('/api/test-email', async (req, res) => {
  const msg = {
    to: req.body.email || process.env.TEST_EMAIL,
    from: process.env.SENDER_EMAIL,
    subject: 'OneTapSafe Test Email',
    text: 'This is a test email from OneTapSafe server.',
    html: '<p><strong>This is a test email from OneTapSafe server.</strong></p>'
  };
  
  try {
    await sgMail.send(msg);
    console.log('✅ Test email sent');
    res.json({ success: true, message: 'Test email sent' });
  } catch (error) {
    console.error('❌ Test email failed:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 OneTapSafe Email Server running on port ${PORT}`);
  console.log(`Sender email: ${process.env.SENDER_EMAIL}`);
});
```

### 4.4 Create `.env` File

```bash
# .env
SENDGRID_API_KEY=SG.your_api_key_here
SENDER_EMAIL=your-email@gmail.com
TEST_EMAIL=your-email@gmail.com
PORT=3000
```

Replace:
- `SG.your_api_key_here` with your actual SendGrid API key
- `your-email@gmail.com` with the email you verified in SendGrid

### 4.5 Create `.gitignore`

```bash
# .gitignore
node_modules/
.env
```

---

## Step 5: Test Locally (5 minutes)

### 5.1 Start Server

```bash
node server.js
```

You should see:
```
🚀 OneTapSafe Email Server running on port 3000
Sender email: your-email@gmail.com
```

### 5.2 Test with curl

Open a new terminal:

```bash
curl -X POST http://localhost:3000/api/test-email \
  -H "Content-Type: application/json" \
  -d '{"email":"your-email@gmail.com"}'
```

**Check your email!** You should receive a test email within seconds.

### 5.3 Test Alert Endpoint

```bash
curl -X POST http://localhost:3000/api/send-alert \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-email@gmail.com",
    "contactName": "Test Contact",
    "userName": "Test User",
    "missedCheckIn": "9:00 AM Today"
  }'
```

Check your email for the formatted alert!

---

## Step 6: Deploy to Railway (Free Hosting) (10 minutes)

### 6.1 Create Railway Account

1. **Go to**: https://railway.app/
2. **Sign up** with GitHub
3. **Click**: New Project → Deploy from GitHub repo

### 6.2 Push Code to GitHub

```bash
cd onetapsafe-email-server
git init
git add .
git commit -m "Initial OneTapSafe email server"

# Create new repo on GitHub: onetapsafe-email-server
git remote add origin https://github.com/YOUR_USERNAME/onetapsafe-email-server.git
git branch -M main
git push -u origin main
```

### 6.3 Deploy on Railway

1. **Railway Dashboard** → New Project
2. **Select**: Deploy from GitHub repo
3. **Choose**: `onetapsafe-email-server`
4. **Wait** for deployment (2-3 minutes)
5. **Add environment variables**:
   - Click **Variables** tab
   - Add `SENDGRID_API_KEY` = `your_key`
   - Add `SENDER_EMAIL` = `your_email`
6. **Get your URL**: Copy the deployment URL (e.g., `https://your-app.railway.app`)

---

## Step 7: Update OneTapSafe iOS App (10 minutes)

### 7.1 Update ContactNotifier.swift

Find this line (around line 14):

```swift
private let notificationWebhookURL = "https://your-server.com/api/notify"
```

Replace with:

```swift
private let notificationWebhookURL = "https://your-app.railway.app/api/send-alert"
```

### 7.2 Update Server Request Format

Find the `sendToServer()` method and update to:

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
        
        // Format for SendGrid server
        let payload: [String: Any] = [
            "email": request["email"] as? String ?? "",
            "contactName": request["contactName"] as? String ?? "",
            "userName": DataStore.shared.userName ?? "User",
            "missedCheckIn": ISO8601DateFormatter().string(from: Date())
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
                    print("✅ Email sent successfully via SendGrid")
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

### 7.3 Enable Automated Notifications

Find this line (around line 13):

```swift
private let automatedNotificationsEnabled = false
```

Change to:

```swift
private let automatedNotificationsEnabled = true
```

---

## Step 8: Test End-to-End (5 minutes)

1. **Run OneTapSafe** on device/simulator
2. **Set up a check-in** with your email as emergency contact
3. **Miss the check-in** (or manually trigger via test function)
4. **Check your email** - you should receive the alert!

---

## 🎯 Cost Analysis

### SendGrid Free Tier
- **100 emails/day** = free forever
- **3,000 emails/month** = $0
- Perfect for OneTapSafe users

### Realistic Usage
- 1 user misses 1 check-in = 1 email
- 100 users missing check-ins daily = FREE
- Scale to 1,000+ users before needing paid tier

### Railway Free Tier
- **500 hours/month** = always free
- Perfect for OneTapSafe server

**Total cost**: **$0/month** 🎉

---

## 🚀 Next Steps

### For Production Launch

1. **Add error handling**: Retry failed emails
2. **Add logging**: Track email delivery
3. **Custom domain**: `alerts@onetapsafe.com` (optional)
4. **Rate limiting**: Prevent abuse
5. **Email templates**: More professional design

### Future Enhancements

1. **Add SMS** as premium feature (Twilio)
2. **Email + SMS combo** for critical alerts
3. **Delivery confirmation** back to app
4. **Customizable messages** per user

---

## 📝 Quick Reference

**SendGrid API Key**: Settings → API Keys
**Test Server**: `curl -X POST http://localhost:3000/api/test-email`
**Railway Logs**: Dashboard → Deployments → View Logs
**SendGrid Activity**: Dashboard → Activity

---

## ❓ Troubleshooting

### Email not received

1. **Check spam folder**
2. **Verify sender email** in SendGrid
3. **Check Railway logs** for errors
4. **Test with curl** to isolate issue

### "Forbidden" error

- API key is invalid
- Check `.env` file on Railway
- Regenerate API key in SendGrid

### "Sender not verified"

- Go to SendGrid → Sender Authentication
- Verify your email address
- Wait for verification email

---

**Status**: Ready to implement ✅
**Time to complete**: ~1 hour total
**Cost**: $0
**Emails**: Automatic, reliable, free!

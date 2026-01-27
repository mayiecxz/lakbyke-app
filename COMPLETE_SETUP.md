# Complete Email Setup - Follow These Steps

## Current Error
❌ "Email service not configured. Please set API_URL in EmailService."

## Quick Solution (Choose One)

### Option A: Complete Firebase Functions Setup (Recommended)

**Step 1: Install Dependencies**
Open Command Prompt (not PowerShell) as Administrator and run:
```cmd
cd c:\Users\chris\lakbyke-app\functions
npm install --no-optional
```

If that fails, try:
```cmd
npm install firebase-admin firebase-functions nodemailer --save
```

**Step 2: Configure Email in `functions/index.js`**
Edit the file and replace:
- `'your-email@gmail.com'` → Your actual Gmail
- `'your-app-password'` → Gmail App Password (get from https://myaccount.google.com/apppasswords)

**Step 3: Deploy**
```cmd
cd c:\Users\chris\lakbyke-app
firebase deploy --only functions
```

**Step 4: Update Flutter Code**
After deployment, edit `lib/services/email_service.dart` line 30:
```dart
static const String? API_URL = 'https://us-central1-lakbyke-39f1f.cloudfunctions.net/sendOTPEmail';
```

### Option B: Use a Free Email Service (Faster Setup)

**Using EmailJS (Free - No Backend Needed):**

1. Sign up at https://www.emailjs.com (free)
2. Create an email service (Gmail, Outlook, etc.)
3. Create an email template
4. Get your Service ID and Template ID
5. Update `lib/services/email_service.dart`:
   ```dart
   static const String? API_URL = 'https://api.emailjs.com/api/v1.0/email/send';
   ```
6. Update the email service to use EmailJS format

**Using SendGrid (Free Tier - 100 emails/day):**

1. Sign up at https://sendgrid.com
2. Get API key
3. Use the Cloud Function with SendGrid (see functions/index.js)

## What's Ready
✅ Functions directory created
✅ Email function code ready
✅ Package.json configured
✅ Firebase.json updated

## What's Needed
⚠️ Install npm dependencies
⚠️ Configure email credentials
⚠️ Deploy function
⚠️ Update API_URL in email_service.dart

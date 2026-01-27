# Quick Setup Steps for Email Service

## ✅ What's Already Done
- ✅ Firebase Functions directory created (`functions/`)
- ✅ Email function code created (`functions/index.js`)
- ✅ Package configuration created (`functions/package.json`)
- ✅ Firebase configuration updated (`firebase.json`)

## 🔧 What You Need to Do

### Step 1: Install Dependencies

Open a **new terminal/command prompt** (not PowerShell if having issues) and run:

```bash
cd c:\Users\chris\lakbyke-app\functions
npm install
```

If you get cache errors, try:
```bash
npm install --no-cache
```

Or run as Administrator if permission errors occur.

### Step 2: Configure Email Service

Edit `functions/index.js` and update the email configuration:

**For Gmail (Testing):**
1. Go to your Google Account → Security
2. Enable 2-Step Verification
3. Generate an App Password: https://myaccount.google.com/apppasswords
4. Update `functions/index.js`:
   ```javascript
   const transporter = nodemailer.createTransport({
     service: 'gmail',
     auth: {
       user: 'your-actual-email@gmail.com', // Your Gmail
       pass: 'xxxx xxxx xxxx xxxx',          // App Password (16 chars)
     },
   });
   ```

**For SendGrid (Production):**
1. Sign up at https://sendgrid.com
2. Get your API key
3. Update `functions/index.js`:
   ```javascript
   const transporter = nodemailer.createTransport({
     host: 'smtp.sendgrid.net',
     port: 587,
     auth: {
       user: 'apikey',
       pass: 'YOUR_SENDGRID_API_KEY',
     },
   });
   ```

### Step 3: Deploy the Function

```bash
cd c:\Users\chris\lakbyke-app
firebase deploy --only functions
```

After deployment, you'll see:
```
✔  functions[sendOTPEmail(us-central1)]: Successful create operation.
Function URL: https://us-central1-lakbyke-39f1f.cloudfunctions.net/sendOTPEmail
```

### Step 4: Update Flutter Code

Open `lib/services/email_service.dart` and update:

```dart
static const String? API_URL = 'https://us-central1-lakbyke-39f1f.cloudfunctions.net/sendOTPEmail';
```

### Step 5: Test

1. Restart your Flutter app
2. Try changing your password
3. Check your email inbox for the OTP code

## Troubleshooting

- **npm install fails**: Try running terminal as Administrator
- **Deployment fails**: Make sure you're logged in: `firebase login`
- **Email not received**: Check spam folder, verify email credentials
- **Function URL different**: Check the URL shown after deployment and update `email_service.dart`

## Current Status
- Project ID: `lakbyke-39f1f`
- Functions directory: ✅ Created
- Email function: ✅ Ready (needs email config)
- Dependencies: ⚠️ Need to run `npm install`
- Deployment: ⏳ Pending

# Quick Email Setup - Step by Step

## Current Problem
❌ Email service is not configured - you're seeing the error: "Email service not configured. Please set API_URL in EmailService."

## Solution: Set Up Firebase Cloud Functions

### Step 1: Install Node.js and Firebase CLI

1. **Install Node.js** (if not installed):
   - Download from: https://nodejs.org/
   - Install the LTS version

2. **Install Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   ```

3. **Login to Firebase**:
   ```bash
   firebase login
   ```

### Step 2: Initialize Firebase Functions

In your project root (`c:\Users\chris\lakbyke-app`), run:

```bash
firebase init functions
```

**When prompted:**
- ✅ Use an existing project: **Yes**
- Select project: **lakbyke-39f1f**
- Language: **JavaScript**
- ESLint: **Yes**
- Install dependencies: **Yes**

### Step 3: Set Up the Email Function

1. **Copy the example function**:
   - The file `functions_example.js` is already in your project root
   - Copy it to: `functions/index.js`

2. **Install nodemailer**:
   ```bash
   cd functions
   npm install nodemailer
   cd ..
   ```

3. **Configure email service** in `functions/index.js`:

   **Option A: Gmail (for testing)**
   ```javascript
   const transporter = nodemailer.createTransport({
     service: 'gmail',
     auth: {
       user: 'your-email@gmail.com',
       pass: 'your-app-password', // Get from Google Account > Security > App Passwords
     },
   });
   ```

   **Option B: SendGrid (for production)**
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

### Step 4: Deploy the Function

```bash
firebase deploy --only functions
```

After deployment, you'll see a URL like:
```
https://us-central1-lakbyke-39f1f.cloudfunctions.net/sendOTPEmail
```

### Step 5: Update Email Service in Flutter

Open `lib/services/email_service.dart` and update:

```dart
static const String? API_URL = 'https://us-central1-lakbyke-39f1f.cloudfunctions.net/sendOTPEmail';
```

### Step 6: Test

1. Restart your Flutter app
2. Try changing your password
3. Check your email inbox for the OTP code

## Quick Alternative: Use a Free Email Service

If you don't want to set up Cloud Functions right now, you can use a service like:
- **EmailJS** (free tier available)
- **SendGrid** (free tier: 100 emails/day)
- **Mailgun** (free tier available)

Then update `lib/services/email_service.dart` with their API endpoint.

## Need Help?

If you encounter any issues:
1. Make sure Node.js is installed: `node --version`
2. Make sure Firebase CLI is installed: `firebase --version`
3. Check Firebase Console: https://console.firebase.google.com/project/lakbyke-39f1f

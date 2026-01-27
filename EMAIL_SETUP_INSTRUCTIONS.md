# Email Service Setup Instructions

## Current Status
❌ Email service is **NOT configured** - OTP codes cannot be sent via email.

## Quick Setup Guide

### Option 1: Firebase Cloud Functions (Recommended)

#### Step 1: Install Prerequisites
```bash
# Install Node.js (if not already installed)
# Download from: https://nodejs.org/

# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login
```

#### Step 2: Initialize Firebase Functions
```bash
# In your project root directory
firebase init functions

# When prompted:
# - Select JavaScript
# - Use ESLint: Yes
# - Install dependencies: Yes
```

#### Step 3: Set Up Email Function
1. Copy `functions_example.js` to `functions/index.js`
2. Edit `functions/index.js` and configure your email service:

**For Gmail (Testing):**
```javascript
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'your-email@gmail.com',
    pass: 'your-app-password', // Get from Google Account > Security > App Passwords
  },
});
```

**For SendGrid (Production):**
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

#### Step 4: Install Nodemailer
```bash
cd functions
npm install nodemailer
cd ..
```

#### Step 5: Deploy Function
```bash
firebase deploy --only functions
```

#### Step 6: Update Email Service
After deployment, update `lib/services/email_service.dart`:

```dart
static const String? API_URL = 'https://us-central1-lakbyke-39f1f.cloudfunctions.net/sendOTPEmail';
```

### Option 2: Custom Backend API

If you have your own backend API:

1. Set up an endpoint that accepts POST requests with:
   ```json
   {
     "email": "user@example.com",
     "otpCode": "123456",
     "purpose": "changePassword",
     "subject": "Your OTP Code",
     "body": "Your code is 123456"
   }
   ```

2. The endpoint should return:
   ```json
   {
     "success": true,
     "message": "Email sent successfully"
   }
   ```

3. Update `lib/services/email_service.dart`:
   ```dart
   static const String? API_URL = 'https://lakbyke.com/api/send-otp-email';
   ```

## Testing

After configuration:
1. Restart your Flutter app
2. Try changing your password
3. Check your email inbox (and spam folder) for the OTP code

## Troubleshooting

- **"Email service not configured"**: Make sure `API_URL` is set in `email_service.dart`
- **Function not found**: Verify the Cloud Function URL is correct
- **Email not received**: Check spam folder, verify email service credentials
- **CORS errors**: Make sure your Cloud Function has CORS enabled (see functions_example.js)

## Current Project Info
- **Project ID**: `lakbyke-39f1f`
- **Expected Cloud Function URL**: `https://us-central1-lakbyke-39f1f.cloudfunctions.net/sendOTPEmail`

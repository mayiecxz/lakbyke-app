/**
 * Firebase Cloud Functions Example for Sending OTP Emails
 * 
 * SETUP INSTRUCTIONS:
 * 1. Install Firebase CLI: npm install -g firebase-tools
 * 2. Initialize Firebase Functions in your project: firebase init functions
 * 3. Install nodemailer: npm install nodemailer --save (in functions directory)
 * 4. Copy this code to functions/index.js
 * 5. Configure your email service (Gmail, SendGrid, etc.) in the transporter
 * 6. Deploy: firebase deploy --only functions
 * 
 * Then update lib/services/email_service.dart with your Cloud Function URL
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Configure your email service here
// Option 1: Gmail (for testing)
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'tara.lakbyke@gmail.com', // Replace with your Gmail
    pass: 'yicdodmzbxkwvrwq',    // Use Gmail App Password, not regular password
  },
});

// Option 2: SendGrid (recommended for production)
// const transporter = nodemailer.createTransport({
//   host: 'smtp.sendgrid.net',
//   port: 587,
//   auth: {
//     user: 'apikey',
//     pass: 'YOUR_SENDGRID_API_KEY',
//   },
// });

// Option 3: Custom SMTP
// const transporter = nodemailer.createTransport({
//   host: 'smtp.your-domain.com',
//   port: 587,
//   auth: {
//     user: 'your-username',
//     pass: 'your-password',
//   },
// });

exports.sendOTPEmail = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  try {
    const { email, otpCode, purpose, subject, body, newEmail } = req.body;

    if (!email || !otpCode || !purpose) {
      res.status(400).json({
        success: false,
        error: 'Missing required fields: email, otpCode, purpose',
      });
      return;
    }

    // Determine email subject and body
    let emailSubject = subject || getEmailSubject(purpose);
    let emailBody = body || getEmailBody(otpCode, purpose, newEmail);

    // Send email
    const mailOptions = {
      from: 'LAKBIKE <noreply@lakbike.com>', // Change to your email
      to: email,
      subject: emailSubject,
      text: emailBody,
      html: getEmailHTML(otpCode, purpose, newEmail), // HTML version
    };

    await transporter.sendMail(mailOptions);

    res.status(200).json({
      success: true,
      message: 'OTP email sent successfully',
    });
  } catch (error) {
    console.error('Error sending email:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to send email: ' + error.message,
    });
  }
});

function getEmailSubject(purpose) {
  switch (purpose) {
    case 'changeEmail':
      return 'Verify Your Email Change - OTP Code';
    case 'changePassword':
      return 'Verify Your Password Change - OTP Code';
    default:
      return 'Your OTP Verification Code';
  }
}

function getEmailBody(otpCode, purpose, newEmail) {
  let action = purpose === 'changeEmail' ? 'change your email address' : 'change your password';
  let body = `Hello,\n\nYou requested to ${action}.\n\nYour OTP verification code is: ${otpCode}\n\nThis code will expire in 10 minutes.\n\n`;
  
  if (purpose === 'changeEmail' && newEmail) {
    body += `Your new email address will be: ${newEmail}\n\n`;
  }
  
  body += `If you did not request this, please ignore this email.\n\nBest regards,\nLAKBIKE Team`;
  
  return body;
}

function getEmailHTML(otpCode, purpose, newEmail) {
  let action = purpose === 'changeEmail' ? 'change your email address' : 'change your password';
  
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f9f9f9; }
        .otp-code { font-size: 32px; font-weight: bold; text-align: center; padding: 20px; background-color: white; border: 2px solid #4CAF50; border-radius: 8px; margin: 20px 0; letter-spacing: 5px; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>LAKBIKE</h1>
        </div>
        <div class="content">
          <h2>Verify Your Identity</h2>
          <p>You requested to ${action}.</p>
          <p>Your OTP verification code is:</p>
          <div class="otp-code">${otpCode}</div>
          <p>This code will expire in 10 minutes.</p>
          ${purpose === 'changeEmail' && newEmail ? `<p><strong>Your new email address will be:</strong> ${newEmail}</p>` : ''}
          <p>If you did not request this, please ignore this email.</p>
        </div>
        <div class="footer">
          <p>Best regards,<br>LAKBIKE Team</p>
        </div>
      </div>
    </body>
    </html>
  `;
}

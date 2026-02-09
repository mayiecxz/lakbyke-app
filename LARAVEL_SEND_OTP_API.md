# Laravel API for OTP Emails

The app sends OTP emails via `https://lakbyke.com/api/send-otp-email` (see `lib/services/email_service.dart`).

## Contract

**Method:** `POST`  
**URL:** `https://lakbyke.com/api/send-otp-email`  
**Headers:** `Content-Type: application/json`

**Request body (JSON):**
```json
{
  "email": "user@example.com",
  "otpCode": "123456",
  "purpose": "changePassword",
  "newEmail": "new@example.com"
}
```

- `email`, `otpCode`, `purpose` are required.
- `newEmail` is optional; only sent when `purpose` is `changeEmail`.

**Success response (e.g. 200):**
```json
{
  "success": true,
  "message": "OTP email sent successfully"
}
```

**Error response (e.g. 4xx/5xx):**
```json
{
  "success": false,
  "error": "Human-readable error message"
}
```

## Laravel example

Add a route in `routes/api.php`:

```php
Route::post('/send-otp-email', [App\Http\Controllers\SendOtpEmailController::class, 'send']);
```

Controller (use your existing MAIL_* from `.env`):

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;

class SendOtpEmailController extends Controller
{
    public function send(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otpCode' => 'required|string',
            'purpose' => 'required|string|in:changeEmail,changePassword',
            'newEmail' => 'nullable|email',
        ]);

        $email = $request->input('email');
        $otpCode = $request->input('otpCode');
        $purpose = $request->input('purpose');
        $newEmail = $request->input('newEmail');

        $subject = $purpose === 'changeEmail'
            ? 'Verify Your Email Change - OTP Code'
            : 'Verify Your Password Change - OTP Code';

        try {
            Mail::raw($this->buildBody($otpCode, $purpose, $newEmail), function ($message) use ($email, $subject) {
                $message->to($email)
                    ->subject($subject)
                    ->from(config('mail.from.address'), config('mail.from.name'));
            });

            return response()->json(['success' => true, 'message' => 'OTP email sent successfully']);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'error' => $e->getMessage()], 500);
        }
    }

    private function buildBody(string $otpCode, string $purpose, ?string $newEmail): string
    {
        $action = $purpose === 'changeEmail' ? 'change your email address' : 'change your password';
        $text = "You requested to {$action}.\n\nYour OTP verification code is: {$otpCode}\n\nThis code expires in 10 minutes.\n\n";
        if ($purpose === 'changeEmail' && $newEmail) {
            $text .= "Your new email address will be: {$newEmail}\n\n";
        }
        $text .= "If you did not request this, please ignore this email.\n\nLakByke Team";
        return $text;
    }
}
```

Ensure CORS allows your app’s origin if the app runs on a different domain.
 
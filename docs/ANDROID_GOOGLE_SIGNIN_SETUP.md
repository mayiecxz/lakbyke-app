# Android Google Sign-In & Certificate Fingerprints

Google Sign-In on Android will **not** work until the app's package name and signing certificate are registered in Firebase. Follow these steps.

## Current status

- **App package name:** `com.lakbyke.cyclist` (in `android/app/build.gradle.kts`)
- **Firebase `google-services.json`** currently has Android apps for:
  - `com.activity.lakbyke`
  - `com.example.lakbyke_mobile`
- There is **no** Android app in Firebase for `com.lakbyke.cyclist`, so the app and Google Sign-In are misconfigured.

## What you need to do

### 1. Add your Android app in Firebase (if not already added)

1. Open [Firebase Console](https://console.firebase.google.com/) → your project **lakbyke-39f1f**.
2. Go to **Project settings** (gear) → **Your apps**.
3. If there is no Android app with package name **`com.lakbyke.cyclist`**:
   - Click **Add app** → Android.
   - **Android package name:** `com.lakbyke.cyclist`
   - Register the app (you can leave nickname and Debug signing certificate optional for now).

### 2. Add SHA certificate fingerprints

Google Sign-In requires your app’s SHA-1 (and optionally SHA-256) to be added in Firebase.

1. In the same Firebase project, open **Project settings** → **Your apps**.
2. Select the **Android** app with package **`com.lakbyke.cyclist`**.
3. Under **SHA certificate fingerprints**, click **Add fingerprint** and add:

**Debug (development):**

- **SHA-1:**  
  `5D:3B:AB:E2:28:8A:F4:62:D2:99:A6:7D:2D:10:0D:8C:74:88:66:01`
- **SHA-256:**  
  `19:2D:51:BC:43:A6:7E:F0:82:FD:D2:2D:26:F5:37:BA:07:50:3D:AA:AB:F4:D9:95:AD:0D:D7:29:E2:AD:EA:CF`

These values are from **this machine’s** debug keystore (`~/.android/debug.keystore`). On another dev machine or CI, run the signing report (step 4 below) and add that machine’s fingerprints too.

4. For **release** builds (and Play App Signing if you use it), add the release keystore’s SHA-1 and SHA-256 from the same signing report.

### 3. Download the new `google-services.json`

1. In Firebase **Project settings** → **Your apps** → your **`com.lakbyke.cyclist`** Android app.
2. Download **google-services.json**.
3. Replace the file in the project:
   - **Path:** `android/app/google-services.json`

### 4. Regenerate FlutterFire config (recommended)

After replacing `google-services.json`:

```bash
flutter pub global run flutterfire_cli:flutterfire configure
```

This updates `lib/firebase_options.dart` to match the new Android app.

### 5. Enable Google sign-in in Firebase Auth

1. Firebase Console → **Build** → **Authentication** → **Sign-in method**.
2. Enable **Google** and save.

---

## Getting fingerprints on another machine

From the project root:

```bash
cd android && ./gradlew signingReport
```

In the report, use the **`:app:signingReport`** section. Copy the **SHA-1** and **SHA-256** for the variant you use (e.g. **debug** or **release**) and add them in Firebase for the same Android app (`com.lakbyke.cyclist`).

---

## Code configuration (already correct)

- **`lib/services/auth_service.dart`**  
  - Android uses the **Android OAuth client ID** and **serverClientId** (web client ID) so Firebase receives a valid `idToken`. No code change needed for basic setup.
- **`android/app/build.gradle.kts`**  
  - Application ID is `com.lakbyke.cyclist`. It must match the Android app package in Firebase and in `google-services.json`.

Once the package name matches, the correct `google-services.json` is in place, and the right SHA-1/SHA-256 are added in Firebase, Google Sign-In on Android will work.

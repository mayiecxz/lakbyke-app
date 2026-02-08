# lakbyke-app

A new Flutter project.

## Developer setup: what to ask for and where to put it

To run the app, you need the following. Ask the project maintainer or team for each item and place it as indicated. These files/values are gitignored and must not be committed.

| What to ask for | Where to place it | Notes |
|-----------------|-------------------|--------|
| **Gemini API key** (Google AI Studio) | `config/secrets.json` | Add key as `{"GEMINI_API_KEY": "your_key"}`. Then run `dart run tool/sync_secrets.dart` once (see [Chatbot](#chatbot-lakbyke-assistant) below). |
| **Firebase `google-services.json`** (Android) | `android/app/google-services.json` | Download from [Firebase Console](https://console.firebase.google.com/) → Project settings → Your apps → Android app. |
| **Google Maps API key** (Maps / stations) | `lib/screens/maps/maps_screen.dart` | Set the `_googleMapsApiKey` variable (around line 47). Used for the map and LakByke station lookups. |

After adding the Gemini key to `config/secrets.json`, run:

```bash
dart run tool/sync_secrets.dart
```

Then run the app with `flutter run`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Chatbot (LakByke Assistant)

The in-app chatbot is for **application instructions and help only**. It does not use or display live sensor or user data.

**API key (required for chat):** The key is read at runtime from a JSON file (gitignored). One-time setup:

1. Copy `config/secrets.json.example` to `config/secrets.json`.
2. Add your Gemini API key to `config/secrets.json`: `{"GEMINI_API_KEY": "your_key"}`. Get a key from [Google AI Studio](https://aistudio.google.com/apikey).
3. Run: `dart run tool/sync_secrets.dart`.
4. Then use `flutter run` as usual.

See [docs/CHATBOT_SETUP.md](docs/CHATBOT_SETUP.md) for more detail. If the key is not set, the chat input is disabled and a short message is shown.

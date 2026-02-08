# lakbyke-app

Flutter app for the LakByke cyclist experience.

## Run the app

1. **Secrets** — Copy `config/secrets.json.example` → `config/secrets.json`. Add your keys (see table below). Then run:
   ```bash
   dart run tool/sync_secrets.dart
   ```
2. **Firebase** — Place `google-services.json` in `android/app/` (from [Firebase Console](https://console.firebase.google.com/)).
3. **Run:** `flutter run`

| What to ask for | Where |
|-----------------|--------|
| Gemini API key | `config/secrets.json` → `{"GEMINI_API_KEY": "your_key"}` |
| Firebase `google-services.json` | `android/app/google-services.json` |
| Google Maps API key | `lib/screens/maps/maps_screen.dart` → `_googleMapsApiKey` |

All of the above are gitignored; do not commit them.

## Chatbot

In-app chatbot is for **app instructions and help only** (no live data). Key is loaded from `config/secrets.json` after sync. Without a key, chat shows a short “not configured” message. See [docs/CHATBOT_SETUP.md](docs/CHATBOT_SETUP.md) for details.

## Getting started

- [Flutter documentation](https://docs.flutter.dev/)
- [First Flutter app](https://docs.flutter.dev/get-started/codelab)

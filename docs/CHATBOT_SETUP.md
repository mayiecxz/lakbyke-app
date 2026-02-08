# Chatbot (LakByke Assistant) setup

The chatbot uses a Gemini/Gemma API key that is **not** stored in source code. It is loaded at runtime from a JSON file that is gitignored.

## One-time setup

1. **Copy the example config**
   - Copy `config/secrets.json.example` to `config/secrets.json`.

2. **Add your API key**
   - Open `config/secrets.json` and set your key:
   - `{"GEMINI_API_KEY": "your_google_ai_studio_key"}`
   - Get a key from [Google AI Studio](https://aistudio.google.com/apikey).

3. **Sync secrets into the app**
   - From the project root run:
   - `dart run tool/sync_secrets.dart`
   - This copies `config/secrets.json` into `assets/config/secrets.json` so the Flutter app can load it. (If `config/secrets.json` is missing, the script copies the empty example so the app still builds.)

4. **Run the app**
   - `flutter run`
   - No need to pass the key on the command line.

## When you change the key

Run the sync script again, then `flutter run`:

```bash
dart run tool/sync_secrets.dart
flutter run
```

## Optional: dart-define fallback

You can still pass the key at run time if you prefer:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key
```

The app uses the JSON file first; if it is empty or missing, it falls back to `GEMINI_API_KEY` from `--dart-define`.

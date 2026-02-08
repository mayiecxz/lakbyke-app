# lakbyke-app

A new Flutter project.

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

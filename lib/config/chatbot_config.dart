import 'package:lakbyke_mobile/config/secrets_loader.dart';

/// Chatbot configuration. API key is loaded at runtime from assets/config/secrets.json
/// (see config/secrets.json.example and tool/sync_secrets.dart).
abstract final class ChatbotConfig {
  /// Gemini/Gemma API key from secrets.json, or dart-define fallback. Empty if not set.
  static String get geminiApiKey =>
      SecretsLoader.cachedKey ??
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static const String modelName = 'gemma-3-27b-it';

  static bool get isConfigured => geminiApiKey.trim().isNotEmpty;
}

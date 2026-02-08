import 'dart:convert';

import 'package:flutter/services.dart';

/// Loads secrets from assets/config/secrets.json (populated by tool/sync_secrets.dart).
/// Call [load] once before runApp (e.g. in main()).
abstract final class SecretsLoader {
  static String? _cachedKey;
  static bool _loaded = false;

  static String? get cachedKey => _cachedKey;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final json = await rootBundle.loadString('assets/config/secrets.json');
      final map = jsonDecode(json) as Map<String, dynamic>?;
      if (map != null && map['GEMINI_API_KEY'] != null) {
        _cachedKey = map['GEMINI_API_KEY'] is String
            ? (map['GEMINI_API_KEY'] as String).trim()
            : map['GEMINI_API_KEY'].toString().trim();
        if (_cachedKey?.isEmpty ?? true) _cachedKey = null;
      }
    } catch (_) {
      _cachedKey = null;
    }
  }
}

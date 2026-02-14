import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/features/chatbot/data/repositories/chatbot_repository.dart';

/// Provider for ChatbotRepository (singleton)
final chatbotRepositoryProvider = Provider<ChatbotRepository>((ref) {
  return ChatbotRepository();
});

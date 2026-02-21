import 'package:lakbyke_mobile/features/chatbot/bot_instructions/instructions.dart';
import 'package:lakbyke_mobile/features/chatbot/domain/models/chatbot_context_builder.dart';

/// Prompt builder for the LakByke chatbot: app instructions and optional user stats.
class ChatbotPromptService {
  /// Builds a prompt for the chatbot.
  ///
  /// [userQuery] - The user's question or message.
  /// [conversationHistory] - Last 5 messages with 'role' and 'text' keys.
  /// [userStatsContext] - Optional formatted "CURRENT USER DATA" block; when non-empty, the bot may use only those values for stats questions.
  static String buildPrompt({
    required String userQuery,
    required List<Map<String, String>> conversationHistory,
    String? userStatsContext,
  }) {
    // Conversation history (last 5 messages)
    String historyBlock = '';
    if (conversationHistory.isNotEmpty) {
      final last5 = conversationHistory.length > 5
          ? conversationHistory.sublist(conversationHistory.length - 5)
          : conversationHistory;
      historyBlock = '\nRECENT CONVERSATION:\n';
      for (final msg in last5) {
        final role = msg['role'] ?? 'Unknown';
        final text = msg['text'] ?? '';
        historyBlock += '[$role]: $text\n';
      }
      historyBlock += 'Use this to keep context (e.g. "it" refers to the previous topic).\n';
    }

    String prompt = '';
    prompt += botInstructionsIdentity;
    prompt += botInstructionsMissionAndScope;
    prompt += ChatbotContextBuilder.buildAppHelpContext();

    if (userStatsContext != null && userStatsContext.isNotEmpty) {
      prompt += botInstructionsUserStatsRule;
      prompt += userStatsContext;
    }

    if (historyBlock.isNotEmpty) {
      prompt += '$historyBlock\n\n';
    }

    prompt += botInstructionsResponseRules;
    prompt += 'USER QUESTION: "$userQuery"\n';

    return prompt;
  }
}

import 'package:lakbyke_mobile/models/chatbot/chatbot_context_builder.dart';

/// Prompt builder for the LakByke chatbot: application instructions and help only.
/// No sensor data, user stats, or environmental impact—strictly app support.
class ChatbotPromptService {
  /// Builds a prompt for app-instructions and help only.
  ///
  /// [userQuery] - The user's question or message.
  /// [conversationHistory] - Last 5 messages with 'role' and 'text' keys.
  static String buildPrompt({
    required String userQuery,
    required List<Map<String, String>> conversationHistory,
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

    // Identity: app instructions and help only
    prompt += 'You are the LakByke support chatbot: a friendly, Taglish-speaking assistant for application instructions and help only. You explain how to use the LakByke app and its purpose. You do not provide live data, sensor readings, or personal stats—only where to find them and how to use the app.\n\n';

    // Mission and in-scope
    prompt += """LAKBYKE (brief):
LakByke is an IoT pedal energy conversion system: cyclists pedal to generate energy, store it in batteries, and use ride-to-earn and charging stations. The mobile app lets users track energy, view battery status, see history, find stations on the map, scan QR at stations, and manage account.

YOU MAY ONLY ANSWER ABOUT:
- How to use the app: Home, Maps, QR, History, Insights, Account.
- Where to find features and what each section does.
- Login, signup, OTP, account settings.
- General LakByke purpose (ride-to-earn, stations, sustainability) in 1–2 sentences when asked.

REFUSAL:
If the question is off-topic (not about LakByke or the app), politely refuse and redirect: "Pasensya na, I can only help with the LakByke app. Ask me where to find something or how to use a feature."

""";

    // App instructions context (from context builder)
    prompt += ChatbotContextBuilder.buildAppHelpContext();

    if (historyBlock.isNotEmpty) {
      prompt += '$historyBlock\n\n';
    }

    prompt += """RESPONSE RULES:
- Answer only the specific question asked. Be concise: 1–3 short sentences.
- Do not add unsolicited detail, extra steps, or lengthy explanations unless the user asks.
- Tone: Taglish, friendly. Use 'po', 'naman', 'pala' where natural.
- No emojis. Plain text only.
- Do not invent or quote sensor values or user stats. Only explain where to find them in the app.

""";

    prompt += 'USER QUESTION: "$userQuery"\n';

    return prompt;
  }
}

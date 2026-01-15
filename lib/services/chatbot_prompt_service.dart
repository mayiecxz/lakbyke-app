import 'package:lakbyke_mobile/models/chatbot_model.dart';

/// Simple prompt builder for chatbot with concise response enforcement.
class ChatbotPromptService {
  /// Builds a complete prompt with response length constraints.
  /// 
  /// [userQuery] - The user's question or message
  /// [bikeData] - Current real-time sensor data
  /// [contextData] - Optional context-specific data (dashboard, history, etc.)
  static String buildPrompt({
    required String userQuery,
    required BikeData bikeData,
    Map<String, dynamic>? contextData,
  }) {
    // Base persona
    String prompt = """
You are si Kleta, the intelligent assistant for 'LakByke', an IoT-integrated pedal energy system.

YOUR IDENTITY:
- You are Kleta, referred to as "si Kleta".
- You are friendly, encouraging, eco-friendly, and helpful.
- You speak in a warm, conversational tone with Filipino cultural elements.

SYSTEM KNOWLEDGE:
- LakByke converts human pedaling via a PMDC motor into electricity.
- Power is stored in a LiFePO4 battery.
- The system can charge small devices like smartphones.
- You promote sustainable mobility and environmental awareness.

COMMUNICATION STYLE:
- Use emojis sparingly (🥰, 🌱, ⚡, 🔋).
- Randomly share sustainability facts when relevant.
- Be encouraging and celebrate achievements.
""";

    // Current sensor data
    prompt += """
CURRENT LIVE SENSOR DATA:
- Voltage: ${bikeData.voltage.toStringAsFixed(1)} V
- Current: ${bikeData.current.toStringAsFixed(1)} A
- Power Output: ${bikeData.power.toStringAsFixed(1)} W
- Battery Level: ${bikeData.batteryLevel}%
- Is Pedaling: ${bikeData.isPedaling ? 'Yes' : 'No'}
""";

    // Add context data if available
    if (contextData != null && contextData.isNotEmpty) {
      prompt += "\nADDITIONAL CONTEXT DATA:\n";
      
      if (contextData.containsKey('totalKwh')) {
        prompt += "- Total kWh Generated: ${contextData['totalKwh']}\n";
      }
      if (contextData.containsKey('totalDistanceKm')) {
        prompt += "- Total Distance: ${contextData['totalDistanceKm']} km\n";
      }
      if (contextData.containsKey('totalRedeems')) {
        prompt += "- Total Redeems: ₱${contextData['totalRedeems']}\n";
      }
      if (contextData.containsKey('totalGenerated')) {
        prompt += "- Total Generated: ${contextData['totalGenerated']} kWh\n";
      }
      if (contextData.containsKey('batteriesExchanged')) {
        prompt += "- Batteries Exchanged: ${contextData['batteriesExchanged']}\n";
      }
    }

    // Response length rules - CRITICAL for concise responses
    prompt += """
RESPONSE LENGTH RULES (STRICTLY FOLLOW):
- DEFAULT: Keep responses to approximately 8 words (one short sentence).
- ONLY provide detailed response (one paragraph maximum, 3-4 sentences) when the query requires:
  * Technical explanations (how something works)
  * Step-by-step instructions
  * Complex data analysis or comparisons
  * Troubleshooting procedures
- After ANY detailed response, always end with: "Need more details?"
- Examples:
  * "How much energy did I generate?" → Concise (8 words): "You generated 2.5 kWh today! ⚡"
  * "Is my battery low?" → Concise (8 words): "Your battery is at 45%, keep pedaling! 🔋"
  * "How do I charge my phone?" → Detailed (paragraph) + "Need more details?"
  * "Why is my power output low?" → Detailed (troubleshooting) + "Need more details?"
- Be concise, friendly, and helpful. Avoid unnecessary elaboration.
""";

    // User query
    prompt += "\nUSER QUESTION: \"$userQuery\"\n";
    prompt += "\nProvide a helpful response following the length rules above.";

    return prompt;
  }
}

import 'package:lakbyke_mobile/models/chatbot/chatbot_context_builder.dart';
import 'package:lakbyke_mobile/models/chatbot/chatbot_model.dart';

/// Prompt builder for chatbot with pre-calculated environmental impact and strict refusal protocols.
class ChatbotPromptService {
  /// Builds a complete prompt with pre-calculated conversions and conversation memory.
  /// 
  /// [userQuery] - The user's question or message
  /// [bikeData] - Current real-time sensor data
  /// [contextData] - Optional context-specific data (home, history, etc.)
  /// [conversationHistory] - Last 5 messages in format List<Map<String, String>> with 'role' and 'text' keys
  static String buildPrompt({
    required String userQuery,
    required BikeData bikeData,
    Map<String, dynamic>? contextData,
    required List<Map<String, String>> conversationHistory,
  }) {
    // STEP 1: Pre-calculate environmental impact (NO LLM MATH)
    double generatedWh = 0.0;
    if (contextData != null) {
      final totalGenerated = contextData['totalGenerated'];
      if (totalGenerated != null) {
        generatedWh = (totalGenerated is num) 
            ? totalGenerated.toDouble() 
            : (totalGenerated is String ? double.tryParse(totalGenerated) ?? 0.0 : 0.0);
      }
    }

    // Formula A: CO2 Saved (kg) = (Generated_Wh / 1000) * 0.7
    final calculatedCO2 = (generatedWh / 1000) * 0.7;

    // Formula B: Phone Charges = Generated_Wh / 19
    final calculatedPhones = generatedWh / 19;

    // Formula C: Car Distance Avoided (km) = (kg_CO2_saved) / 0.15
    final calculatedCarKm = calculatedCO2 / 0.15;

    // STEP 2: Format conversation history (last 5 messages)
    String historyBlock = '';
    if (conversationHistory.isNotEmpty) {
      final last5 = conversationHistory.length > 5 
          ? conversationHistory.sublist(conversationHistory.length - 5)
          : conversationHistory;
      
      historyBlock = '\nRECENT CONVERSATION HISTORY:\n';
      for (final msg in last5) {
        final role = msg['role'] ?? 'Unknown';
        final text = msg['text'] ?? '';
        historyBlock += '[$role]: $text\n';
      }
      historyBlock += 'INSTRUCTION: Use this history to understand context (e.g., "Why is it low?" refers to the previous topic).';
    }

    // STEP 3: Build prompt with strict hierarchy
    String prompt = '';

    // A. Identity & Persona
    prompt += 'You are Si Kleta, the friendly, Taglish-speaking assistant for the LakByke pedal energy system. You are encouraging, like a workout buddy.\n\n';

    // B. Scope of Knowledge (Negative Constraints)
    prompt += """SCOPE OF KNOWLEDGE & REFUSAL:

YOU KNOW: Voltage, Current, Power, Battery Level, Pedaling Status, and Energy stats.

YOU DO NOT KNOW: GPS location, tire pressure, chain health, motor temperature, or weather.

REFUSAL RULE: If asked about 'Unknown' data, you must say: 'Pasensya na, I don't have sensors for that! But I can tell you about your battery.'

ZERO VALUE RULE: If a sensor reads 0 or null, state it is 'currently unavailable' rather than making up a number.

LIVE EFFORT TIMESTAMP RULE: The Live Effort value represents the most recent power generation reading. If the Live Effort Timestamp has not changed for more than 10 seconds, the effort reading may be stale and should be considered as 0 (no current activity).

""";

    // C. Live Sensor Data
    prompt += """CURRENT LIVE SENSOR DATA:
- Voltage: ${bikeData.voltage.toStringAsFixed(1)} V
- Current: ${bikeData.current.toStringAsFixed(1)} A
- Power Output: ${bikeData.power.toStringAsFixed(1)} W
- Battery Level: ${bikeData.batteryLevel}%
- Is Pedaling: ${bikeData.isPedaling ? 'Yes' : 'No'}
""";

    // Add additional context data if available
    prompt += ChatbotContextBuilder.buildContextSection(contextData);

    // D. Pre-Calculated Impact Data (The Truth Source)
    prompt += '\nIMPACT CONTEXT (Use these EXACT values if asked, do not calculate):\n';
    prompt += 'CO2 Saved: ${calculatedCO2.toStringAsFixed(2)} kg\n';
    prompt += 'Smartphone Charges: ${calculatedPhones.toStringAsFixed(1)} full charges\n';
    prompt += 'Driving Offset: ${calculatedCarKm.toStringAsFixed(2)} km\n\n';

    // E. Conversation History
    if (historyBlock.isNotEmpty) {
      prompt += '$historyBlock\n\n';
    }

    // F. Tone & Guidelines
    prompt += """RESPONSE GUIDELINES:

TONE: Use 'Taglish' (mix of English and Tagalog). Use particles like 'naman', 'pala', 'nga', 'po'.

LENGTH: Provide responses in 2-3 sentences. Be informative but concise. Only provide longer explanations if the user specifically asks for 'details' or 'help'.

FORMATTING: Do not use emojis in your responses. Use plain text only.

SAFETY: Never invent sensor readings.

""";

    // G. User Input
    prompt += 'USER QUESTION: "$userQuery"\n';

    return prompt;
  }
}

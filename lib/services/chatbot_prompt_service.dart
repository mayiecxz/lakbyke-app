import 'package:lakbyke_mobile/models/chatbot/chatbot_context_builder.dart';
import 'package:lakbyke_mobile/models/chatbot/chatbot_model.dart';

/// Prompt builder for chatbot with pre-calculated environmental impact and strict refusal protocols.
class ChatbotPromptService {
  /// Builds a complete prompt with pre-calculated conversions and conversation memory.
  /// 
  /// [userQuery] - The user's question or message
  /// [bikeData] - Current real-time sensor data
  /// [contextData] - Optional context-specific data (home, history, etc.)
  /// [conversationHistory] - Last 5 messages in format `List<Map<String, String>>` with 'role' and 'text' keys
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

    // A. Identity & Persona (LakByke support agent)
    prompt += 'You are the LakByke support chatbot: a friendly, Taglish-speaking assistant that helps cyclists with the LakByke app and explains LakByke\'s purpose and features. You are helpful and concise.\n\n';

    // B. LakByke mission, vision, and scope (from project scope/objectives)
    prompt += """LAKBYKE MISSION & VISION:
LakByke is an IoT-integrated pedal energy conversion system that promotes sustainable mobility and renewable energy. It turns bicycle pedaling into electrical energy (PMDC motor), stores it in LiFePO4 batteries, and provides a community-based charging solution. The system includes a ride-to-earn model, solar-supported charging stations, and a mobile app for cyclists to track energy, view battery status, see transaction history, estimate energy yield, and navigate to the nearest LakByke station via map. The goal is to support energy self-sufficiency in urban communities.

IN-SCOPE TOPICS (you may ONLY answer about these):
- LakByke system: pedal energy conversion, storage, charging stations, ride-to-earn, sustainability.
- App support: energy tracking, battery status, transaction history, energy yield estimates, map and station locator, QR scanning, Insights, History, login, account.
- Limitations: low-power DC charging only (no e-bikes/EVs), urban prototype, single-station scale; no fitness tracking.

""";

    // C. SCOPE & REFUSAL (strict)
    prompt += """SCOPE & REFUSAL:
If the user's question is clearly OFF-TOPIC (unrelated to LakByke's mission/vision, system, or app support), you MUST respond with a short, polite refusal and redirect. Example: "Pasensya na, I can only help with LakByke and the app. Ask me about energy tracking, stations, or how LakByke works." Do not answer questions about general knowledge, other products, politics, or unrelated topics.

When the question IS in scope: use the sensor/context data below when relevant (e.g. user asks about their stats). If a sensor reads 0 or null, say it is 'currently unavailable' rather than inventing a number. Do not claim knowledge of GPS, tire pressure, chain health, motor temperature, or weather unless it is from the data provided.

""";

    // D. Live Sensor Data
    prompt += """CURRENT LIVE SENSOR DATA:
- Voltage: ${bikeData.voltage.toStringAsFixed(1)} V
- Current: ${bikeData.current.toStringAsFixed(1)} A
- Power Output: ${bikeData.power.toStringAsFixed(1)} W
- Battery Level: ${bikeData.batteryLevel}%
- Is Pedaling: ${bikeData.isPedaling ? 'Yes' : 'No'}
""";

    // Add additional context data if available
    prompt += ChatbotContextBuilder.buildContextSection(contextData);

    // E. Pre-Calculated Impact Data (The Truth Source)
    prompt += '\nIMPACT CONTEXT (Use these EXACT values if asked, do not calculate):\n';
    prompt += 'CO2 Saved: ${calculatedCO2.toStringAsFixed(2)} kg\n';
    prompt += 'Smartphone Charges: ${calculatedPhones.toStringAsFixed(1)} full charges\n';
    prompt += 'Driving Offset: ${calculatedCarKm.toStringAsFixed(2)} km\n\n';

    // F. Conversation History
    if (historyBlock.isNotEmpty) {
      prompt += '$historyBlock\n\n';
    }

    // G. Tone & Guidelines
    prompt += """RESPONSE GUIDELINES:

TONE: Use 'Taglish' (mix of English and Tagalog). Use particles like 'naman', 'pala', 'nga', 'po'.

LENGTH: Provide responses in 2-3 sentences. Be informative but concise. Only provide longer explanations if the user specifically asks for 'details' or 'help'.

FORMATTING: Do not use emojis in your responses. Use plain text only.

SAFETY: Never invent sensor readings.

""";

    // H. User Input
    prompt += 'USER QUESTION: "$userQuery"\n';

    return prompt;
  }
}

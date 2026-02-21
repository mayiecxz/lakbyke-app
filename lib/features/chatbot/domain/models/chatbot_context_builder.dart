import 'package:lakbyke_mobile/features/chatbot/bot_instructions/instructions.dart';
import 'package:lakbyke_mobile/features/home/domain/models/home_data.dart';

/// Builds context for the LakByke chatbot: app instructions and optional user stats.
class ChatbotContextBuilder {
  /// Returns the app-instructions and help context for the support chatbot.
  static String buildAppHelpContext() => getAppHelpContext();

  /// Formats current user stats for the prompt. Returns empty string if [data] is null.
  /// Use only these values in the prompt; never invent. Handles nulls and stale effort.
  static String buildUserStatsContext(HomeData? data) {
    if (data == null) return '';
    final parts = <String>[];
    if (data.mountBatteryPercentage != null) {
      parts.add('Battery: ${data.mountBatteryPercentage!.toStringAsFixed(0)}%');
    } else {
      parts.add('Battery: N/A');
    }
    parts.add('Today: ${data.todayWh.toStringAsFixed(2)} kWh');
    parts.add('Total generated: ${data.totalGenerated.toStringAsFixed(2)} kWh');
    parts.add('Total redeemed: ${data.totalRedeems.toStringAsFixed(2)} kWh');
    parts.add('Batteries exchanged: ${data.batteriesExchanged}');
    if (data.liveEffort > 0 && !data.isEffortStale) {
      parts.add('Live effort: ${data.liveEffort.toStringAsFixed(0)} W');
    } else {
      parts.add('Live effort: no recent pedal data');
    }
    return 'CURRENT USER DATA (use only these values; never invent):\n${parts.join('. ')}.\n\n';
  }
}

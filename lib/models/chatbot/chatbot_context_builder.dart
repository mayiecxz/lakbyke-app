/// Builds context for the LakByke chatbot strictly for application instructions and help.
/// No user stats, sensor data, or live metrics—only app structure and help topics.
class ChatbotContextBuilder {
  /// Returns the app-instructions and help context for the support chatbot.
  /// Use this so the assistant only answers about the app and how to use it.
  static String buildAppHelpContext() {
    return '''
APP INSTRUCTIONS & HELP CONTEXT (use only this to answer):

LAKBYKE APP SECTIONS:
- Home: View today's energy, total generated, total redeemed; see battery status and live effort when available.
- Maps: Find the nearest LakByke station; view map and get directions to stations.
- QR Scanner: Scan QR codes at LakByke stations for battery exchange or station actions.
- History: View combined history, kWh/energy history, and transaction history.
- Insights: See energy and usage insights.
- Account / Settings: Manage profile, login, sign up, OTP verification, account settings.

HOW TO GUIDE USERS:
- Explain where to find features (e.g. "Go to Home to see your total generated").
- Explain steps in order (e.g. "Open Maps, then tap a station for directions").
- For login/signup: direct to Account or the login/signup screens; mention OTP if needed.
- For stations: direct to Maps and QR; explain ride-to-earn and battery exchange at stations.
- Keep answers focused on app usage only. Do not provide live sensor values or personal stats—only explain where and how to find them in the app.
''';
  }
}

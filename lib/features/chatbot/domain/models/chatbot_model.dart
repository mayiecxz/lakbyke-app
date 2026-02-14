// Chat message model for chatbot. Bike sensor state uses bikeDataProvider (Riverpod).

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}

import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/chatbot_bottom_sheet.dart';

/// Floating Action Button for accessing the chatbot assistant.
/// Follows Material Design guidelines for chat FABs.
class ChatFAB extends StatelessWidget {
  const ChatFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => ChatbotBottomSheet.show(context),
      backgroundColor: Colors.teal,
      tooltip: 'Chat with LakByke Assistant',
      child: const Icon(Icons.chat_bubble, color: Colors.white),
    );
  }
}

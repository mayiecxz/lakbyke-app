import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakbyke_mobile/features/chatbot/domain/models/chatbot_model.dart';

/// Repository for chatbot data persistence (chat history, messages).
class ChatbotRepository {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Save a chat message to Firebase
  Future<void> saveMessage(String text, bool isUser, DateTime time) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return;
      }

      // Create a unique message ID using timestamp and random number
      final messageId = '${time.millisecondsSinceEpoch}_${DateTime.now().microsecond}';
      
      // Save message to chatHistory/{userId}/messages/{messageId}
      await _database.child('chatHistory/$userId/messages/$messageId').set({
        'text': text,
        'isUser': isUser,
        'time': time.millisecondsSinceEpoch,
      });
    } catch (e) {
      // Error saving message to Firebase
    }
  }

  // Load chat history from Firebase
  Future<List<ChatMessage>> loadChatHistory() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return [];
      }

      final snapshot = await _database.child('chatHistory/$userId/messages').get();
      
      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.value;
      if (data == null) return [];

      List<ChatMessage> messages = [];

      // Handle Map structure (each message is a key-value pair)
      if (data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            try {
              final text = value['text'] as String? ?? '';
              final isUser = value['isUser'] as bool? ?? false;
              final timestamp = value['time'] as int? ?? DateTime.now().millisecondsSinceEpoch;
              
              messages.add(ChatMessage(
                text: text,
                isUser: isUser,
                time: DateTime.fromMillisecondsSinceEpoch(timestamp),
              ));
            } catch (e) {
              // Error parsing message
            }
          }
        });
      }

      // Sort messages by time (oldest first)
      messages.sort((a, b) => a.time.compareTo(b.time));

      return messages;
    } catch (e) {
      return [];
    }
  }

  // Delete chat history for a specific user ID
  Future<void> deleteChatHistoryForUser(String userId) async {
    try {
      await _database.child('chatHistory/$userId/messages').remove();
    } catch (e) {
      // Error deleting chat history
    }
  }

  // Delete all chat history for the current user
  Future<void> deleteChatHistory() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      return;
    }
    await deleteChatHistoryForUser(userId);
  }
}

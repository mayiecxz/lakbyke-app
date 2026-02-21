import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakbyke_mobile/features/chatbot/domain/models/chatbot_model.dart';

/// Repository for chatbot data persistence (chat history, messages).
/// Conversation is saved per user: messages are stored under chatHistory/{userId}/messages
/// where [userId] is the current Firebase Auth UID, so each signed-in user has isolated history.
class ChatbotRepository {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current user ID (Firebase Auth UID). Chat history is isolated per user.
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Saves a chat message to Firebase for the current user.
  Future<void> saveMessage(String text, bool isUser, DateTime time) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return;
      }

      final messageId = '${time.millisecondsSinceEpoch}_${DateTime.now().microsecond}';
      
      // Per-user path: chatHistory/{userId}/messages/{messageId}
      await _database.child('chatHistory/$userId/messages/$messageId').set({
        'text': text,
        'isUser': isUser,
        'time': time.millisecondsSinceEpoch,
      });
    } catch (e, st) {
      debugPrint('ChatbotRepository.saveMessage: $e');
      debugPrint(st.toString());
    }
  }

  /// Loads chat history from Firebase for the current user only.
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
              debugPrint('ChatbotRepository.loadChatHistory: parse error for $key: $e');
            }
          }
        });
      }

      // Sort messages by time (oldest first)
      messages.sort((a, b) => a.time.compareTo(b.time));

      return messages;
    } catch (e, st) {
      debugPrint('ChatbotRepository.loadChatHistory: $e');
      debugPrint(st.toString());
      return [];
    }
  }

  // Delete chat history for a specific user ID
  Future<void> deleteChatHistoryForUser(String userId) async {
    try {
      await _database.child('chatHistory/$userId/messages').remove();
    } catch (e, st) {
      debugPrint('ChatbotRepository.deleteChatHistoryForUser: $e');
      debugPrint(st.toString());
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

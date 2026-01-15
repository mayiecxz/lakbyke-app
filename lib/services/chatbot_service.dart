import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakbyke_mobile/models/chatbot_model.dart';

class ChatbotService {
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
        print('No user logged in, cannot save message');
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

      print('Message saved to Firebase: $messageId');
    } catch (e) {
      print('Error saving message to Firebase: $e');
    }
  }

  // Load chat history from Firebase
  Future<List<ChatMessage>> loadChatHistory() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        print('No user logged in, cannot load chat history');
        return [];
      }

      final snapshot = await _database.child('chatHistory/$userId/messages').get();
      
      if (!snapshot.exists) {
        print('No chat history found for user');
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
              print('Error parsing message $key: $e');
            }
          }
        });
      }

      // Sort messages by time (oldest first)
      messages.sort((a, b) => a.time.compareTo(b.time));

      print('Loaded ${messages.length} messages from Firebase');
      return messages;
    } catch (e) {
      print('Error loading chat history: $e');
      return [];
    }
  }

  // Delete chat history for a specific user ID
  Future<void> deleteChatHistoryForUser(String userId) async {
    try {
      await _database.child('chatHistory/$userId/messages').remove();
      print('Chat history deleted for user: $userId');
    } catch (e) {
      print('Error deleting chat history: $e');
    }
  }

  // Delete all chat history for the current user
  Future<void> deleteChatHistory() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      print('No user logged in, cannot delete chat history');
      return;
    }
    await deleteChatHistoryForUser(userId);
  }
}

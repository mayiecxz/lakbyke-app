import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _userBubbleColor = Color(0xFF0F8A8A);
const _botBubbleColor = Color(0xFFE8F5F5);
const _bubbleRadius = 18.0;
const _avatarSize = 32.0;

/// Single chat message bubble for the chatbot bottom sheet (user or bot).
class SheetChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime time;

  const SheetChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.time,
  });

  Widget _avatar(bool isUser) {
    return CircleAvatar(
      radius: _avatarSize / 2,
      backgroundColor: isUser ? _userBubbleColor.withValues(alpha: 0.9) : _botBubbleColor,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy_rounded,
        size: 18,
        color: isUser ? Colors.white : _userBubbleColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _avatar(isUser),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? _userBubbleColor : _botBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(_bubbleRadius),
                  topRight: const Radius.circular(_bubbleRadius),
                  bottomLeft: Radius.circular(isUser ? _bubbleRadius : 6),
                  bottomRight: Radius.circular(isUser ? 6 : _bubbleRadius),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15, height: 1.35),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(time),
                        style: TextStyle(fontSize: 11, color: isUser ? Colors.white70 : Colors.black54),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.done_all, size: 14, color: Colors.white70),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _avatar(isUser),
        ],
      ),
    );
  }
}

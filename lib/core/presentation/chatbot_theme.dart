import 'package:flutter/material.dart';

/// Centralized UI constants for the LakByke chatbot (screen and bottom sheet).
abstract final class ChatbotTheme {
  static const Color userBubbleColor = Color(0xFF0F8A8A);
  static const Color botBubbleColor = Color(0xFFE8F5F5);
  static const Color gradientStart = Color(0xFFE0F7FA);
  static const Color gradientEnd = Color(0xFFB2DFDB);
  static const Color inputBg = Color(0xFFF5F5F5);
  static const Color progressBarBg = Color(0xFFE0F2F1);

  static const double bubbleRadius = 18.0;
  static const double avatarSize = 32.0;

  /// Bot profile image (square-cropped in UI via CircleAvatar + BoxFit.cover).
  static const String botProfileAsset = 'assets/images/chatbot_profile.png';
}

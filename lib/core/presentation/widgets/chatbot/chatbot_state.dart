// File: lib/core/presentation/chatbot_state.dart
import 'package:flutter/material.dart';

/// Global notifier to track if the Chatbot FAB is currently visible on screen.
final ValueNotifier<bool> isChatbotVisible = ValueNotifier<bool>(true);
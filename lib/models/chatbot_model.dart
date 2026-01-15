import 'package:flutter/material.dart';

// ---------------------------------------------------------
// 1. DATA MODEL & STATE MANAGEMENT (The "Bike's Brain")
// ---------------------------------------------------------

class BikeData extends ChangeNotifier {
  // In a real app, these values would come from your ESP32 via Firebase/MQTT
  double voltage = 12.5; // Volts
  double current = 1.2;  // Amps
  int batteryLevel = 45; // Percentage
  bool isPedaling = true;

  // Calculates power (P = V * I)
  double get power => voltage * current;

  // Simulate data changes for this demo
  void simulateDataChange() {
    voltage = 12.0 + (DateTime.now().second % 3);
    current = 0.5 + (DateTime.now().second % 2);
    batteryLevel = (batteryLevel + 1).clamp(0, 100);
    notifyListeners();
  }
}

// ---------------------------------------------------------
// 2. CHAT MESSAGE MODEL
// ---------------------------------------------------------

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}
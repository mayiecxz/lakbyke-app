import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/services/home.dart';
import 'dart:async';

// ---------------------------------------------------------
// 1. DATA MODEL & STATE MANAGEMENT (The "Bike's Brain")
// ---------------------------------------------------------

class BikeData extends ChangeNotifier {
  final HomeService _homeService = HomeService();
  StreamSubscription<Map<String, dynamic>?>? _dataSubscription;

  // Real-time sensor data from Firebase
  double voltage = 0.0; // Volts (default, will be updated from Firebase)
  double current = 0.0; // Amps (default, will be updated from Firebase)
  int batteryLevel = 0; // Percentage (default, will be updated from Firebase)
  bool isPedaling = true;

  // Calculates power (P = V * I)
  double get power => voltage * current;

  BikeData() {
    _initializeDataStream();
  }

  // Initialize real-time data stream from Firebase
  void _initializeDataStream() {
    _dataSubscription = _homeService.getHomeDataStream().listen(
      (data) {
        if (data != null) {
          _updateFromFirebaseData(data);
        }
      },
      onError: (error) {
        // Error in BikeData stream
      },
    );
  }

  // Check if data is stale (same timestamp for more than 60 seconds)
  // bool _isDataStale(Map<String, dynamic> data) {
  //   final timestampStr =
  //       data['timestamp'] as String? ?? data['liveEffortTimestamp'] as String?;
  //   if (timestampStr == null) return true;

  //   try {
  //     final timestamp = DateTime.parse(timestampStr);
  //     final secondsSinceUpdate = DateTime.now().difference(timestamp).inSeconds;
  //     return secondsSinceUpdate > 60;
  //   } catch (e) {
  //     return true;
  //   }
  // }

  // Update values from Firebase deviceEnergyData
  void _updateFromFirebaseData(Map<String, dynamic> data) {
    // Check if data is stale
    // final isStale = _isDataStale(data);

    // Battery level from mountBatteryPercentage
    final batteryValue = data['mountBatteryPercentage'];
    if (batteryValue != null) {
      batteryLevel = batteryValue is int
          ? batteryValue
          : (batteryValue as num).toInt().clamp(0, 100);
    }

    // Power from powerGeneratedInWatts or liveEffort
    final powerValue = data['powerGeneratedInWatts'] ?? data['liveEffort'];
    if (powerValue != null) {
      final powerWatts = powerValue is num
          ? powerValue.toDouble()
          : (powerValue is String ? double.tryParse(powerValue) ?? 0.0 : 0.0);

      // Calculate voltage and current from power
      // Assuming typical LiFePO4 battery: ~12.8V nominal, 13.2V when charging
      // If power > 0 and not stale, assume pedaling is happening
      if (powerWatts > 0 /*&& !isStale*/) {
        isPedaling = true;
        // Estimate voltage based on battery level (12.0V at 0%, 13.2V at 100%)
        voltage = 12.0 + (batteryLevel / 100.0) * 1.2;
        // Calculate current from power and voltage (I = P / V)
        current = powerWatts / voltage;
      } else {
        // Not pedaling if power is 0 or data is stale
        isPedaling = false;
        // When not pedaling, use nominal voltage
        voltage = 12.0 + (batteryLevel / 100.0) * 1.2;
        current = 0.0;
      }
    } else {
      // No power data, not pedaling
      isPedaling = false;
      voltage = 12.0 + (batteryLevel / 100.0) * 1.2;
      current = 0.0;
    }

    notifyListeners();
  }

  // Simulate data changes for testing (kept for backward compatibility)
  void simulateDataChange() {
    voltage = 12.0 + (DateTime.now().second % 3);
    current = 0.5 + (DateTime.now().second % 2);
    batteryLevel = (batteryLevel + 1).clamp(0, 100);
    notifyListeners();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/features/home/providers/home_providers.dart';
import 'package:lakbyke_mobile/features/home/domain/models/home_data.dart';

/// State class for bike sensor data
class BikeDataState {
  final double voltage;
  final double current;
  final int batteryLevel;
  final bool isPedaling;
  
  BikeDataState({
    required this.voltage,
    required this.current,
    required this.batteryLevel,
    required this.isPedaling,
  });
  
  double get power => voltage * current;
  
  factory BikeDataState.initial() {
    return BikeDataState(
      voltage: 0.0,
      current: 0.0,
      batteryLevel: 0,
      isPedaling: false,
    );
  }
  
  BikeDataState copyWith({
    double? voltage,
    double? current,
    int? batteryLevel,
    bool? isPedaling,
  }) {
    return BikeDataState(
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isPedaling: isPedaling ?? this.isPedaling,
    );
  }
}

/// Provider for bike sensor data - watches homeDataStreamProvider
/// This REPLACES BikeData ChangeNotifier and eliminates duplicate Firebase listener
final bikeDataProvider = StateNotifierProvider<BikeDataNotifier, BikeDataState>((ref) {
  return BikeDataNotifier(ref);
});

class BikeDataNotifier extends StateNotifier<BikeDataState> {
  final Ref _ref;
  
  BikeDataNotifier(this._ref) : super(BikeDataState.initial()) {
    // Watch the homeDataStreamProvider (SINGLE Firebase listener)
    _ref.listen(homeDataStreamProvider, (previous, next) {
      next.whenData((homeData) {
        if (homeData != null) {
          _updateFromHomeData(homeData);
        }
      });
    });
  }
  
  void _updateFromHomeData(HomeData data) {
    final batteryValue = data.mountBatteryPercentage;
    final batteryLevel = batteryValue != null 
        ? batteryValue.toInt().clamp(0, 100)
        : 0;
    
    final powerValue = data.liveEffort;
    
    // Calculate voltage and current from power
    // Assuming typical LiFePO4 battery: ~12.8V nominal, 13.2V when charging
    bool isPedaling = false;
    double voltage = 12.0 + (batteryLevel / 100.0) * 1.2;
    double current = 0.0;
    
    if (powerValue > 0 && !(data.isEffortStale)) {
      isPedaling = true;
      voltage = 12.0 + (batteryLevel / 100.0) * 1.2;
      current = powerValue / voltage;
    } else {
      isPedaling = false;
      voltage = 12.0 + (batteryLevel / 100.0) * 1.2;
      current = 0.0;
    }
    
    state = BikeDataState(
      voltage: voltage,
      current: current,
      batteryLevel: batteryLevel,
      isPedaling: isPedaling,
    );
  }
  
  /// Simulate data changes for testing (kept for backward compatibility)
  void simulateDataChange() {
    final now = DateTime.now();
    state = state.copyWith(
      voltage: 12.0 + (now.second % 3).toDouble(),
      current: 0.5 + (now.second % 2).toDouble(),
      batteryLevel: (state.batteryLevel + 1).clamp(0, 100),
    );
  }
}

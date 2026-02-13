/// Domain model for home screen data
class HomeData {
  final double? mountBatteryPercentage;
  final double? speedKmh;
  final double? mountVoltage;
  final double? mAh;
  final bool? isMotorRunning;
  final double liveEffort;
  final DateTime? liveEffortTimestamp;
  final double todayDistance;
  final double todayWh;
  final double totalRedeems;
  final double totalGenerated;
  final int batteriesExchanged;
  final String? timestamp;

  HomeData({
    this.mountBatteryPercentage,
    this.speedKmh,
    this.mountVoltage,
    this.mAh,
    this.isMotorRunning,
    required this.liveEffort,
    this.liveEffortTimestamp,
    required this.todayDistance,
    required this.todayWh,
    required this.totalRedeems,
    required this.totalGenerated,
    required this.batteriesExchanged,
    this.timestamp,
  });

  factory HomeData.fromMap(Map<String, dynamic> map) {
    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    double? toDoubleOrNull(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int? toIntOrNull(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    bool? toBoolOrNull(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true' || lower == '1') return true;
        if (lower == 'false' || lower == '0') return false;
      }
      if (value is int) return value != 0;
      return null;
    }

    return HomeData(
      mountBatteryPercentage: toDoubleOrNull(map['mountBatteryPercentage']),
      speedKmh: toDoubleOrNull(map['speedKmh']),
      mountVoltage: toDoubleOrNull(map['mountVoltage']),
      mAh: toDoubleOrNull(map['mAh']),
      isMotorRunning: toBoolOrNull(map['isMotorRunning']),
      liveEffort: toDoubleOrNull(map['liveEffort']) ?? toDoubleOrNull(map['powerGeneratedInWatts']) ?? 0.0,
      liveEffortTimestamp: parseTimestamp(map['liveEffortTimestamp']),
      todayDistance: toDoubleOrNull(map['todayDistance']) ?? 0.0,
      todayWh: toDoubleOrNull(map['todayWh']) ?? 0.0,
      totalRedeems: toDoubleOrNull(map['totalRedeems']) ?? 0.0,
      totalGenerated: toDoubleOrNull(map['totalGenerated']) ?? 0.0,
      batteriesExchanged: toIntOrNull(map['batteriesExchanged']) ?? 0,
      timestamp: map['timestamp'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mountBatteryPercentage': mountBatteryPercentage,
      'speedKmh': speedKmh,
      'mountVoltage': mountVoltage,
      'mAh': mAh,
      'isMotorRunning': isMotorRunning,
      'liveEffort': liveEffort,
      'liveEffortTimestamp': liveEffortTimestamp?.toIso8601String(),
      'todayDistance': todayDistance,
      'todayWh': todayWh,
      'totalRedeems': totalRedeems,
      'totalGenerated': totalGenerated,
      'batteriesExchanged': batteriesExchanged,
      'timestamp': timestamp,
    };
  }

  bool get isEffortStale {
    if (liveEffortTimestamp == null) return true;
    final secondsSinceUpdate = DateTime.now().difference(liveEffortTimestamp!).inSeconds;
    return secondsSinceUpdate > 60;
  }

  HomeData copyWith({
    double? mountBatteryPercentage,
    double? speedKmh,
    double? mountVoltage,
    double? mAh,
    bool? isMotorRunning,
    double? liveEffort,
    DateTime? liveEffortTimestamp,
    double? todayDistance,
    double? todayWh,
    double? totalRedeems,
    double? totalGenerated,
    int? batteriesExchanged,
    String? timestamp,
  }) {
    return HomeData(
      mountBatteryPercentage: mountBatteryPercentage ?? this.mountBatteryPercentage,
      speedKmh: speedKmh ?? this.speedKmh,
      mountVoltage: mountVoltage ?? this.mountVoltage,
      mAh: mAh ?? this.mAh,
      isMotorRunning: isMotorRunning ?? this.isMotorRunning,
      liveEffort: liveEffort ?? this.liveEffort,
      liveEffortTimestamp: liveEffortTimestamp ?? this.liveEffortTimestamp,
      todayDistance: todayDistance ?? this.todayDistance,
      todayWh: todayWh ?? this.todayWh,
      totalRedeems: totalRedeems ?? this.totalRedeems,
      totalGenerated: totalGenerated ?? this.totalGenerated,
      batteriesExchanged: batteriesExchanged ?? this.batteriesExchanged,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

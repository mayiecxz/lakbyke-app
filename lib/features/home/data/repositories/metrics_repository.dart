import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakbyke_mobile/core/services/service_tag.dart';

/// Repository for device energy metrics (today/yesterday totals).
/// Extracted from HomeRepository so each responsibility has its own class.
class MetricsRepository {
  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  MetricsRepository({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  })  : _database = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<String?> getServiceTag() => getServiceTagFromFirebase(_auth, _database);

  /// Resolve the device data map for the current user's service tag.
  Map<String, dynamic>? _findDeviceData(
    Map<String, dynamic> deviceData,
    String serviceTag,
    String cleanServiceTag,
  ) {
    if (deviceData.containsKey(serviceTag)) {
      return Map<String, dynamic>.from(deviceData[serviceTag] as Map);
    } else if (deviceData.containsKey(cleanServiceTag)) {
      return Map<String, dynamic>.from(deviceData[cleanServiceTag] as Map);
    } else {
      for (final entry in deviceData.entries) {
        final cleanDeviceId =
            entry.key.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
        if (cleanDeviceId == cleanServiceTag) {
          return Map<String, dynamic>.from(entry.value as Map);
        }
      }
    }
    return null;
  }

  /// Sum distance and Wh for sessions matching [matchDate].
  Map<String, double> _sumForDate(
    Map<String, dynamic> targetDeviceData,
    DateTime matchDate,
  ) {
    double distance = 0.0;
    double wh = 0.0;

    for (final entry in targetDeviceData.entries) {
      if (entry.value is! Map) continue;
      final sessionData = Map<String, dynamic>.from(entry.value as Map);
      final timestamp = sessionData['timestamp'];
      if (timestamp is String) {
        try {
          final time = DateTime.parse(timestamp);
          if (time.year == matchDate.year &&
              time.month == matchDate.month &&
              time.day == matchDate.day) {
            final d = sessionData['totalDistanceKm'];
            if (d != null) {
              distance += (d is num)
                  ? d.toDouble()
                  : (double.tryParse(d.toString()) ?? 0.0);
            }
            final w = sessionData['totalWh'];
            if (w != null) {
              wh += (w is num)
                  ? w.toDouble()
                  : (double.tryParse(w.toString()) ?? 0.0);
            }
          }
        } catch (_) {}
      }
    }
    return {'distance': distance, 'wh': wh};
  }

  /// Get today's totals (distance, Wh) from deviceEnergyData.
  Future<Map<String, double>> getTodayData() async {
    try {
      final serviceTag = await getServiceTag();
      if (serviceTag == null) return {'todayDistance': 0.0, 'todayWh': 0.0};

      final cleanServiceTag =
          serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
      final snapshot = await _database.ref('deviceEnergyData').get();
      if (!snapshot.exists) return {'todayDistance': 0.0, 'todayWh': 0.0};

      final data = snapshot.value;
      if (data is! Map) return {'todayDistance': 0.0, 'todayWh': 0.0};

      final deviceData = Map<String, dynamic>.from(data);
      final targetDeviceData =
          _findDeviceData(deviceData, serviceTag, cleanServiceTag);
      if (targetDeviceData == null) {
        return {'todayDistance': 0.0, 'todayWh': 0.0};
      }

      final result = _sumForDate(targetDeviceData, DateTime.now());
      return {
        'todayDistance': result['distance']!,
        'todayWh': result['wh']!,
      };
    } catch (e) {
      return {'todayDistance': 0.0, 'todayWh': 0.0};
    }
  }

  /// Get yesterday's totals (distance, Wh) from deviceEnergyData.
  Future<Map<String, dynamic>> getYesterdayData() async {
    try {
      final serviceTag = await getServiceTag();
      if (serviceTag == null) {
        return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};
      }

      final cleanServiceTag =
          serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
      final snapshot = await _database.ref('deviceEnergyData').get();
      if (!snapshot.exists) {
        return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};
      }

      final data = snapshot.value;
      if (data is! Map) {
        return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};
      }

      final deviceData = Map<String, dynamic>.from(data);
      final targetDeviceData =
          _findDeviceData(deviceData, serviceTag, cleanServiceTag);
      if (targetDeviceData == null) {
        return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};
      }

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = _sumForDate(targetDeviceData, yesterday);
      return {
        'yesterdayDistance': result['distance']!,
        'yesterdayWh': result['wh']!,
      };
    } catch (e) {
      return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};
    }
  }
}

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeMetricsService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? getCurrentUserId() => _auth.currentUser?.uid;

  DateTime? _parseIsoTimestamp(String? timestampStr) {
    if (timestampStr == null || timestampStr.isEmpty) return null;
    try {
      return DateTime.parse(timestampStr);
    } catch (e) {
      return null;
    }
  }

  bool _isToday(DateTime timestamp) {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  bool _isYesterday(DateTime timestamp) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return timestamp.year == yesterday.year &&
        timestamp.month == yesterday.month &&
        timestamp.day == yesterday.day;
  }

  // Returns: {yesterdayDistance: double, yesterdayWh: double}
  Future<Map<String, dynamic>> getYesterdayData() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};
      }

      final serviceTagSnapshot = await _database.child('userTable/$userId/serviceTag').get();
      if (!serviceTagSnapshot.exists) {
        return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};
      }

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) {
        return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};
      }

      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();

      final snapshot = await _database.child('deviceEnergyData').get();

      if (!snapshot.exists) {
        return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};
      }

      final data = snapshot.value;
      if (data == null || data is! Map<Object?, Object?>) {
        return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};
      }

      double yesterdayDistance = 0.0;
      double yesterdayWh = 0.0;

      data.forEach((deviceId, deviceData) {
        if (deviceData is Map<Object?, Object?>) {
          final document = Map<String, dynamic>.from(
            deviceData.map((key, value) => MapEntry(key.toString(), value)),
          );

          final mntTag = (document['mntTag'] as String?) ?? '';
          final cleanMntTag = mntTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
          if (cleanMntTag != cleanServiceTag) return;

          final timestampStr = document['timestamp'] as String?;
          final timestamp = _parseIsoTimestamp(timestampStr);

          if (timestamp != null && _isYesterday(timestamp)) {
            final distance = document['totalDistanceKm'];
            if (distance != null) {
              final distanceValue = (distance is num)
                  ? distance.toDouble()
                  : (distance is String)
                      ? double.tryParse(distance) ?? 0.0
                      : 0.0;
              yesterdayDistance += distanceValue;
            }

            final totalWh = document['totalWh'];
            if (totalWh != null) {
              final whValue = (totalWh is num)
                  ? totalWh.toDouble()
                  : (totalWh is String)
                      ? double.tryParse(totalWh) ?? 0.0
                      : 0.0;
              yesterdayWh += whValue;
            }
          }
        }
      });

      return {'yesterdayDistance': yesterdayDistance, 'yesterdayWh': yesterdayWh};
    } catch (e) {
      return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};
    }
  }

  // Returns: {todayDistance: double, todayWh: double}
  Future<Map<String, dynamic>> getTodayData() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return {'todayDistance': 0.0, 'todayWh': 0.0};
      }

      final serviceTagSnapshot = await _database.child('userTable/$userId/serviceTag').get();
      if (!serviceTagSnapshot.exists) {
        return {'todayDistance': 0.0, 'todayWh': 0.0};
      }

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) {
        return {'todayDistance': 0.0, 'todayWh': 0.0};
      }

      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();

      final snapshot = await _database.child('deviceEnergyData').get();

      if (!snapshot.exists) {
        return {'todayDistance': 0.0, 'todayWh': 0.0};
      }

      final data = snapshot.value;
      if (data == null || data is! Map<Object?, Object?>) {
        return {'todayDistance': 0.0, 'todayWh': 0.0};
      }

      double todayDistance = 0.0;
      double todayWh = 0.0;

      data.forEach((deviceId, deviceData) {
        if (deviceData is Map<Object?, Object?>) {
          final document = Map<String, dynamic>.from(
            deviceData.map((key, value) => MapEntry(key.toString(), value)),
          );

          final mntTag = (document['mntTag'] as String?) ?? '';
          final cleanMntTag = mntTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
          if (cleanMntTag != cleanServiceTag) return;

          final timestampStr = document['timestamp'] as String?;
          final timestamp = _parseIsoTimestamp(timestampStr);

          if (timestamp != null && _isToday(timestamp)) {
            final distance = document['totalDistanceKm'];
            if (distance != null) {
              final distanceValue = (distance is num)
                  ? distance.toDouble()
                  : (distance is String)
                      ? double.tryParse(distance) ?? 0.0
                      : 0.0;
              todayDistance += distanceValue;
            }

            final totalWh = document['totalWh'];
            if (totalWh != null) {
              final whValue = (totalWh is num)
                  ? totalWh.toDouble()
                  : (totalWh is String)
                      ? double.tryParse(totalWh) ?? 0.0
                      : 0.0;
              todayWh += whValue;
            }
          }
        }
      });

      return {'todayDistance': todayDistance, 'todayWh': todayWh};
    } catch (e) {
      return {'todayDistance': 0.0, 'todayWh': 0.0};
    }
  }

  Future<Map<String, dynamic>?> getTodayMetrics() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return null;

      final serviceTagSnapshot = await _database.child('userTable/$userId/serviceTag').get();
      if (!serviceTagSnapshot.exists) return null;

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) return null;

      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();

      final snapshot = await _database.child('deviceEnergyData').get();

      if (snapshot.exists) {
        final data = snapshot.value;

        if (data is Map<Object?, Object?>) {
          Map<String, dynamic>? latestDocument;
          DateTime? latestTimestamp;

          data.forEach((deviceId, deviceData) {
            if (deviceData is Map<Object?, Object?>) {
              final document = Map<String, dynamic>.from(
                deviceData.map((key, value) => MapEntry(key.toString(), value)),
              );

              final mntTag = (document['mntTag'] as String?) ?? '';
              final cleanMntTag = mntTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
              if (cleanMntTag != cleanServiceTag) return;

              final timestampStr = document['timestamp'] as String?;
              final timestamp = _parseIsoTimestamp(timestampStr);

              if (timestamp != null) {
                if (latestTimestamp == null || timestamp.isAfter(latestTimestamp!)) {
                  latestTimestamp = timestamp;
                  latestDocument = document;
                }
              } else if (latestDocument == null) {
                latestDocument = document;
              }
            }
          });

          if (latestDocument != null) {
            final result = Map<String, dynamic>.from(latestDocument!);
            return result;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

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

  /// Normalize Firebase snapshot value to Map<String, dynamic> (handles any Map type from RTDB).
  Map<String, dynamic>? _toMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return null;
  }

  /// Get sessions for device: try deviceEnergyData/{serviceTag} then full tree by clean ID match.
  Future<List<Map<String, dynamic>>> _getSessionsForDevice(String serviceTag, String cleanServiceTag) async {
    final deviceRef = _database.child('deviceEnergyData');
    final directSnapshot = await deviceRef.child(serviceTag).get();
    if (directSnapshot.exists) {
      final sessionsMap = _toMap(directSnapshot.value);
      if (sessionsMap != null && sessionsMap.isNotEmpty) {
        return sessionsMap.values.map((v) => _toMap(v)).whereType<Map<String, dynamic>>().toList();
      }
    }
    final fullSnapshot = await deviceRef.get();
    if (!fullSnapshot.exists) return [];
    final root = _toMap(fullSnapshot.value);
    if (root == null) return [];
    for (final entry in root.entries) {
      final cleanDeviceId = entry.key.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
      if (cleanDeviceId != cleanServiceTag) continue;
      final sessionsMap = _toMap(entry.value);
      if (sessionsMap != null) {
        return sessionsMap.values.map((v) => _toMap(v)).whereType<Map<String, dynamic>>().toList();
      }
    }
    return [];
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
      final sessions = await _getSessionsForDevice(serviceTag, cleanServiceTag);

      double yesterdayDistance = 0.0;
      double yesterdayWh = 0.0;
      for (final document in sessions) {
        final timestamp = _parseIsoTimestamp(document['timestamp'] as String?);
        if (timestamp != null && _isYesterday(timestamp)) {
          final distance = document['totalDistanceKm'];
          if (distance != null) {
            yesterdayDistance += (distance is num) ? distance.toDouble() : (double.tryParse(distance.toString()) ?? 0.0);
          }
          final totalWh = document['totalWh'];
          if (totalWh != null) {
            yesterdayWh += (totalWh is num) ? totalWh.toDouble() : (double.tryParse(totalWh.toString()) ?? 0.0);
          }
        }
      }

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
      final sessions = await _getSessionsForDevice(serviceTag, cleanServiceTag);

      double todayDistance = 0.0;
      double todayWh = 0.0;
      for (final document in sessions) {
        final timestamp = _parseIsoTimestamp(document['timestamp'] as String?);
        if (timestamp != null && _isToday(timestamp)) {
          final distance = document['totalDistanceKm'];
          if (distance != null) {
            todayDistance += (distance is num) ? distance.toDouble() : (double.tryParse(distance.toString()) ?? 0.0);
          }
          final totalWh = document['totalWh'];
          if (totalWh != null) {
            todayWh += (totalWh is num) ? totalWh.toDouble() : (double.tryParse(totalWh.toString()) ?? 0.0);
          }
        }
      }

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
      final sessions = await _getSessionsForDevice(serviceTag, cleanServiceTag);
      if (sessions.isEmpty) return null;

      Map<String, dynamic>? latestDoc;
      DateTime? latestTs;
      for (final doc in sessions) {
        final ts = _parseIsoTimestamp(doc['timestamp'] as String?);
        if (ts != null && (latestTs == null || ts.isAfter(latestTs))) {
          latestTs = ts;
          latestDoc = doc;
        } else if (latestDoc == null) latestDoc = doc;
      }
      if (latestDoc != null) return Map<String, dynamic>.from(latestDoc);
      return null;
    } catch (e) {
      return null;
    }
  }
}

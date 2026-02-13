import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:lakbyke_mobile/services/home/metrics_service.dart';
import 'package:lakbyke_mobile/services/transaction/transaction_service.dart';
import 'package:lakbyke_mobile/services/energy/kwh_service.dart';

class HomeService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final HomeMetricsService _metricsService = HomeMetricsService();
  final TransactionService _transactionService = TransactionService();
  final KwhService _kwhService = KwhService();

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Delegate metric methods to HomeMetricsService
  Future<Map<String, dynamic>> getYesterdayData() => _metricsService.getYesterdayData();
  Future<Map<String, dynamic>> getTodayData() => _metricsService.getTodayData();
  Future<Map<String, dynamic>?> getTodayMetrics() => _metricsService.getTodayMetrics();

  // Delegate transaction aggregates to TransactionService
  Future<double> getTotalRedeems() => _transactionService.getTotalRedeemed();
  Future<double> getTotalGenerated() => _transactionService.getTotalGenerated();
  Future<int> getBatteriesExchanged() => _transactionService.getBatteryExchangeCount();

  // Get user's service tag via KwhService (single source)
  Future<String?> getServiceTag() => _kwhService.getServiceTag();

  // Parse ISO 8601 timestamp string to DateTime
  DateTime? _parseIsoTimestamp(String? timestampStr) {
    if (timestampStr == null || timestampStr.isEmpty) return null;
    try {
      return DateTime.parse(timestampStr);
    } catch (e) {
      return null;
    }
  }

  // Check if timestamp is today
  bool _isToday(DateTime timestamp) {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  /// Normalize Firebase snapshot value to a map we can iterate (handles Map<String,dynamic> etc.).
  Map<String, dynamic>? _toMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  /// True if [map] is a single live doc (homescreen live: flat fields under deviceId).
  /// Live doc has "timestamp" and no session-id keys (no keys starting with '-').
  bool _isLiveDoc(Map<String, dynamic> map) {
    if (!map.containsKey('timestamp')) return false;
    return !map.keys.any((k) => k.toString().startsWith('-'));
  }

  /// Get data for the user's device from deviceEnergyData.
  /// Supports two structures:
  /// - Homescreen live: deviceEnergyData/{deviceId} = { timestamp, mountBatteryPercentage, speedKmh, mAh, ... } (flat).
  /// - Session-based: deviceEnergyData/{deviceId}/{sessionId} = { ... }.
  /// Returns a list of one doc for live, or many session docs for session-based.
  Future<List<Map<String, dynamic>>> _getSessionsForDevice(String serviceTag, String cleanServiceTag) async {
    final deviceRef = _database.child('deviceEnergyData');
    for (final key in [serviceTag, cleanServiceTag]) {
      if (key.isEmpty) continue;
      final directSnapshot = await deviceRef.child(key).get();
      if (directSnapshot.exists) {
        final data = _toMap(directSnapshot.value);
        if (data != null && data.isNotEmpty) {
          if (_isLiveDoc(data)) return [Map<String, dynamic>.from(data)];
          return _sessionsMapToList(data);
        }
      }
    }
    final fullSnapshot = await deviceRef.get();
    if (!fullSnapshot.exists) return [];
    final root = _toMap(fullSnapshot.value);
    if (root == null) return [];
    for (final entry in root.entries) {
      final deviceId = entry.key;
      final cleanDeviceId = deviceId.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
      if (cleanDeviceId != cleanServiceTag) continue;
      final data = _toMap(entry.value);
      if (data != null) {
        if (_isLiveDoc(data)) return [Map<String, dynamic>.from(data)];
        return _sessionsMapToList(data);
      }
      return [];
    }
    return [];
  }

  List<Map<String, dynamic>> _sessionsMapToList(Map<String, dynamic> sessionsMap) {
    final list = <Map<String, dynamic>>[];
    for (final entry in sessionsMap.entries) {
      final sessionDoc = _toMap(entry.value);
      if (sessionDoc != null) list.add(sessionDoc);
    }
    return list;
  }

  /// Parse mountBatteryPercentage from session doc (int, double, or string from Firebase).
  int? _parseBatteryPercentage(dynamic value) {
    if (value == null) return null;
    if (value is int) return value.clamp(0, 100);
    if (value is num) return value.round().clamp(0, 100);
    if (value is String) return int.tryParse(value)?.clamp(0, 100);
    return null;
  }

  /// Parse double from session doc (for speedKmh, mountVoltage, mAh, etc.).
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Parse bool from session doc (for isMotorRunning).
  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    if (value is num) return value != 0;
    return false;
  }

  /// Copy latest-session sensor fields into [target] for UI access.
  void _applyLatestSessionSensors(Map<String, dynamic> target, Map<String, dynamic> latestDoc) {
    final speedKmh = _parseDouble(latestDoc['speedKmh']);
    if (speedKmh != null) target['speedKmh'] = speedKmh;
    final mountVoltage = _parseDouble(latestDoc['mountVoltage']);
    if (mountVoltage != null) target['mountVoltage'] = mountVoltage;
    final mAh = _parseDouble(latestDoc['mAh']);
    if (mAh != null) target['mAh'] = mAh;
    target['isMotorRunning'] = _parseBool(latestDoc['isMotorRunning']);
  }

  /// Get the latest battery percentage from deviceEnergyData for the current user's device (by serviceTag).
  /// Structure: deviceEnergyData/{deviceId}/{sessionId} with mountBatteryPercentage in each session.
  Future<int?> getLatestBatteryPercentage() async {
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
      if (latestDoc == null) return null;
      return _parseBatteryPercentage(latestDoc['mountBatteryPercentage']);
    } catch (e) {
      return null;
    }
  }

  // Get latest effort (powerGeneratedInWatts) with timestamp for live indicator
  Future<Map<String, dynamic>?> getLatestEffort() async {
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
      if (latestDoc != null && latestTs != null) {
        final effort = latestDoc['powerGeneratedInWatts'];
        final effortValue = (effort is num) ? effort.toDouble() : (effort is String) ? double.tryParse(effort) ?? 0.0 : 0.0;
        return {'effort': effortValue, 'timestamp': latestTs};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get home data for the current user (consolidates latest session + today's metrics + transaction aggregates)
  // Structure: deviceEnergyData/{deviceId}/{sessionId} = { timestamp, totalWh, totalDistanceKm, powerGeneratedInWatts, ... }
  Future<Map<String, dynamic>?> getHomeData() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return null;

      final serviceTagSnapshot = await _database.child('userTable/$userId/serviceTag').get();
      if (!serviceTagSnapshot.exists) return null;

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) return null;

      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
      final sessions = await _getSessionsForDevice(serviceTag, cleanServiceTag);

      Map<String, dynamic> homeData = {};

      if (sessions.isNotEmpty) {
        Map<String, dynamic>? latestDoc;
        DateTime? latestTs;
        for (final doc in sessions) {
          final ts = _parseIsoTimestamp(doc['timestamp'] as String?);
          if (ts != null && (latestTs == null || ts.isAfter(latestTs))) {
            latestTs = ts;
            latestDoc = doc;
          } else if (latestDoc == null) latestDoc = doc;
        }
        if (latestDoc != null) {
          homeData = Map<String, dynamic>.from(latestDoc);
          // Battery: latest session (home screen shows latest battery)
          final batt = _parseBatteryPercentage(latestDoc['mountBatteryPercentage']);
          if (batt != null) homeData['mountBatteryPercentage'] = batt;
          // Explicit sensor fields for UI: speedKmh, mountVoltage, mAh (double), isMotorRunning
          _applyLatestSessionSensors(homeData, latestDoc);
        }
      }

      // Today's metrics: aggregate distance and Wh from today's sessions only
      double todayDistance = 0.0;
      double todayWh = 0.0;
      for (final doc in sessions) {
        final ts = _parseIsoTimestamp(doc['timestamp'] as String?);
        if (ts != null && _isToday(ts)) {
          final d = doc['totalDistanceKm'];
          final w = doc['totalWh'];
          if (d != null) todayDistance += (d is num) ? d.toDouble() : (double.tryParse(d.toString()) ?? 0.0);
          if (w != null) todayWh += (w is num) ? w.toDouble() : (double.tryParse(w.toString()) ?? 0.0);
        }
      }
      homeData['todayDistance'] = todayDistance;
      homeData['todayWh'] = todayWh;

      // Fetch transaction aggregates via TransactionService
      final totalRedeems = await getTotalRedeems();
      homeData['totalRedeems'] = totalRedeems;

      final totalGenerated = await getTotalGenerated();
      homeData['totalGenerated'] = totalGenerated;

      final batteriesExchanged = await getBatteriesExchanged();
      homeData['batteriesExchanged'] = batteriesExchanged;

      // Consolidate live effort
      final powerWatts = homeData['powerGeneratedInWatts'];
      if (powerWatts != null) {
        final effortValue = (powerWatts is num)
            ? powerWatts.toDouble()
            : (powerWatts is String ? double.tryParse(powerWatts) ?? 0.0 : 0.0);
        homeData['liveEffort'] = effortValue;
      } else {
        homeData['liveEffort'] = 0.0;
      }

      final latestEffort = await getLatestEffort();
      if (latestEffort != null && latestEffort['timestamp'] != null) {
        homeData['liveEffortTimestamp'] = latestEffort['timestamp'];
      }

      // Ensure battery percentage from latest session (structure: device -> sessions -> session doc)
      final latestBattery = await getLatestBatteryPercentage();
      if (latestBattery != null) homeData['mountBatteryPercentage'] = latestBattery;

      return homeData;
    } catch (e) {
      return null;
    }
  }

  // Check if data is stale (same timestamp for more than 10 seconds)
  bool isDataStale(Map<String, dynamic>? data) {
    if (data == null) return true;

    final timestampStr = data['timestamp'] as String?;
    if (timestampStr == null) return true;

    final timestamp = _parseIsoTimestamp(timestampStr);
    if (timestamp == null) return true;

    final secondsSinceUpdate = DateTime.now().difference(timestamp).inSeconds;
    return secondsSinceUpdate > 10;
  }

  // Stream home data for real-time updates
  Stream<Map<String, dynamic>?> getHomeDataStream() {
    final userId = getCurrentUserId();
    if (userId == null) {
      return Stream.value(null);
    }

    return Stream.fromFuture(_database.child('userTable/$userId/serviceTag').get(),)
        .asyncExpand((serviceTagSnapshot) {
      if (!serviceTagSnapshot.exists) {
        return Stream.value(null);
      }

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) {
        return Stream.value(null);
      }

      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();

      return _database.child('deviceEnergyData').onValue.asyncMap((event) async {
        if (event.snapshot.exists) {
          final data = _toMap(event.snapshot.value);
          if (data == null) return null;

          List<Map<String, dynamic>> allSessionsForDevice = [];
          // 1) Try direct key (homescreen live: deviceEnergyData/MNT0001 = flat doc, or session-based)
          final deviceData = _toMap(data[serviceTag]) ?? _toMap(data[cleanServiceTag]);
          if (deviceData != null && deviceData.isNotEmpty) {
            if (_isLiveDoc(deviceData)) {
              allSessionsForDevice = [Map<String, dynamic>.from(deviceData)];
            } else {
              allSessionsForDevice = _sessionsMapToList(deviceData);
            }
          } else {
            // 2) Find device by clean ID match
            for (final entry in data.entries) {
              final deviceId = entry.key;
              final cleanDeviceId = deviceId.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
              if (cleanDeviceId != cleanServiceTag) continue;
              final deviceDataEntry = _toMap(entry.value);
              if (deviceDataEntry != null) {
                if (_isLiveDoc(deviceDataEntry)) {
                  allSessionsForDevice = [Map<String, dynamic>.from(deviceDataEntry)];
                } else {
                  allSessionsForDevice = _sessionsMapToList(deviceDataEntry);
                }
                break;
              }
            }
          }

          if (allSessionsForDevice.isEmpty) return null;

          Map<String, dynamic>? latestDocument;
          DateTime? latestTimestamp;
          for (final doc in allSessionsForDevice) {
            final ts = _parseIsoTimestamp(doc['timestamp'] as String?);
            if (ts != null && (latestTimestamp == null || ts.isAfter(latestTimestamp))) {
              latestTimestamp = ts;
              latestDocument = doc;
            } else if (latestDocument == null) latestDocument = doc;
          }

          if (latestDocument != null) {
            final result = Map<String, dynamic>.from(latestDocument);

            // Battery from latest session
            final batt = _parseBatteryPercentage(latestDocument['mountBatteryPercentage']);
            if (batt != null) result['mountBatteryPercentage'] = batt;
            // Sensor fields for UI: speedKmh, mountVoltage, mAh (double), isMotorRunning
            _applyLatestSessionSensors(result, latestDocument);

            final powerWatts = result['powerGeneratedInWatts'];
            if (powerWatts != null) {
              final effortValue = (powerWatts is num)
                  ? powerWatts.toDouble()
                  : (powerWatts is String ? double.tryParse(powerWatts) ?? 0.0 : 0.0);
              result['liveEffort'] = effortValue;
            } else {
              result['liveEffort'] = 0.0;
            }

            if (latestTimestamp != null) {
              result['liveEffortTimestamp'] = latestTimestamp;
            }

            double todayDistance = 0.0;
            double todayWh = 0.0;

            for (final doc in allSessionsForDevice) {
              final timestampStr = doc['timestamp'] as String?;
              final timestamp = _parseIsoTimestamp(timestampStr);

              if (timestamp != null && _isToday(timestamp)) {
                final distance = doc['totalDistanceKm'];
                if (distance != null) {
                  final distanceValue = (distance is num)
                      ? distance.toDouble()
                      : (distance is String)
                          ? double.tryParse(distance) ?? 0.0
                          : 0.0;
                  todayDistance += distanceValue;
                }

                final totalWh = doc['totalWh'];
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

            result['todayDistance'] = todayDistance;
            result['todayWh'] = todayWh;

            return result;
          }
        }
        return null;
      }).handleError((error) {
        throw error;
      });
    });
  }
}

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

      final snapshot = await _database.child('deviceEnergyData').get();

      if (!snapshot.exists) return null;

      final data = snapshot.value;
      if (data == null || data is! Map<Object?, Object?>) return null;

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

      if (latestDocument != null && latestTimestamp != null) {
        final doc = latestDocument!;
        final effort = doc['powerGeneratedInWatts'];
        final effortValue = (effort is num) ? effort.toDouble() : (effort is String) ? double.tryParse(effort) ?? 0.0 : 0.0;

        return {'effort': effortValue, 'timestamp': latestTimestamp!};
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Get home data for the current user (consolidates latest device doc + today's metrics + transaction aggregates)
  Future<Map<String, dynamic>?> getHomeData() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return null;

      final serviceTagSnapshot = await _database.child('userTable/$userId/serviceTag').get();
      if (!serviceTagSnapshot.exists) return null;

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) return null;

      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();

      final snapshot = await _database.child('deviceEnergyData').get();

      Map<String, dynamic> homeData = {};

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
            homeData = Map<String, dynamic>.from(latestDocument!);
          }
        }
      }

      // Fetch today's aggregated data via metrics service
      final todayData = await getTodayData();
      homeData['todayDistance'] = todayData['todayDistance'];
      homeData['todayWh'] = todayData['todayWh'];

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
          final data = event.snapshot.value;

          Map<String, dynamic>? latestDocument;
          DateTime? latestTimestamp;
          List<Map<String, dynamic>> allMatchingDevices = [];

          if (data is Map<Object?, Object?>) {
            data.forEach((deviceId, deviceData) {
              if (deviceData is Map<Object?, Object?>) {
                final document = Map<String, dynamic>.from(
                  deviceData.map((key, value) => MapEntry(key.toString(), value)),
                );

                final mntTag = (document['mntTag'] as String?) ?? '';
                final cleanMntTag = mntTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
                if (cleanMntTag != cleanServiceTag) return;

                allMatchingDevices.add(document);

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
          }

          if (latestDocument != null) {
            final result = Map<String, dynamic>.from(latestDocument!);

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

            for (final doc in allMatchingDevices) {
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

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakbyke_mobile/features/home/domain/models/home_data.dart';
import 'package:lakbyke_mobile/services/transaction/transaction_service.dart';
import 'dart:async';

/// Repository for home screen data operations.
/// This consolidates logic from HomeService, MetricsService, and KwhService.
/// SINGLE INSTANCE provides ONE Firebase listener for the entire app.
class HomeRepository {
  final FirebaseDatabase _database;
  final FirebaseAuth _auth;
  final TransactionService _transactionService;

  HomeRepository({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
    TransactionService? transactionService,
  })  : _database = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _transactionService = transactionService ?? TransactionService();

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get user's service tag
  Future<String?> getServiceTag() async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final snapshot = await _database.ref('userTable/$userId/serviceTag').get();
      if (snapshot.exists) {
        return snapshot.value as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Stream of home data - THIS IS THE SINGLE FIREBASE LISTENER
  /// All consumers (HomeScreen, BikeData, etc.) watch this ONE stream
  Stream<HomeData?> getHomeDataStream() async* {
    final userId = currentUserId;
    if (userId == null) {
      yield null;
      return;
    }

    // Get service tag first
    final serviceTag = await getServiceTag();
    if (serviceTag == null || serviceTag.isEmpty) {
      yield null;
      return;
    }

    final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();

    // Single Firebase listener on deviceEnergyData
    await for (final event in _database.ref('deviceEnergyData').onValue) {
      if (!event.snapshot.exists) {
        yield null;
        continue;
      }

      try {
        final data = event.snapshot.value;
        if (data is! Map) {
          yield null;
          continue;
        }

        final Map<String, dynamic> deviceData = Map<String, dynamic>.from(data as Map);
        
        // Find device data by service tag
        Map<String, dynamic>? targetDeviceData;
        if (deviceData.containsKey(serviceTag)) {
          targetDeviceData = Map<String, dynamic>.from(deviceData[serviceTag] as Map);
        } else if (deviceData.containsKey(cleanServiceTag)) {
          targetDeviceData = Map<String, dynamic>.from(deviceData[cleanServiceTag] as Map);
        } else {
          // Search by clean ID
          for (final entry in deviceData.entries) {
            final deviceId = entry.key;
            final cleanDeviceId = deviceId.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
            if (cleanDeviceId == cleanServiceTag) {
              targetDeviceData = Map<String, dynamic>.from(entry.value as Map);
              break;
            }
          }
        }

        if (targetDeviceData == null) {
          yield null;
          continue;
        }

        // Extract latest session data
        Map<String, dynamic> latestSession = {};
        if (targetDeviceData.containsKey('timestamp')) {
          // Flat structure (live data)
          latestSession = targetDeviceData;
        } else {
          // Session-based structure - find latest
          DateTime? latestTime;
          for (final entry in targetDeviceData.entries) {
            if (entry.value is! Map) continue;
            final sessionData = Map<String, dynamic>.from(entry.value as Map);
            final timestamp = sessionData['timestamp'];
            if (timestamp is String) {
              try {
                final time = DateTime.parse(timestamp);
                if (latestTime == null || time.isAfter(latestTime)) {
                  latestTime = time;
                  latestSession = sessionData;
                }
              } catch (_) {}
            }
          }
        }

        // Calculate today's totals
        final now = DateTime.now();
        double todayDistance = 0.0;
        double todayWh = 0.0;

        for (final entry in targetDeviceData.entries) {
          if (entry.value is! Map) continue;
          final sessionData = Map<String, dynamic>.from(entry.value as Map);
          final timestamp = sessionData['timestamp'];
          if (timestamp is String) {
            try {
              final time = DateTime.parse(timestamp);
              if (time.year == now.year && time.month == now.month && time.day == now.day) {
                final distance = sessionData['totalDistanceKm'];
                if (distance != null) {
                  todayDistance += (distance is num) ? distance.toDouble() : (double.tryParse(distance.toString()) ?? 0.0);
                }
                final wh = sessionData['totalWh'];
                if (wh != null) {
                  todayWh += (wh is num) ? wh.toDouble() : (double.tryParse(wh.toString()) ?? 0.0);
                }
              }
            } catch (_) {}
          }
        }

        // Get transaction data using existing service
        double totalRedeems = 0.0;
        double totalGenerated = 0.0;
        int batteriesExchanged = 0;
        
        try {
          totalRedeems = await _transactionService.getTotalRedeemed();
          totalGenerated = await _transactionService.getTotalGenerated();
          batteriesExchanged = await _transactionService.getBatteryExchangeCount();
        } catch (_) {
          // Use defaults
        }

        latestSession['todayDistance'] = todayDistance;
        latestSession['todayWh'] = todayWh;
        latestSession['totalRedeems'] = totalRedeems;
        latestSession['totalGenerated'] = totalGenerated;
        latestSession['batteriesExchanged'] = batteriesExchanged;

        yield HomeData.fromMap(latestSession);
      } catch (e) {
        yield null;
      }
    }
  }

  /// Get one-time snapshot of home data
  Future<HomeData?> getHomeData() async {
    await for (final data in getHomeDataStream().take(1)) {
      return data;
    }
    return null;
  }

  /// Get yesterday's data
  Future<Map<String, dynamic>> getYesterdayData() async {
    try {
      final serviceTag = await getServiceTag();
      if (serviceTag == null) return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};

      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
      final snapshot = await _database.ref('deviceEnergyData').get();

      if (!snapshot.exists) return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      double yesterdayDistance = 0.0;
      double yesterdayWh = 0.0;

      final data = snapshot.value;
      if (data is Map) {
        final deviceData = Map<String, dynamic>.from(data as Map);
        Map<String, dynamic>? targetDeviceData;
        
        if (deviceData.containsKey(serviceTag)) {
          targetDeviceData = Map<String, dynamic>.from(deviceData[serviceTag] as Map);
        } else if (deviceData.containsKey(cleanServiceTag)) {
          targetDeviceData = Map<String, dynamic>.from(deviceData[cleanServiceTag] as Map);
        } else {
          for (final entry in deviceData.entries) {
            final deviceId = entry.key;
            final cleanDeviceId = deviceId.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
            if (cleanDeviceId == cleanServiceTag) {
              targetDeviceData = Map<String, dynamic>.from(entry.value as Map);
              break;
            }
          }
        }

        if (targetDeviceData != null) {
          for (final entry in targetDeviceData.entries) {
            if (entry.value is! Map) continue;
            final sessionData = Map<String, dynamic>.from(entry.value as Map);
            final timestamp = sessionData['timestamp'];
            if (timestamp is String) {
              try {
                final time = DateTime.parse(timestamp);
                if (time.year == yesterday.year && time.month == yesterday.month && time.day == yesterday.day) {
                  final distance = sessionData['totalDistanceKm'];
                  if (distance != null) {
                    yesterdayDistance += (distance is num) ? distance.toDouble() : (double.tryParse(distance.toString()) ?? 0.0);
                  }
                  final wh = sessionData['totalWh'];
                  if (wh != null) {
                    yesterdayWh += (wh is num) ? wh.toDouble() : (double.tryParse(wh.toString()) ?? 0.0);
                  }
                }
              } catch (_) {}
            }
          }
        }
      }

      return {
        'yesterdayDistance': yesterdayDistance,
        'yesterdayWh': yesterdayWh,
      };
    } catch (e) {
      return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};
    }
  }
}

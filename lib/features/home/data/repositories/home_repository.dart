import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakbyke_mobile/core/data/service_tag.dart';
import 'package:lakbyke_mobile/features/home/domain/models/home_data.dart';
import 'package:lakbyke_mobile/features/history/data/repositories/transaction_repository.dart';
import 'package:lakbyke_mobile/features/home/data/repositories/metrics_repository.dart';

/// Repository for home screen data operations.
/// Composes TransactionRepository (aggregates) and MetricsRepository (today/yesterday).
/// SINGLE INSTANCE provides ONE Firebase listener for the entire app.
/// Includes a 30-second in-memory cache for one-shot reads.
class HomeRepository {
  final FirebaseDatabase _database;
  final FirebaseAuth _auth;
  final TransactionRepository _transactionRepository;
  final MetricsRepository _metricsRepository;

  /// In-memory cache (30s TTL)
  HomeData? _cachedData;
  DateTime? _lastFetch;
  static const _cacheTtl = Duration(seconds: 30);

  HomeRepository({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
    required TransactionRepository transactionRepository,
    required MetricsRepository metricsRepository,
  })  : _database = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _transactionRepository = transactionRepository,
        _metricsRepository = metricsRepository;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get user's service tag (single source: core/data/service_tag.dart)
  Future<String?> getServiceTag() => getServiceTagFromFirebase(_auth, _database);

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

        final Map<String, dynamic> deviceData = Map<String, dynamic>.from(data);
        
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

        // Get transaction data from single source (TransactionRepository)
        double totalRedeems = 0.0;
        double totalGenerated = 0.0;
        int batteriesExchanged = 0;
        
        try {
          totalRedeems = await _transactionRepository.getTotalRedeemed();
          totalGenerated = await _transactionRepository.getTotalGenerated();
          batteriesExchanged = await _transactionRepository.getBatteryExchangeCount();
        } catch (_) {
          // Use defaults
        }

        latestSession['todayDistance'] = todayDistance;
        latestSession['todayWh'] = todayWh;
        latestSession['totalRedeems'] = totalRedeems;
        latestSession['totalGenerated'] = totalGenerated;
        latestSession['batteriesExchanged'] = batteriesExchanged;

        final homeData = HomeData.fromMap(latestSession);
        // Update cache on every stream emission
        _cachedData = homeData;
        _lastFetch = DateTime.now();
        yield homeData;
      } catch (e) {
        yield null;
      }
    }
  }

  /// Get one-time snapshot of home data (returns cache if fresh).
  Future<HomeData?> getHomeData() async {
    if (_cachedData != null && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!) < _cacheTtl) {
        return _cachedData;
      }
    }
    await for (final data in getHomeDataStream().take(1)) {
      return data;
    }
    return null;
  }

  /// Delegate yesterday's data to MetricsRepository
  Future<Map<String, dynamic>> getYesterdayData() =>
      _metricsRepository.getYesterdayData();
}

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakbyke_mobile/core/data/service_tag.dart';

/// Repository for energy/kWh history operations
class KwhRepository {
  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  KwhRepository({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  })  : _database = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<String?> getServiceTag() => getServiceTagFromFirebase(_auth, _database);

  DateTime? _parseTimestamp(String timestampStr) {
    if (timestampStr.isEmpty) return null;
    
    try {
      if (timestampStr.contains('T') || timestampStr.contains('Z')) {
        return DateTime.parse(timestampStr);
      }
      
      final parts = timestampStr.split(' ');
      if (parts.length != 2) return null;
      
      final dateParts = parts[0].split('-');
      final timeParts = parts[1].split(':');
      
      if (dateParts.length != 3 || timeParts.length != 3) return null;
      
      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getHistoryData() async {
    try {
      final serviceTag = await getServiceTag();
      if (serviceTag == null || serviceTag.isEmpty) return [];

      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
      final snapshot = await _database.ref('deviceEnergyHistory').get();

      if (!snapshot.exists) return [];

      final data = snapshot.value;
      if (data is! Map) return [];

      final deviceData = Map<String, dynamic>.from(data);
      final historyRecords = <Map<String, dynamic>>[];

      for (final deviceEntry in deviceData.entries) {
        final deviceId = deviceEntry.key;
        final cleanDeviceId = deviceId.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
        
        if (cleanDeviceId != cleanServiceTag) continue;

        final deviceValue = deviceEntry.value;
        if (deviceValue is! Map) continue;

        final deviceSessions = Map<String, dynamic>.from(deviceValue);

        for (final sessionEntry in deviceSessions.entries) {
          final sessionData = sessionEntry.value;
          if (sessionData is! Map) continue;

          final session = Map<String, dynamic>.from(sessionData);
          final timestampStr = session['timestamp'] as String?;
          
          if (timestampStr != null) {
            final timestamp = _parseTimestamp(timestampStr);
            if (timestamp != null) {
              session['timestamp'] = timestamp;
              // Support both totalDistanceKM and totalDistanceKm (Firebase key casing)
              final distance = session['totalDistanceKM'] ?? session['totalDistanceKm'];
              session['totalDistanceKm'] = distance;
              final totalWh = session['totalWh'];
              final totalDistanceKm = distance;
              
              if (totalWh != null || totalDistanceKm != null) {
                historyRecords.add(session);
              }
            }
          }
        }
      }

      historyRecords.sort((a, b) {
        final aTime = a['timestamp'] as DateTime?;
        final bTime = b['timestamp'] as DateTime?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return historyRecords;
    } catch (e) {
      return [];
    }
  }

  /// Returns all records that fall within the specified date range for detail modals.
  Future<List<Map<String, dynamic>>> getDetailedRecordsForPeriod({
    required DateTime periodDate,
    required String filterType,
  }) async {
    try {
      final allRecords = await getHistoryData();
      if (allRecords.isEmpty) return [];

      final periodRecords = <Map<String, dynamic>>[];

      for (final record in allRecords) {
        final recordDate = record['timestamp'] as DateTime?;
        if (recordDate == null) continue;

        bool isInPeriod = false;
        switch (filterType) {
          case 'daily':
            isInPeriod = recordDate.year == periodDate.year &&
                recordDate.month == periodDate.month &&
                recordDate.day == periodDate.day;
            break;
          case 'weekly':
            final weekStart = DateTime(periodDate.year, periodDate.month, periodDate.day);
            final weekEnd = weekStart.add(const Duration(days: 6));
            isInPeriod = recordDate.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
                recordDate.isBefore(weekEnd.add(const Duration(days: 1)));
            break;
          case 'monthly':
            isInPeriod = recordDate.year == periodDate.year &&
                recordDate.month == periodDate.month;
            break;
          case 'yearly':
            isInPeriod = recordDate.year == periodDate.year;
            break;
          default:
            isInPeriod = false;
        }
        if (isInPeriod) periodRecords.add(record);
      }
      periodRecords.sort((a, b) {
        final aTime = a['timestamp'] as DateTime?;
        final bTime = b['timestamp'] as DateTime?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });
      return periodRecords;
    } catch (e) {
      return [];
    }
  }

  Future<double> getTotalKwhGenerated() async {
    try {
      final history = await getHistoryData();
      double total = 0.0;
      
      for (final record in history) {
        final wh = record['totalWh'];
        if (wh != null) {
          total += (wh is num) ? wh.toDouble() : (double.tryParse(wh.toString()) ?? 0.0);
        }
      }
      
      return total / 1000; // Convert Wh to kWh
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> getTotalDistanceKm() async {
    try {
      final history = await getHistoryData();
      double total = 0.0;
      
      for (final record in history) {
        final distance = record['totalDistanceKm'];
        if (distance != null) {
          total += (distance is num) ? distance.toDouble() : (double.tryParse(distance.toString()) ?? 0.0);
        }
      }
      
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> getAggregatedData(String filter) async {
    try {
      final history = await getHistoryData();
      if (history.isEmpty) return [];

      final aggregated = <DateTime, Map<String, double>>{};

      for (final record in history) {
        final timestamp = record['timestamp'] as DateTime?;
        if (timestamp == null) continue;

        final wh = (record['totalWh'] is num) 
            ? (record['totalWh'] as num).toDouble() 
            : (double.tryParse(record['totalWh'].toString()) ?? 0.0);
        final distance = (record['totalDistanceKm'] is num)
            ? (record['totalDistanceKm'] as num).toDouble()
            : (double.tryParse(record['totalDistanceKm'].toString()) ?? 0.0);

        DateTime key;
        switch (filter) {
          case 'daily':
            key = DateTime(timestamp.year, timestamp.month, timestamp.day);
            break;
          case 'weekly':
            // Monday of the week for this timestamp (weekday: 1=Monday, 7=Sunday)
            final daysToMonday = timestamp.weekday - 1;
            final monday = timestamp.subtract(Duration(days: daysToMonday));
            key = DateTime(monday.year, monday.month, monday.day);
            break;
          case 'monthly':
            key = DateTime(timestamp.year, timestamp.month);
            break;
          case 'yearly':
            key = DateTime(timestamp.year);
            break;
          default:
            key = DateTime(timestamp.year, timestamp.month, timestamp.day);
        }

        if (!aggregated.containsKey(key)) {
          aggregated[key] = {'wh': 0.0, 'distance': 0.0};
        }
        aggregated[key]!['wh'] = (aggregated[key]!['wh'] ?? 0.0) + wh;
        aggregated[key]!['distance'] = (aggregated[key]!['distance'] ?? 0.0) + distance;
      }

      return aggregated.entries
          .map((e) => {
                'date': e.key,
                'wh': e.value['wh'],
                'distance': e.value['distance'],
              })
          .toList()
        ..sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    } catch (e) {
      return [];
    }
  }
}

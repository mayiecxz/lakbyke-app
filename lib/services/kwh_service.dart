import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KwhService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Get user's service tag
  Future<String?> getServiceTag() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return null;

      final snapshot = await _database.child('userTable/$userId/serviceTag').get();
      
      if (snapshot.exists) {
        return snapshot.value as String?;
      }
      
      return null;
    } catch (e) {
      print('Error fetching service tag: $e');
      return null;
    }
  }

  // Parse timestamp string to DateTime
  DateTime? _parseTimestamp(String timestampStr) {
    try {
      // Format: "1970-01-01 08:00:05"
      final parts = timestampStr.split(' ');
      if (parts.length != 2) return null;
      
      final dateParts = parts[0].split('-');
      final timeParts = parts[1].split(':');
      
      if (dateParts.length != 3 || timeParts.length != 3) return null;
      
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = int.parse(timeParts[2]);
      
      return DateTime(year, month, day, hour, minute, second);
    } catch (e) {
      print('Error parsing timestamp: $timestampStr - $e');
      return null;
    }
  }

  // Get all history data for the current user's device
  Future<List<Map<String, dynamic>>> getHistoryData() async {
    try {
      final serviceTag = await getServiceTag();
      if (serviceTag == null || serviceTag.isEmpty) {
        print('Service tag not found for user');
        return [];
      }

      // Clean service tag: remove spaces and dashes, convert to uppercase
      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
      
      print('Fetching kWh history for service tag: "$serviceTag" (cleaned: "$cleanServiceTag")');

      // Fetch all records from deviceHistoryData/{serviceTag}
      final snapshot = await _database.child('deviceHistoryData/$cleanServiceTag').get();
      
      if (!snapshot.exists) {
        print('No history data found for service tag: "$cleanServiceTag"');
        return [];
      }

      final data = snapshot.value;
      if (data == null) return [];

      List<Map<String, dynamic>> historyRecords = [];

      // Handle both Map and List structures
      if (data is Map<Object?, Object?>) {
        data.forEach((recordId, recordData) {
          if (recordData is Map<Object?, Object?>) {
            final record = Map<String, dynamic>.from(
              recordData.map((key, value) => MapEntry(key.toString(), value)),
            );
            
            // Extract timestamp and totalKwh
            final timestampStr = record['timestamp'] as String?;
            final totalKwh = record['totalKwh'];
            
            if (timestampStr != null && totalKwh != null) {
              final timestamp = _parseTimestamp(timestampStr);
              if (timestamp != null) {
                final kwhValue = (totalKwh is num) ? totalKwh.toDouble() : 
                               (totalKwh is String) ? double.tryParse(totalKwh) ?? 0.0 : 0.0;
                
                historyRecords.add({
                  'timestamp': timestamp,
                  'totalKwh': kwhValue,
                  'recordId': recordId.toString(),
                });
              }
            }
          }
        });
      }

      // Sort by timestamp descending (most recent first)
      historyRecords.sort((a, b) => 
        (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime)
      );

      print('Fetched ${historyRecords.length} history records');
      return historyRecords;
    } catch (e) {
      print('Error fetching history data: $e');
      return [];
    }
  }

  // Get aggregated data by filter type (daily, weekly, monthly, yearly)
  Future<List<Map<String, dynamic>>> getAggregatedData(String filterType) async {
    try {
      final historyRecords = await getHistoryData();
      if (historyRecords.isEmpty) return [];

      final aggregated = <DateTime, double>{};

      for (final record in historyRecords) {
        final timestamp = record['timestamp'] as DateTime;
        final kwhValue = record['totalKwh'] as double;

        DateTime key;
        switch (filterType) {
          case 'daily':
            key = DateTime(timestamp.year, timestamp.month, timestamp.day);
            break;
          case 'weekly':
            // Week starting Monday
            final weekStart = timestamp.subtract(Duration(days: timestamp.weekday - 1));
            key = DateTime(weekStart.year, weekStart.month, weekStart.day);
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

        aggregated[key] = (aggregated[key] ?? 0.0) + kwhValue;
      }

      // Convert to list and format
      final entries = aggregated.entries.map((e) {
        final DateTime dt = e.key;
        String label;
        
        String monthName(int m) {
          const names = [
            '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ];
          return names[m];
        }

        switch (filterType) {
          case 'daily':
            label = '${monthName(dt.month)} ${dt.day}, ${dt.year}';
            break;
          case 'weekly':
            final end = dt.add(const Duration(days: 6));
            label = '${monthName(dt.month)} ${dt.day}-${end.day} ${end.year}';
            break;
          case 'monthly':
            label = '${monthName(dt.month)} ${dt.year}';
            break;
          case 'yearly':
            label = '${dt.year}';
            break;
          default:
            label = '${monthName(dt.month)} ${dt.day}, ${dt.year}';
        }

        return {
          'label': label,
          'value': e.value,
          'date': dt,
        };
      }).toList();

      // Sort descending by date (most recent first)
      entries.sort((a, b) => 
        (b['date'] as DateTime).compareTo(a['date'] as DateTime)
      );

      return entries;
    } catch (e) {
      print('Error aggregating data: $e');
      return [];
    }
  }

  // Get total kWh generated across all records
  Future<double> getTotalKwhGenerated() async {
    try {
      final historyRecords = await getHistoryData();
      if (historyRecords.isEmpty) return 0.0;

      double total = 0.0;
      for (final record in historyRecords) {
        total += record['totalKwh'] as double;
      }

      return total;
    } catch (e) {
      print('Error calculating total kWh: $e');
      return 0.0;
    }
  }
}

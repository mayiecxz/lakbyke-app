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
  // Supports both ISO 8601 format ("2025-10-22T20:04:07.346Z") and legacy format ("1970-01-01 08:00:05")
  DateTime? _parseTimestamp(String timestampStr) {
    if (timestampStr.isEmpty) return null;
    
    try {
      // Try ISO 8601 format first (e.g., "2025-10-22T20:04:07.346Z")
      if (timestampStr.contains('T') || timestampStr.contains('Z')) {
        return DateTime.parse(timestampStr);
      }
      
      // Fallback to legacy format: "1970-01-01 08:00:05"
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
  // Data is stored in deviceEnergyData/{serviceTag}/{document_id}/[fields]
  Future<List<Map<String, dynamic>>> getHistoryData() async {
    try {
      final serviceTag = await getServiceTag();
      if (serviceTag == null || serviceTag.isEmpty) {
        print('Service tag not found for user');
        return [];
      }

      // Clean service tag: remove spaces and dashes, convert to uppercase
      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
      
      print('Fetching Wh history for service tag: "$serviceTag" (cleaned: "$cleanServiceTag")');

      // Fetch all records from deviceEnergyData/{serviceTag} (nested structure)
      final snapshot = await _database.child('deviceEnergyData/$cleanServiceTag').get();
      
      if (!snapshot.exists) {
        print('No history data found for service tag: "$cleanServiceTag"');
        return [];
      }

      final data = snapshot.value;
      if (data == null) return [];

      List<Map<String, dynamic>> historyRecords = [];

      // Handle nested structure: deviceEnergyData/{serviceTag}/{document_id}/[fields]
      if (data is Map<Object?, Object?>) {
        data.forEach((documentId, documentData) {
          if (documentData is Map<Object?, Object?>) {
            final record = Map<String, dynamic>.from(
              documentData.map((key, value) => MapEntry(key.toString(), value)),
            );
            
            // Extract timestamp and totalWh
            final timestampStr = record['timestamp'] as String?;
            final totalWh = record['totalWh'];
            
            if (timestampStr != null && totalWh != null) {
              final timestamp = _parseTimestamp(timestampStr);
              if (timestamp != null) {
                double whValue = (totalWh is num) ? totalWh.toDouble() : 
                               (totalWh is String) ? double.tryParse(totalWh) ?? 0.0 : 0.0;
                
                historyRecords.add({
                  'timestamp': timestamp,
                  'totalWh': whValue,
                  'recordId': documentId.toString(),
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

      print('Fetched ${historyRecords.length} history records from deviceEnergyData');
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
        final whValue = record['totalWh'] as double? ?? record['totalKwh'] as double? ?? 0.0;

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

        aggregated[key] = (aggregated[key] ?? 0.0) + whValue;
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

  // Get total Wh generated across all records
  Future<double> getTotalKwhGenerated() async {
    try {
      final historyRecords = await getHistoryData();
      if (historyRecords.isEmpty) return 0.0;

      double total = 0.0;
      for (final record in historyRecords) {
        total += record['totalWh'] as double? ?? record['totalKwh'] as double? ?? 0.0;
      }

      return total; // Returns Wh
    } catch (e) {
      print('Error calculating total Wh: $e');
      return 0.0;
    }
  }
  
  // Alias for backward compatibility - returns Wh
  Future<double> getTotalWhGenerated() async {
    return getTotalKwhGenerated();
  }
}

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
      return null;
    }
  }

  // Get all history data for the current user's device
  // Data is stored in deviceEnergyData/{serviceTag}/{document_id}/[fields]
  Future<List<Map<String, dynamic>>> getHistoryData() async {
    try {
      final serviceTag = await getServiceTag();
      if (serviceTag == null || serviceTag.isEmpty) {
        return [];
      }

      // Clean service tag: remove spaces and dashes, convert to uppercase
      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();

      // Fetch all records from deviceEnergyData/{serviceTag} (nested structure)
      final snapshot = await _database.child('deviceEnergyData/$cleanServiceTag').get();
      
      if (!snapshot.exists) {
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
            
            // Extract timestamp (required field)
            final timestampStr = record['timestamp'] as String?;
            if (timestampStr == null || timestampStr.isEmpty) {
              return; // Skip records without timestamp
            }
            
            final timestamp = _parseTimestamp(timestampStr);
            if (timestamp == null) {
              return; // Skip records with invalid timestamp
            }
            
            // Helper function to safely parse numeric values
            double? parseNumeric(dynamic value) {
              if (value == null) return null;
              if (value is num) return value.toDouble();
              if (value is String) return double.tryParse(value);
              return null;
            }
            
            // Helper function to safely parse integer values
            int? parseInteger(dynamic value) {
              if (value == null) return null;
              if (value is int) return value;
              if (value is double) return value.toInt();
              if (value is String) return int.tryParse(value);
              return null;
            }
            
            // Helper function to safely parse boolean values
            bool? parseBoolean(dynamic value) {
              if (value == null) return null;
              if (value is bool) return value;
              if (value is String) {
                return value.toLowerCase() == 'true' || value == '1';
              }
              if (value is num) return value != 0;
              return null;
            }
            
            // Extract all fields from Firebase structure
            final historyRecord = <String, dynamic>{
              'timestamp': timestamp,
              'recordId': documentId.toString(),
              
              // Energy and distance fields
              'totalWh': parseNumeric(record['totalWh']) ?? 0.0,
              'totalDistanceKm': parseNumeric(record['totalDistanceKm']) ?? 0.0,
              
              // Battery and voltage fields
              'mountBatteryPercentage': parseInteger(record['mountBatteryPercentage']),
              'mountVoltage': parseNumeric(record['mountVoltage']),
              
              // Power and speed fields (schema: speedKmh as float)
              'powerGeneratedInWatts': parseNumeric(record['powerGeneratedInWatts']) ?? 0.0,
              'speedKmh': parseNumeric(record['speedKmh']) ?? 0.0,
              
              // Additional fields
              'mAh': parseInteger(record['mAh']) ?? 0,
              'isMotorRunning': parseBoolean(record['isMotorRunning']) ?? false,
            };
            
            historyRecords.add(historyRecord);
          }
        });
      }

      // Sort by timestamp descending (most recent first)
      historyRecords.sort((a, b) => 
        (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime)
      );

      return historyRecords;
    } catch (e) {
      return [];
    }
  }

  // Get detailed records for a specific period
  // Returns all records that fall within the specified date range
  Future<List<Map<String, dynamic>>> getDetailedRecordsForPeriod({
    required DateTime periodDate,
    required String filterType,
  }) async {
    try {
      final allRecords = await getHistoryData();
      if (allRecords.isEmpty) return [];

      List<Map<String, dynamic>> periodRecords = [];

      for (final record in allRecords) {
        final recordDate = record['timestamp'] as DateTime;
        bool isInPeriod = false;

        switch (filterType) {
          case 'daily':
            // Same day
            isInPeriod = recordDate.year == periodDate.year &&
                recordDate.month == periodDate.month &&
                recordDate.day == periodDate.day;
            break;
          case 'weekly':
            // Week starting from periodDate
            final weekStart = DateTime(periodDate.year, periodDate.month, periodDate.day);
            final weekEnd = weekStart.add(const Duration(days: 6));
            isInPeriod = recordDate.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
                recordDate.isBefore(weekEnd.add(const Duration(days: 1)));
            break;
          case 'monthly':
            // Same month and year
            isInPeriod = recordDate.year == periodDate.year &&
                recordDate.month == periodDate.month;
            break;
          case 'yearly':
            // Same year
            isInPeriod = recordDate.year == periodDate.year;
            break;
        }

        if (isInPeriod) {
          periodRecords.add(record);
        }
      }

      return periodRecords;
    } catch (e) {
      return [];
    }
  }

  // Get aggregated data by filter type (daily, weekly, monthly, yearly)
  Future<List<Map<String, dynamic>>> getAggregatedData(String filterType) async {
    try {
      final historyRecords = await getHistoryData();
      if (historyRecords.isEmpty) return [];

      final aggregatedWh = <DateTime, double>{};
      final aggregatedDistance = <DateTime, double>{};

      for (final record in historyRecords) {
        final timestamp = record['timestamp'] as DateTime;
        final whValue = record['totalWh'] as double? ?? record['totalKwh'] as double? ?? 0.0;
        final distanceValue = record['totalDistanceKm'] as double? ?? 0.0;

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

        aggregatedWh[key] = (aggregatedWh[key] ?? 0.0) + whValue;
        aggregatedDistance[key] = (aggregatedDistance[key] ?? 0.0) + distanceValue;
      }

      // Convert to list and format
      final entries = aggregatedWh.entries.map((e) {
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
          'distance': aggregatedDistance[dt] ?? 0.0,
          'date': dt,
        };
      }).toList();

      // Sort descending by date (most recent first)
      entries.sort((a, b) => 
        (b['date'] as DateTime).compareTo(a['date'] as DateTime)
      );

      return entries;
    } catch (e) {
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
      return 0.0;
    }
  }

  // Get total distance traveled across all records
  Future<double> getTotalDistanceKm() async {
    try {
      final historyRecords = await getHistoryData();
      if (historyRecords.isEmpty) return 0.0;

      double total = 0.0;
      for (final record in historyRecords) {
        total += record['totalDistanceKm'] as double? ?? 0.0;
      }

      return total; // Returns km
    } catch (e) {
      return 0.0;
    }
  }
  
  // Alias for backward compatibility - returns Wh
  Future<double> getTotalWhGenerated() async {
    return getTotalKwhGenerated();
  }

  // Verify Firebase connection and return diagnostic information
  Future<Map<String, dynamic>> verifyConnection() async {
    try {
      final serviceTag = await getServiceTag();
      if (serviceTag == null || serviceTag.isEmpty) {
        return {
          'success': false,
          'error': 'No service tag found for current user',
        };
      }

      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
      
      // Try to fetch data from Firebase
      final snapshot = await _database.child('deviceEnergyData/$cleanServiceTag').get();
      
      if (!snapshot.exists) {
        return {
          'success': false,
          'error': 'No data found at deviceEnergyData/$cleanServiceTag',
          'serviceTag': serviceTag,
          'cleanServiceTag': cleanServiceTag,
        };
      }

      final data = snapshot.value;
      if (data == null) {
        return {
          'success': false,
          'error': 'Data is null at deviceEnergyData/$cleanServiceTag',
          'serviceTag': serviceTag,
          'cleanServiceTag': cleanServiceTag,
        };
      }

      // Count records and check structure
      int recordCount = 0;
      List<String> sampleFields = [];
      
      if (data is Map<Object?, Object?>) {
        recordCount = data.length;
        
        // Get sample fields from first record
        if (data.isNotEmpty) {
          final firstRecord = data.values.first;
          if (firstRecord is Map<Object?, Object?>) {
            sampleFields = firstRecord.keys.map((k) => k.toString()).toList();
          }
        }
      }

      // Get a sample record to verify field mappings
      final historyData = await getHistoryData();
      Map<String, dynamic>? sampleRecord;
      if (historyData.isNotEmpty) {
        sampleRecord = historyData.first;
      }

      return {
        'success': true,
        'serviceTag': serviceTag,
        'cleanServiceTag': cleanServiceTag,
        'firebasePath': 'deviceEnergyData/$cleanServiceTag',
        'recordCount': recordCount,
        'sampleFields': sampleFields,
        'sampleRecord': sampleRecord,
        'totalHistoryRecords': historyData.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Exception occurred: $e',
      };
    }
  }
}

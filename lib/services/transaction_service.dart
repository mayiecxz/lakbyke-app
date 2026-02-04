import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionService {
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

  // Parse timestamp (ISO 8601 string or int) to DateTime
  DateTime? _parseTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) return null;
      
      // If timestamp is a String, try to parse as ISO 8601 format
      if (timestamp is String) {
        try {
          return DateTime.parse(timestamp);
        } catch (e) {
          // If ISO 8601 parsing fails, try as Unix timestamp string
          final timestampInt = int.tryParse(timestamp);
          if (timestampInt != null) {
            // Check if it's in milliseconds (13 digits) or seconds (10 digits)
            if (timestampInt > 9999999999) {
              return DateTime.fromMillisecondsSinceEpoch(timestampInt);
            } else {
              return DateTime.fromMillisecondsSinceEpoch(timestampInt * 1000);
            }
          }
          return null;
        }
      }
      
      // If timestamp is an int (Unix timestamp in seconds or milliseconds)
      if (timestamp is int) {
        // Check if it's in milliseconds (13 digits) or seconds (10 digits)
        if (timestamp > 9999999999) {
          // Milliseconds
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        } else {
          // Seconds
          return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get all transactions from Firebase for the current user
  // New structure: transactions/STN0001/{transaction_id}/[fields]
  // Filters by current user's service tag (mntTag)
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    try {
      // Get current user's service tag
      final serviceTag = await getServiceTag();
      if (serviceTag == null || serviceTag.isEmpty) {
        return []; // No service tag means no transactions
      }

      // Clean service tag for comparison
      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();

      // Fetch all records from transactions node
      final snapshot = await _database.child('transactions').get();
      
      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.value;
      if (data == null) return [];

      List<Map<String, dynamic>> transactions = [];

      // Handle nested structure: iterate through station IDs first
      if (data is Map<Object?, Object?>) {
        data.forEach((stationId, stationData) {
          if (stationData is Map<Object?, Object?>) {
            // Iterate through transaction IDs under each station
            stationData.forEach((transactionId, transactionData) {
              if (transactionData is Map<Object?, Object?>) {
                final transaction = Map<String, dynamic>.from(
                  transactionData.map((key, value) => MapEntry(key.toString(), value)),
                );
                
                // Filter by current user's service tag (mntTag)
                final mntTag = transaction['mntTag'] as String? ?? '';
                final cleanMntTag = mntTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
                
                // Only include transactions that match the current user's service tag
                if (cleanMntTag != cleanServiceTag) {
                  return; // Skip this transaction
                }
                
                // Extract all fields from the transaction (updated field names)
                final payout = transaction['payout']; // Changed from 'amount'
                final mntBattPercentage = transaction['mntBattPercentage'];
                final powerSubmittedAh = transaction['powerSubmitted_Ah']; // Changed from 'powerSubmitted'
                final stnBattPercentage = transaction['stnBattPercentage'];
                final timestamp = transaction['timestamp']; // Changed from 'timeStamp'
                final voltage = transaction['voltage'];
                
                // Parse timestamp to DateTime (now ISO 8601 string)
                final dateTime = _parseTimestamp(timestamp);
                
                transactions.add({
                  'transactionId': transactionId.toString(),
                  'stationId': stationId.toString(),
                  'payout': payout is num ? payout.toDouble() : (payout is String ? double.tryParse(payout) ?? 0.0 : 0.0),
                  'amount': payout is num ? payout.toDouble() : (payout is String ? double.tryParse(payout) ?? 0.0 : 0.0), // Keep 'amount' for backward compatibility
                  'mntBattPercentage': mntBattPercentage is num ? mntBattPercentage.toInt() : (mntBattPercentage is String ? int.tryParse(mntBattPercentage) ?? 0 : 0),
                  'mntTag': mntTag,
                  'powerSubmitted_Ah': powerSubmittedAh is num ? powerSubmittedAh.toDouble() : (powerSubmittedAh is String ? double.tryParse(powerSubmittedAh) ?? 0.0 : 0.0),
                  'powerSubmitted': powerSubmittedAh is num ? powerSubmittedAh.toDouble() : (powerSubmittedAh is String ? double.tryParse(powerSubmittedAh) ?? 0.0 : 0.0), // Keep for backward compatibility
                  'stnBattPercentage': stnBattPercentage is num ? stnBattPercentage.toInt() : (stnBattPercentage is String ? int.tryParse(stnBattPercentage) ?? 0 : 0),
                  'timestamp': dateTime,
                  'timeStamp': dateTime, // Keep for backward compatibility
                  'voltage': voltage is num ? voltage.toDouble() : (voltage is String ? double.tryParse(voltage) ?? 0.0 : 0.0),
                });
              }
            });
          }
        });
      }

      // Sort by timestamp descending (most recent first)
      transactions.sort((a, b) {
        final aTime = a['timestamp'] as DateTime? ?? a['timeStamp'] as DateTime?;
        final bTime = b['timestamp'] as DateTime? ?? b['timeStamp'] as DateTime?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return transactions;
    } catch (e) {
      return [];
    }
  }

  // Get detailed transactions for a specific period
  // Returns all transactions that fall within the specified date range
  Future<List<Map<String, dynamic>>> getDetailedTransactionsForPeriod({
    required DateTime periodDate,
    required String filterType,
  }) async {
    try {
      final allTransactions = await getAllTransactions();
      if (allTransactions.isEmpty) return [];

      List<Map<String, dynamic>> periodTransactions = [];

      for (final transaction in allTransactions) {
        final transactionDate = transaction['timestamp'] as DateTime? ??
            transaction['timeStamp'] as DateTime?;
        if (transactionDate == null) continue;

        bool isInPeriod = false;

        switch (filterType) {
          case 'daily':
            // Same day
            isInPeriod = transactionDate.year == periodDate.year &&
                transactionDate.month == periodDate.month &&
                transactionDate.day == periodDate.day;
            break;
          case 'weekly':
            // Week starting from periodDate
            final weekStart = DateTime(periodDate.year, periodDate.month, periodDate.day);
            final weekEnd = weekStart.add(const Duration(days: 6));
            isInPeriod = transactionDate.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
                transactionDate.isBefore(weekEnd.add(const Duration(days: 1)));
            break;
          case 'monthly':
            // Same month and year
            isInPeriod = transactionDate.year == periodDate.year &&
                transactionDate.month == periodDate.month;
            break;
          case 'yearly':
            // Same year
            isInPeriod = transactionDate.year == periodDate.year;
            break;
        }

        if (isInPeriod) {
          periodTransactions.add(transaction);
        }
      }

      return periodTransactions;
    } catch (e) {
      return [];
    }
  }

  // Get aggregated data by filter type (daily, weekly, monthly, yearly)
  Future<List<Map<String, dynamic>>> getAggregatedData(String filterType) async {
    try {
      final transactions = await getAllTransactions();
      if (transactions.isEmpty) return [];

      final aggregated = <DateTime, double>{};

      for (final transaction in transactions) {
        final timestamp = transaction['timestamp'] as DateTime? ?? transaction['timeStamp'] as DateTime?;
        if (timestamp == null) continue;
        
        final amount = transaction['payout'] as double? ?? transaction['amount'] as double? ?? 0.0;

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

        aggregated[key] = (aggregated[key] ?? 0.0) + amount;
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
          'amount': e.value,
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

  // Get total redeemed amount across all transactions
  Future<double> getTotalRedeemed() async {
    try {
      final transactions = await getAllTransactions();
      if (transactions.isEmpty) return 0.0;

      double total = 0.0;
      for (final transaction in transactions) {
        final payout = transaction['payout'] as double? ?? transaction['amount'] as double? ?? 0.0;
        total += payout;
      }

      return total;
    } catch (e) {
      return 0.0;
    }
  }

  // Get total generated power (Wh) from all transactions
  // Sums all powerSubmitted_Ah values from transactions and converts to Wh
  // Optionally filters by service tag if provided
  // Note: powerSubmitted_Ah is in Ampere-hours, convert to Wh using voltage
  Future<double> getTotalGenerated({String? serviceTag}) async {
    try {
      final transactions = await getAllTransactions();
      if (transactions.isEmpty) return 0.0;

      double totalGenerated = 0.0;
      
      for (final transaction in transactions) {
        // If service tag is provided, filter by mntTag
        if (serviceTag != null) {
          final mntTag = transaction['mntTag'] as String? ?? '';
          final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
          final cleanMntTag = mntTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
          
          if (cleanMntTag != cleanServiceTag) {
            continue; // Skip transactions that don't match the service tag
          }
        }
        
        // Get powerSubmitted_Ah (changed from 'powerSubmitted')
        // Convert Ah to Wh: Wh = Ah * V
        final powerSubmittedAh = transaction['powerSubmitted_Ah'] as double? ?? 
                                 transaction['powerSubmitted'] as double? ?? 0.0;
        final voltage = transaction['voltage'] as double? ?? 0.0;
        
        if (voltage > 0 && powerSubmittedAh > 0) {
          final whValue = powerSubmittedAh * voltage;
          totalGenerated += whValue;
        }
      }

      return totalGenerated;
    } catch (e) {
      return 0.0;
    }
  }

  // Get battery exchange count (transactions with battery exchange)
  // Already filtered by current user's service tag via getAllTransactions()
  Future<int> getBatteryExchangeCount() async {
    try {
      final transactions = await getAllTransactions();
      // All transactions are already filtered by service tag, so count all of them
      // All transactions with matching mntTag are considered battery exchanges
      return transactions.length;
    } catch (e) {
      return 0;
    }
  }
}

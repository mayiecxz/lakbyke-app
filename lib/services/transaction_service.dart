import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Parse timestamp (int) to DateTime
  DateTime? _parseTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) return null;
      
      // If timestamp is an int (Unix timestamp in seconds or milliseconds)
      int timestampInt;
      if (timestamp is int) {
        timestampInt = timestamp;
      } else if (timestamp is String) {
        timestampInt = int.tryParse(timestamp) ?? 0;
      } else {
        return null;
      }

      // Check if it's in milliseconds (13 digits) or seconds (10 digits)
      if (timestampInt > 9999999999) {
        // Milliseconds
        return DateTime.fromMillisecondsSinceEpoch(timestampInt);
      } else {
        // Seconds
        return DateTime.fromMillisecondsSinceEpoch(timestampInt * 1000);
      }
    } catch (e) {
      print('Error parsing timestamp: $timestamp - $e');
      return null;
    }
  }

  // Get all transactions from Firebase
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    try {
      print('Fetching transactions from Firebase...');
      
      // Fetch all records from transactions node
      final snapshot = await _database.child('transactions').get();
      
      if (!snapshot.exists) {
        print('No transactions found in Firebase');
        return [];
      }

      final data = snapshot.value;
      if (data == null) return [];

      List<Map<String, dynamic>> transactions = [];

      // Handle Map structure (each document is a key-value pair)
      if (data is Map<Object?, Object?>) {
        data.forEach((transactionId, transactionData) {
          if (transactionData is Map<Object?, Object?>) {
            final transaction = Map<String, dynamic>.from(
              transactionData.map((key, value) => MapEntry(key.toString(), value)),
            );
            
            // Extract all fields from the transaction
            final amount = transaction['amount'];
            final mntBattPercentage = transaction['mntBattPercentage'];
            final mntTag = transaction['mntTag'];
            final powerSubmitted = transaction['powerSubmitted'];
            final stnBattPercentage = transaction['stnBattPercentage'];
            final stnTag = transaction['stnTag'];
            final timeStamp = transaction['timeStamp'];
            final transactionID = transaction['transactionID'];
            final voltage = transaction['voltage'];
            
            // Parse timestamp to DateTime
            final dateTime = _parseTimestamp(timeStamp);
            
            transactions.add({
              'transactionId': transactionId.toString(),
              'amount': amount is num ? amount.toDouble() : (amount is String ? double.tryParse(amount) ?? 0.0 : 0.0),
              'mntBattPercentage': mntBattPercentage is num ? mntBattPercentage.toInt() : (mntBattPercentage is String ? int.tryParse(mntBattPercentage) ?? 0 : 0),
              'mntTag': mntTag?.toString() ?? '',
              'powerSubmitted': powerSubmitted is num ? powerSubmitted.toDouble() : (powerSubmitted is String ? double.tryParse(powerSubmitted) ?? 0.0 : 0.0),
              'stnBattPercentage': stnBattPercentage is num ? stnBattPercentage.toInt() : (stnBattPercentage is String ? int.tryParse(stnBattPercentage) ?? 0 : 0),
              'stnTag': stnTag?.toString() ?? '',
              'timeStamp': dateTime,
              'transactionID': transactionID is num ? transactionID.toInt() : (transactionID is String ? int.tryParse(transactionID) ?? 0 : 0),
              'voltage': voltage is num ? voltage.toDouble() : (voltage is String ? double.tryParse(voltage) ?? 0.0 : 0.0),
            });
          }
        });
      }

      // Sort by timestamp descending (most recent first)
      transactions.sort((a, b) {
        final aTime = a['timeStamp'] as DateTime?;
        final bTime = b['timeStamp'] as DateTime?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      print('Fetched ${transactions.length} transactions from Firebase');
      return transactions;
    } catch (e) {
      print('Error fetching transactions: $e');
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
        final timestamp = transaction['timeStamp'] as DateTime?;
        if (timestamp == null) continue;
        
        final amount = transaction['amount'] as double? ?? 0.0;

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
      print('Error aggregating transaction data: $e');
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
        final amount = transaction['amount'] as double? ?? 0.0;
        total += amount;
      }

      return total;
    } catch (e) {
      print('Error calculating total redeemed: $e');
      return 0.0;
    }
  }

  // Get total generated power (kWh) from all transactions
  // Sums all powerSubmitted values from transactions
  // Optionally filters by service tag if provided
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
        
        // Sum the powerSubmitted value (assuming it's already in kWh)
        final powerSubmitted = transaction['powerSubmitted'] as double? ?? 0.0;
        totalGenerated += powerSubmitted;
      }

      print('Total generated calculated: ${totalGenerated.toStringAsFixed(2)} kWh${serviceTag != null ? ' for service tag: $serviceTag' : ''}');
      return totalGenerated;
    } catch (e) {
      print('Error calculating total generated: $e');
      return 0.0;
    }
  }

  // Get battery exchange count (transactions with battery exchange)
  Future<int> getBatteryExchangeCount() async {
    try {
      final transactions = await getAllTransactions();
      // You can filter based on specific criteria if needed
      // For now, we'll count transactions that have battery-related data
      int count = 0;
      for (final transaction in transactions) {
        final mntBattPercentage = transaction['mntBattPercentage'] as int? ?? 0;
        final stnBattPercentage = transaction['stnBattPercentage'] as int? ?? 0;
        // If either battery percentage is present, consider it a battery exchange
        if (mntBattPercentage > 0 || stnBattPercentage > 0) {
          count++;
        }
      }
      return count;
    } catch (e) {
      print('Error calculating battery exchange count: $e');
      return 0;
    }
  }
}

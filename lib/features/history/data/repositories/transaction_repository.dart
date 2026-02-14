import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Repository for transaction operations
class TransactionRepository {
  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  TransactionRepository({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  })  : _database = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

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

  DateTime? _parseTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) return null;
      
      if (timestamp is String) {
        try {
          return DateTime.parse(timestamp);
        } catch (e) {
          final timestampInt = int.tryParse(timestamp);
          if (timestampInt != null) {
            if (timestampInt > 9999999999) {
              return DateTime.fromMillisecondsSinceEpoch(timestampInt);
            } else {
              return DateTime.fromMillisecondsSinceEpoch(timestampInt * 1000);
            }
          }
          return null;
        }
      }
      
      if (timestamp is int) {
        if (timestamp > 9999999999) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        } else {
          return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    try {
      final mntTag = await getServiceTag();
      if (mntTag == null || mntTag.isEmpty) return [];

      final cleanMntTag = mntTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
      final snapshot = await _database.ref('transactions').get();

      if (!snapshot.exists) return [];

      final data = snapshot.value;
      if (data is! Map) return [];

      final transactions = <Map<String, dynamic>>[];
      final transactionsMap = Map<String, dynamic>.from(data);

      for (final entry in transactionsMap.entries) {
        final value = entry.value;
        if (value is Map) {
          final transactionData = Map<String, dynamic>.from(value);
          final transactionMntTag = transactionData['mntTag'] as String?;
          
          if (transactionMntTag != null) {
            final cleanTransactionTag = transactionMntTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
            if (cleanTransactionTag == cleanMntTag) {
              final timestamp = _parseTimestamp(transactionData['timeStamp'] ?? transactionData['timestamp']);
              if (timestamp != null) {
                transactionData['timestamp'] = timestamp;
              }
              transactions.add(transactionData);
            }
          }
        }
      }

      transactions.sort((a, b) {
        final aTime = a['timestamp'] as DateTime?;
        final bTime = b['timestamp'] as DateTime?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return transactions;
    } catch (e) {
      return [];
    }
  }

  Future<double> getTotalRedeemed() async {
    try {
      final transactions = await getAllTransactions();
      double total = 0.0;
      for (final transaction in transactions) {
        final payout = transaction['payout'] as num?;
        if (payout != null) {
          total += payout.toDouble();
        }
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> getTotalGenerated() async {
    try {
      final transactions = await getAllTransactions();
      double total = 0.0;
      for (final transaction in transactions) {
        final powerAh = transaction['powerSubmitted_Ah'] as num?;
        final voltage = transaction['voltage'] as num?;
        if (powerAh != null && voltage != null) {
          total += (powerAh * voltage).toDouble();
        }
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  Future<int> getBatteryExchangeCount() async {
    try {
      final transactions = await getAllTransactions();
      int count = 0;
      for (final transaction in transactions) {
        // A transaction is a battery exchange if it has meaningful battery % or type
        final mnt = transaction['mntBattPercentage'] as num?;
        final stn = transaction['stnBattPercentage'] as num?;
        final type = transaction['type'] as String?;
        final hasBatteryData = (mnt != null && mnt > 0) || (stn != null && stn > 0);
        if (hasBatteryData || type == 'battery_exchange') {
          count++;
        }
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Returns all transactions that fall within the specified date range for detail modals.
  Future<List<Map<String, dynamic>>> getDetailedTransactionsForPeriod({
    required DateTime periodDate,
    required String filterType,
  }) async {
    try {
      final allTransactions = await getAllTransactions();
      if (allTransactions.isEmpty) return [];

      final periodTransactions = <Map<String, dynamic>>[];

      for (final transaction in allTransactions) {
        final transactionDate = transaction['timestamp'] as DateTime?;
        if (transactionDate == null) continue;

        bool isInPeriod = false;
        switch (filterType) {
          case 'daily':
            isInPeriod = transactionDate.year == periodDate.year &&
                transactionDate.month == periodDate.month &&
                transactionDate.day == periodDate.day;
            break;
          case 'weekly':
            final weekStart = DateTime(periodDate.year, periodDate.month, periodDate.day);
            final weekEnd = weekStart.add(const Duration(days: 6));
            isInPeriod = transactionDate.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
                transactionDate.isBefore(weekEnd.add(const Duration(days: 1)));
            break;
          case 'monthly':
            isInPeriod = transactionDate.year == periodDate.year &&
                transactionDate.month == periodDate.month;
            break;
          case 'yearly':
            isInPeriod = transactionDate.year == periodDate.year;
            break;
          default:
            isInPeriod = false;
        }
        if (isInPeriod) periodTransactions.add(transaction);
      }
      periodTransactions.sort((a, b) {
        final aTime = a['timestamp'] as DateTime?;
        final bTime = b['timestamp'] as DateTime?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });
      return periodTransactions;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAggregatedData(String filter) async {
    try {
      final transactions = await getAllTransactions();
      if (transactions.isEmpty) return [];

      final aggregated = <DateTime, double>{};

      for (final transaction in transactions) {
        final timestamp = transaction['timestamp'] as DateTime?;
        if (timestamp == null) continue;

        final amount = (transaction['payout'] as num?)?.toDouble() ?? 0.0;
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

        aggregated[key] = (aggregated[key] ?? 0.0) + amount;
      }

      return aggregated.entries
          .map((e) => {'date': e.key, 'amount': e.value})
          .toList()
        ..sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> updateTransactionForQrScan(String transactionUid) async {
    try {
      final uid = transactionUid.trim();
      if (uid.isEmpty) {
        return {'success': false, 'error': 'Invalid transaction ID'};
      }

      final mntTag = await getServiceTag();
      if (mntTag == null || mntTag.trim().isEmpty) {
        return {'success': false, 'error': 'User service tag not found.'};
      }

      final snapshot = await _database.ref('transactions').get();
      if (!snapshot.exists) {
        return {'success': false, 'error': 'Transaction not found'};
      }

      final data = snapshot.value;
      if (data is! Map) {
        return {'success': false, 'error': 'Transaction not found'};
      }

      final transactionsMap = Map<String, dynamic>.from(data);

      // Check flat structure
      if (transactionsMap.containsKey(uid)) {
        await _database.ref('transactions').child(uid).update({
          'mntTag': mntTag.trim(),
          'status': 'qr_scanned',
        });
        return {'success': true, 'message': 'Transaction updated successfully'};
      }

      // Check nested structure
      for (final entry in transactionsMap.entries) {
        final stationData = entry.value;
        if (stationData is Map && stationData.containsKey(uid)) {
          await _database.ref('transactions').child(entry.key).child(uid).update({
            'mntTag': mntTag.trim(),
            'status': 'qr_scanned',
          });
          return {'success': true, 'message': 'Transaction updated successfully'};
        }
      }

      return {'success': false, 'error': 'Transaction not found'};
    } catch (e) {
      return {'success': false, 'error': 'Failed to update transaction: $e'};
    }
  }
}

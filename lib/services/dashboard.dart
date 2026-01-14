import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? getCurrentuserTable() {
    return _auth.currentUser?.uid;
  }

  // Get dashboard data for the current user from deviceEnergyData
  // Data is stored by service tag (e.g., "MNT 0001"), not by userId
  Future<Map<String, dynamic>?> getDashboardData() async {
    try {
      final userId = getCurrentuserTable();
      if (userId == null) {
        print('No user logged in');
        return null;
      }

      // First, get the user's service tag
      final serviceTagSnapshot = await _database.child('userTable/$userId/serviceTag').get();
      if (!serviceTagSnapshot.exists) {
        print('Service tag not found for user');
        return null;
      }

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) {
        print('Service tag is empty');
        return null;
      }

      // Try both formats: with spaces and without spaces
      final cleanServiceTag = serviceTag.replaceAll(' ', '');
      
      print('Fetching dashboard data for service tag: "$serviceTag" (cleaned: "$cleanServiceTag")');

      // First try without spaces
      var snapshot = await _database.child('deviceEnergyData/$cleanServiceTag').get();
      
      // If not found, try with spaces
      if (!snapshot.exists && serviceTag.contains(' ')) {
        print('Trying with spaces: "$serviceTag"');
        snapshot = await _database.child('deviceEnergyData/$serviceTag').get();
      }
      
      Map<String, dynamic> dashboardData = {};
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<Object?, Object?>;
        print('Successfully fetched dashboard data');
        dashboardData = Map<String, dynamic>.from(
          data.map((key, value) => MapEntry(key.toString(), value)),
        );
      } else {
        print('No deviceEnergyData found for service tag: "$serviceTag" or "$cleanServiceTag"');
      }

      // Fetch total redeems from transactions table
      final totalRedeems = await getTotalRedeems();
      dashboardData['totalRedeems'] = totalRedeems;

      // Fetch total generated from transactions table
      final totalGenerated = await getTotalGenerated();
      dashboardData['totalGenerated'] = totalGenerated;

      // Fetch batteries exchanged count from transactions table
      final batteriesExchanged = await getBatteriesExchanged();
      dashboardData['batteriesExchanged'] = batteriesExchanged;

      return dashboardData.isEmpty ? null : dashboardData;
    } catch (e) {
      print('Error fetching dashboard data: $e');
      return null;
    }
  }

  // Stream dashboard data for real-time updates from deviceEnergyData
  // Data is stored by service tag (e.g., "MNT 0001"), not by userId
  Stream<Map<String, dynamic>?> getDashboardDataStream() {
    final userId = getCurrentuserTable();
    if (userId == null) {
      return Stream.value(null);
    }

    // Get service tag first, then create stream
    return Stream.fromFuture(
      _database.child('userTable/$userId/serviceTag').get(),
    ).asyncExpand((serviceTagSnapshot) {
      if (!serviceTagSnapshot.exists) {
        return Stream.value(null);
      }

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) {
        return Stream.value(null);
      }

      // Remove spaces from service tag for database lookup
      final cleanServiceTag = serviceTag.replaceAll(' ', '');

      // Stream data using the service tag
      return _database.child('deviceEnergyData/$cleanServiceTag').onValue.map((event) {
        if (event.snapshot.exists) {
          final data = event.snapshot.value as Map<Object?, Object?>;
          return Map<String, dynamic>.from(
            data.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
        return null;
      });
    });
  }

  // Get today's metrics from deviceEnergyData
  // Data is stored by service tag (e.g., "MNT 0001"), not by userId
  Future<Map<String, dynamic>?> getTodayMetrics() async {
    try {
      final userId = getCurrentuserTable();
      if (userId == null) return null;

      // First, get the user's service tag
      final serviceTagSnapshot = await _database.child('userTable/$userId/serviceTag').get();
      if (!serviceTagSnapshot.exists) return null;

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) return null;

      // Remove spaces from service tag for database lookup
      final cleanServiceTag = serviceTag.replaceAll(' ', '');

      final snapshot = await _database.child('deviceEnergyData/$cleanServiceTag').get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<Object?, Object?>;
        return Map<String, dynamic>.from(
          data.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
      
      return null;
    } catch (e) {
      print('Error fetching today metrics: $e');
      return null;
    }
  }

  // Get user's service tag (MNT-A001)
  Future<String?> getServiceTag() async {
    try {
      final userId = getCurrentuserTable();
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

  // Get total redeems from transactions table
  // Sums all 'amount' fields from transactions where mntTag matches user's service tag
  Future<double> getTotalRedeems() async {
    try {
      final userId = getCurrentuserTable();
      if (userId == null) return 0.0;

      // First, get the user's service tag
      final serviceTagSnapshot = await _database.child('userTable/$userId/serviceTag').get();
      if (!serviceTagSnapshot.exists) return 0.0;

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) return 0.0;

      // Remove spaces from service tag for database lookup
      final cleanServiceTag = serviceTag.replaceAll(' ', '');

      // Fetch all transactions
      final transactionsSnapshot = await _database.child('transactions').get();
      
      if (!transactionsSnapshot.exists) {
        print('No transactions found');
        return 0.0;
      }

      final transactions = transactionsSnapshot.value as Map<Object?, Object?>?;
      if (transactions == null) return 0.0;

      double totalRedeems = 0.0;

      // Iterate through all transactions and sum amounts where mntTag matches
      transactions.forEach((transactionId, transactionData) {
        if (transactionData is Map<Object?, Object?>) {
          final transaction = Map<String, dynamic>.from(
            transactionData.map((key, value) => MapEntry(key.toString(), value)),
          );

          // Check if this transaction belongs to the user's service tag
          final mntTag = transaction['mntTag'] as String?;
          if (mntTag != null) {
            final cleanMntTag = mntTag.replaceAll(' ', '');
            if (cleanMntTag == cleanServiceTag) {
              // Sum the amount
              final amount = transaction['amount'];
              if (amount != null) {
                final amountValue = (amount is num) ? amount.toDouble() : 
                                   (amount is String) ? double.tryParse(amount) ?? 0.0 : 0.0;
                totalRedeems += amountValue;
              }
            }
          }
        }
      });

      print('Total redeems calculated: $totalRedeems for service tag: $cleanServiceTag');
      return totalRedeems;
    } catch (e) {
      print('Error calculating total redeems: $e');
      return 0.0;
    }
  }

  // Get total generated (kWh) from transactions table
  // Sums all powerSubmitted values from transactions where mntTag matches user's service tag
  // Converts power from watts to kWh if needed
  Future<double> getTotalGenerated() async {
    try {
      final userId = getCurrentuserTable();
      if (userId == null) return 0.0;

      // First, get the user's service tag
      final serviceTagSnapshot = await _database.child('userTable/$userId/serviceTag').get();
      if (!serviceTagSnapshot.exists) return 0.0;

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) return 0.0;

      // Remove spaces from service tag for database lookup
      final cleanServiceTag = serviceTag.replaceAll(' ', '');

      // Fetch all transactions
      final transactionsSnapshot = await _database.child('transactions').get();
      
      if (!transactionsSnapshot.exists) {
        print('No transactions found for total generated');
        return 0.0;
      }

      final transactions = transactionsSnapshot.value as Map<Object?, Object?>?;
      if (transactions == null) return 0.0;

      double totalGenerated = 0.0;

      // Sum powerSubmitted from all transactions where mntTag matches
      transactions.forEach((transactionId, transactionData) {
        if (transactionData is Map<Object?, Object?>) {
          final transaction = Map<String, dynamic>.from(
            transactionData.map((key, value) => MapEntry(key.toString(), value)),
          );

          // Check if this transaction belongs to the user's service tag
          final mntTag = transaction['mntTag'] as String?;
          if (mntTag != null) {
            final cleanMntTag = mntTag.replaceAll(' ', '');
            if (cleanMntTag == cleanServiceTag) {
              // Get powerSubmitted value and sum it
              // Assuming powerSubmitted is already in kWh, or adjust conversion as needed
              final powerSubmitted = transaction['powerSubmitted'];
              if (powerSubmitted != null) {
                final powerValue = (powerSubmitted is num) ? powerSubmitted.toDouble() : 
                                 (powerSubmitted is String) ? double.tryParse(powerSubmitted) ?? 0.0 : 0.0;
                // Sum the power values (assuming already in kWh)
                // If your powerSubmitted is in watts, uncomment the line below and comment the direct sum
                // totalGenerated += powerValue / 1000.0; // Convert watts to kWh
                totalGenerated += powerValue; // Sum directly (assuming kWh)
              }
            }
          }
        }
      });

      print('Total generated calculated: ${totalGenerated.toStringAsFixed(2)} kWh for service tag: $cleanServiceTag');
      return totalGenerated;
    } catch (e) {
      print('Error calculating total generated: $e');
      return 0.0;
    }
  }

  // Get total batteries exchanged from transactions table
  // Counts all transactions where mntTag matches user's service tag
  // All transactions with matching mntTag are considered battery exchanges
  Future<int> getBatteriesExchanged() async {
    try {
      final userId = getCurrentuserTable();
      if (userId == null) return 0;

      // First, get the user's service tag
      final serviceTagSnapshot = await _database.child('userTable/$userId/serviceTag').get();
      if (!serviceTagSnapshot.exists) return 0;

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) return 0;

      // Remove spaces from service tag for database lookup
      final cleanServiceTag = serviceTag.replaceAll(' ', '');

      // Fetch all transactions
      final transactionsSnapshot = await _database.child('transactions').get();
      
      if (!transactionsSnapshot.exists) return 0;

      final transactions = transactionsSnapshot.value as Map<Object?, Object?>?;
      if (transactions == null) return 0;

      int batteryCount = 0;

      // Count all transactions where mntTag matches user's service tag
      transactions.forEach((transactionId, transactionData) {
        if (transactionData is Map<Object?, Object?>) {
          final transaction = Map<String, dynamic>.from(
            transactionData.map((key, value) => MapEntry(key.toString(), value)),
          );

          final mntTag = transaction['mntTag'] as String?;
          if (mntTag != null) {
            final cleanMntTag = mntTag.replaceAll(' ', '');
            if (cleanMntTag == cleanServiceTag) {
              // Count all transactions with matching mntTag as battery exchanges
              batteryCount++;
            }
          }
        }
      });

      print('Batteries exchanged count: $batteryCount for service tag: $cleanServiceTag');
      return batteryCount;
    } catch (e) {
      print('Error calculating batteries exchanged: $e');
      return 0;
    }
  }
}
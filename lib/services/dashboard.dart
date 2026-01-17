import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class DashboardService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Staleness monitoring fields
  Timer? _stalenessTimer;
  Map<String, dynamic>? _lastReceivedData;
  String? _monitoringServiceTag;
  DateTime? _monitoredTimestamp; // The timestamp we're currently monitoring for staleness
  bool _hasWrittenForZeroPower = false; // Track if we've written for zero power

  // Get current user ID
  String? getCurrentuserTable() {
    return _auth.currentUser?.uid;
  }

  // Parse ISO 8601 timestamp string to DateTime
  DateTime? _parseIsoTimestamp(String? timestampStr) {
    if (timestampStr == null || timestampStr.isEmpty) return null;
    try {
      return DateTime.parse(timestampStr);
    } catch (e) {
      print('Error parsing ISO timestamp: $timestampStr - $e');
      return null;
    }
  }

  // Check if timestamp is today
  bool _isToday(DateTime timestamp) {
    final now = DateTime.now();
    return timestamp.year == now.year &&
           timestamp.month == now.month &&
           timestamp.day == now.day;
  }

  // Check if timestamp is yesterday
  bool _isYesterday(DateTime timestamp) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return timestamp.year == yesterday.year &&
           timestamp.month == yesterday.month &&
           timestamp.day == yesterday.day;
  }

  // Get yesterday's aggregated data (sum of all records from yesterday)
  // Returns: {yesterdayDistance: double, yesterdayWh: double}
  Future<Map<String, dynamic>> getYesterdayData() async {
    try {
      final userId = getCurrentuserTable();
      if (userId == null) {
        return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};
      }

      // First, get the user's service tag
      final serviceTagSnapshot = await _database.child('userTable/$userId/serviceTag').get();
      if (!serviceTagSnapshot.exists) {
        return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};
      }

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) {
        return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};
      }

      // Clean service tag
      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();

      // Fetch all documents
      final snapshot = await _database.child('deviceEnergyData/$cleanServiceTag').get();
      
      if (!snapshot.exists) {
        return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};
      }

      final data = snapshot.value;
      if (data == null || data is! Map<Object?, Object?>) {
        return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};
      }

      double yesterdayDistance = 0.0;
      double yesterdayWh = 0.0;

      // Iterate through all documents and sum yesterday's data
      data.forEach((documentId, documentData) {
        if (documentData is Map<Object?, Object?>) {
          final document = Map<String, dynamic>.from(
            documentData.map((key, value) => MapEntry(key.toString(), value)),
          );

          final timestampStr = document['timestamp'] as String?;
          final timestamp = _parseIsoTimestamp(timestampStr);

          // Only include records from yesterday
          if (timestamp != null && _isYesterday(timestamp)) {
            // Sum distance
            final distance = document['totalDistanceKm'];
            if (distance != null) {
              final distanceValue = (distance is num) ? distance.toDouble() : 
                                   (distance is String) ? double.tryParse(distance) ?? 0.0 : 0.0;
              yesterdayDistance += distanceValue;
            }

            // Sum energy (Wh)
            final totalWh = document['totalWh'];
            if (totalWh != null) {
              final whValue = (totalWh is num) ? totalWh.toDouble() : 
                            (totalWh is String) ? double.tryParse(totalWh) ?? 0.0 : 0.0;
              yesterdayWh += whValue;
            }
          }
        }
      });

      return {
        'yesterdayDistance': yesterdayDistance,
        'yesterdayWh': yesterdayWh,
      };
    } catch (e) {
      print('Error fetching yesterday data: $e');
      return {'yesterdayDistance': 0.0, 'yesterdayWh': 0.0};
    }
  }

  // Get today's aggregated data (sum of all records from today)
  // Returns: {todayDistance: double, todayWh: double}
  Future<Map<String, dynamic>> getTodayData() async {
    try {
      final userId = getCurrentuserTable();
      if (userId == null) {
        return {'todayDistance': 0.0, 'todayWh': 0.0};
      }

      // First, get the user's service tag
      final serviceTagSnapshot = await _database.child('userTable/$userId/serviceTag').get();
      if (!serviceTagSnapshot.exists) {
        return {'todayDistance': 0.0, 'todayWh': 0.0};
      }

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) {
        return {'todayDistance': 0.0, 'todayWh': 0.0};
      }

      // Clean service tag
      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();

      // Fetch all documents
      final snapshot = await _database.child('deviceEnergyData/$cleanServiceTag').get();
      
      if (!snapshot.exists) {
        return {'todayDistance': 0.0, 'todayWh': 0.0};
      }

      final data = snapshot.value;
      if (data == null || data is! Map<Object?, Object?>) {
        return {'todayDistance': 0.0, 'todayWh': 0.0};
      }

      double todayDistance = 0.0;
      double todayWh = 0.0;

      // Iterate through all documents and sum today's data
      data.forEach((documentId, documentData) {
        if (documentData is Map<Object?, Object?>) {
          final document = Map<String, dynamic>.from(
            documentData.map((key, value) => MapEntry(key.toString(), value)),
          );

          final timestampStr = document['timestamp'] as String?;
          final timestamp = _parseIsoTimestamp(timestampStr);

          // Only include records from today
          if (timestamp != null && _isToday(timestamp)) {
            // Sum distance
            final distance = document['totalDistanceKm'];
            if (distance != null) {
              final distanceValue = (distance is num) ? distance.toDouble() : 
                                   (distance is String) ? double.tryParse(distance) ?? 0.0 : 0.0;
              todayDistance += distanceValue;
            }

            // Sum energy (Wh)
            final totalWh = document['totalWh'];
            if (totalWh != null) {
              final whValue = (totalWh is num) ? totalWh.toDouble() : 
                            (totalWh is String) ? double.tryParse(totalWh) ?? 0.0 : 0.0;
              todayWh += whValue;
            }
          }
        }
      });

      return {
        'todayDistance': todayDistance,
        'todayWh': todayWh,
      };
    } catch (e) {
      print('Error fetching today data: $e');
      return {'todayDistance': 0.0, 'todayWh': 0.0};
    }
  }

  // Get latest effort (powerGeneratedInWatts) with timestamp for live indicator
  // Returns: {effort: double, timestamp: DateTime}
  Future<Map<String, dynamic>?> getLatestEffort() async {
    try {
      final userId = getCurrentuserTable();
      if (userId == null) return null;

      // First, get the user's service tag
      final serviceTagSnapshot = await _database.child('userTable/$userId/serviceTag').get();
      if (!serviceTagSnapshot.exists) return null;

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) return null;

      // Clean service tag
      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();

      // Fetch all documents
      final snapshot = await _database.child('deviceEnergyData/$cleanServiceTag').get();
      
      if (!snapshot.exists) return null;

      final data = snapshot.value;
      if (data == null || data is! Map<Object?, Object?>) return null;

      Map<String, dynamic>? latestDocument;
      DateTime? latestTimestamp;

      // Find the latest document by timestamp
      data.forEach((documentId, documentData) {
        if (documentData is Map<Object?, Object?>) {
          final document = Map<String, dynamic>.from(
            documentData.map((key, value) => MapEntry(key.toString(), value)),
          );

          final timestampStr = document['timestamp'] as String?;
          final timestamp = _parseIsoTimestamp(timestampStr);

          if (timestamp != null) {
            if (latestTimestamp == null || timestamp.isAfter(latestTimestamp!)) {
              latestTimestamp = timestamp;
              latestDocument = document;
            }
          } else if (latestDocument == null) {
            latestDocument = document;
          }
        }
      });

      if (latestDocument != null && latestTimestamp != null) {
        final doc = latestDocument!;
        final effort = doc['powerGeneratedInWatts'];
        final effortValue = (effort is num) ? effort.toDouble() : 
                          (effort is String) ? double.tryParse(effort) ?? 0.0 : 0.0;

        return {
          'effort': effortValue,
          'timestamp': latestTimestamp!,
        };
      }

      return null;
    } catch (e) {
      print('Error fetching latest effort: $e');
      return null;
    }
  }

  // Get dashboard data for the current user from deviceEnergyData
  // Data is stored by service tag (e.g., "MNT 0001"), not by userId
  // New structure: deviceEnergyData/MNT0001/{document_id}/[fields]
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

      // Clean service tag: remove spaces and dashes, convert to uppercase for consistency
      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
      
      print('Fetching dashboard data for service tag: "$serviceTag" (cleaned: "$cleanServiceTag")');

      // Fetch nested structure: deviceEnergyData/{serviceTag}/* to get all documents
      var snapshot = await _database.child('deviceEnergyData/$cleanServiceTag').get();
      
      Map<String, dynamic> dashboardData = {};
      
      if (snapshot.exists) {
        final data = snapshot.value;
        
        // Handle nested structure: iterate through document IDs to find the latest one
        if (data is Map<Object?, Object?>) {
          Map<String, dynamic>? latestDocument;
          DateTime? latestTimestamp;
          
          data.forEach((documentId, documentData) {
            if (documentData is Map<Object?, Object?>) {
              final document = Map<String, dynamic>.from(
                documentData.map((key, value) => MapEntry(key.toString(), value)),
              );
              
              // Get timestamp to find the latest document
              final timestampStr = document['timestamp'] as String?;
              final timestamp = _parseIsoTimestamp(timestampStr);
              
              if (timestamp != null) {
                if (latestTimestamp == null || timestamp.isAfter(latestTimestamp!)) {
                  latestTimestamp = timestamp;
                  latestDocument = document;
                }
              } else if (latestDocument == null) {
                // If no timestamp, use first document as fallback
                latestDocument = document;
              }
            }
          });
          
          if (latestDocument != null) {
            dashboardData = Map<String, dynamic>.from(latestDocument!);
            
            // Keep totalWh as-is (no conversion to kWh)
            print('Successfully fetched dashboard data from deviceEnergyData/$cleanServiceTag');
            print('Fetched deviceEnergyData keys: ${dashboardData.keys.toList()}');
            print('totalDistanceKm: ${dashboardData['totalDistanceKm']}');
            print('powerGeneratedInWatts: ${dashboardData['powerGeneratedInWatts']}');
            print('totalWh: ${dashboardData['totalWh']}');
          } else {
            print('No valid documents found in deviceEnergyData/$cleanServiceTag');
          }
        } else {
          // Fallback: handle flat structure if data is not nested
          dashboardData = Map<String, dynamic>.from(
            (data as Map<Object?, Object?>).map((key, value) => MapEntry(key.toString(), value)),
          );
          
          // Keep totalWh as-is (no conversion)
        }
      } else {
        print('No deviceEnergyData found for service tag: "$cleanServiceTag" (cleaned from "$serviceTag")');
      }

      // Fetch today's aggregated data
      final todayData = await getTodayData();
      dashboardData['todayDistance'] = todayData['todayDistance'];
      dashboardData['todayWh'] = todayData['todayWh'];

      // Fetch total redeems from transactions table
      final totalRedeems = await getTotalRedeems();
      dashboardData['totalRedeems'] = totalRedeems;

      // Fetch total generated from transactions table (in Wh)
      final totalGenerated = await getTotalGenerated();
      dashboardData['totalGenerated'] = totalGenerated;

      // Fetch batteries exchanged count from transactions table
      final batteriesExchanged = await getBatteriesExchanged();
      dashboardData['batteriesExchanged'] = batteriesExchanged;

      // Consolidate live effort: always set liveEffort = powerGeneratedInWatts from latest document
      final powerWatts = dashboardData['powerGeneratedInWatts'];
      if (powerWatts != null) {
        final effortValue = (powerWatts is num) 
            ? powerWatts.toDouble() 
            : (powerWatts is String ? double.tryParse(powerWatts) ?? 0.0 : 0.0);
        dashboardData['liveEffort'] = effortValue;
      } else {
        dashboardData['liveEffort'] = 0.0;
      }
      
      // Add live effort timestamp from latest document
      final latestEffort = await getLatestEffort();
      if (latestEffort != null && latestEffort['timestamp'] != null) {
        dashboardData['liveEffortTimestamp'] = latestEffort['timestamp'];
      }

      print('Final dashboardData keys: ${dashboardData.keys.toList()}');
      print('Returning dashboardData: ${dashboardData.isNotEmpty}');
      
      return dashboardData;
    } catch (e) {
      print('Error fetching dashboard data: $e');
      return null;
    }
  }

  // Write zero-value record to database after 10 seconds of inactivity
  Future<void> _writeZeroValueRecord(Map<String, dynamic> lastData, String serviceTag) async {
    try {
      // Clean service tag
      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
      
      // Extract last known voltage and battery percentage
      final lastVoltage = lastData['mountVoltage'];
      final lastBattery = lastData['mountBatteryPercentage'];
      
      // Get voltage value
      double voltageValue = 0.0;
      if (lastVoltage != null) {
        voltageValue = (lastVoltage is num) 
            ? lastVoltage.toDouble() 
            : (lastVoltage is String ? double.tryParse(lastVoltage) ?? 0.0 : 0.0);
      }
      
      // Get battery percentage value
      int batteryValue = 0;
      if (lastBattery != null) {
        batteryValue = (lastBattery is int) 
            ? lastBattery 
            : (lastBattery is num ? lastBattery.toInt() : 0);
      }
      
      // Create zero-value record
      final zeroRecord = {
        'mountVoltage': voltageValue,
        'mountBatteryPercentage': batteryValue,
        'timestamp': DateTime.now().toIso8601String(),
        'powerGeneratedInWatts': 0.0,
        'mAh': 0,
        'speedKmh': 0,
        'totalDistanceKm': 0.0,
        'totalWh': 0,
        'isMotorRunning': false,
      };
      
      // Write to database using push to create new document
      await _database.child('deviceEnergyData/$cleanServiceTag').push().set(zeroRecord);
      
      print('Zero-value record written for service tag: $cleanServiceTag');
    } catch (e) {
      print('Error writing zero-value record: $e');
    }
  }

  // Check if data is stale (same timestamp for more than 10 seconds)
  bool isDataStale(Map<String, dynamic>? data) {
    if (data == null) return true;
    
    final timestampStr = data['timestamp'] as String?;
    if (timestampStr == null) return true;
    
    final timestamp = _parseIsoTimestamp(timestampStr);
    if (timestamp == null) return true;
    
    final secondsSinceUpdate = DateTime.now().difference(timestamp).inSeconds;
    return secondsSinceUpdate > 10;
  }

  // Start staleness monitoring - follows sequence: zero power (write once), stale (write every 10s), else (no write)
  void _startStalenessMonitoring(Map<String, dynamic> lastData, String serviceTag) {
    // Extract and store the timestamp we're monitoring
    final timestampStr = lastData['timestamp'] as String?;
    DateTime? newTimestamp;
    if (timestampStr != null) {
      newTimestamp = _parseIsoTimestamp(timestampStr);
    }
    
    // Reset zero power flag if timestamp changed (new data arrived)
    if (_monitoredTimestamp != null && newTimestamp != null && 
        !newTimestamp.isAtSameMomentAs(_monitoredTimestamp!)) {
      _hasWrittenForZeroPower = false;
    } else if (_monitoredTimestamp == null && newTimestamp != null) {
      // First time monitoring, reset flag
      _hasWrittenForZeroPower = false;
    }
    
    // Stop any existing timer
    _stopStalenessMonitoring();
    
    // Store data for monitoring
    _lastReceivedData = Map<String, dynamic>.from(lastData);
    _monitoringServiceTag = serviceTag;
    _monitoredTimestamp = newTimestamp;
    
    // Check power value
    final powerValue = lastData['powerGeneratedInWatts'] ?? lastData['liveEffort'];
    final powerWatts = (powerValue is num) 
        ? powerValue.toDouble() 
        : (powerValue is String ? double.tryParse(powerValue) ?? 0.0 : 0.0);
    
    // Sequence 1: If power is zero, write once and stop
    if (powerWatts == 0.0 && !_hasWrittenForZeroPower) {
      _writeZeroValueRecord(_lastReceivedData!, _monitoringServiceTag!);
      _hasWrittenForZeroPower = true;
      _stopStalenessMonitoring();
      return;
    }
    
    // Sequence 2: If power > 0, start monitoring for staleness
    // Start timer for 10 seconds
    _stalenessTimer = Timer(const Duration(seconds: 10), () {
      // Check if we still have the same timestamp (no new data received)
      if (_lastReceivedData != null && _monitoringServiceTag != null && _monitoredTimestamp != null) {
        final currentTimestampStr = _lastReceivedData!['timestamp'] as String?;
        if (currentTimestampStr != null) {
          final currentTimestamp = _parseIsoTimestamp(currentTimestampStr);
          // If timestamp hasn't changed from what we're monitoring, it's stale
          if (currentTimestamp != null && 
              currentTimestamp.isAtSameMomentAs(_monitoredTimestamp!)) {
            // Write zero-value record
            _writeZeroValueRecord(_lastReceivedData!, _monitoringServiceTag!);
            // Restart timer to write again every 10 seconds (continuous)
            _startStalenessMonitoring(_lastReceivedData!, _monitoringServiceTag!);
          } else {
            // Timestamp changed, stop monitoring (new data arrived)
            _stopStalenessMonitoring();
          }
        }
      }
    });
  }

  // Stop staleness monitoring
  void _stopStalenessMonitoring() {
    _stalenessTimer?.cancel();
    _stalenessTimer = null;
    _lastReceivedData = null;
    _monitoringServiceTag = null;
    _monitoredTimestamp = null;
    // Don't reset _hasWrittenForZeroPower here - it resets when power > 0
  }

  // Stream dashboard data for real-time updates from deviceEnergyData
  // Data is stored by service tag (e.g., "MNT 0001"), not by userId
  // New structure: deviceEnergyData/MNT0001/{document_id}/[fields]
  // Includes live effort with timestamp and today's aggregated data
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

      // Remove spaces and dashes from service tag for database lookup, convert to uppercase
      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();

      // Stream data using the service tag - handle nested structure
      return _database.child('deviceEnergyData/$cleanServiceTag').onValue.asyncMap((event) async {
        if (event.snapshot.exists) {
          final data = event.snapshot.value;
          
          // Handle nested structure: find latest document for live effort
          Map<String, dynamic>? latestDocument;
          DateTime? latestTimestamp;
          List<Map<String, dynamic>> allDocuments = [];
          
          if (data is Map<Object?, Object?>) {
            data.forEach((documentId, documentData) {
              if (documentData is Map<Object?, Object?>) {
                final document = Map<String, dynamic>.from(
                  documentData.map((key, value) => MapEntry(key.toString(), value)),
                );
                
                allDocuments.add(document);
                
                // Get timestamp to find the latest document
                final timestampStr = document['timestamp'] as String?;
                final timestamp = _parseIsoTimestamp(timestampStr);
                
                if (timestamp != null) {
                  if (latestTimestamp == null || timestamp.isAfter(latestTimestamp!)) {
                    latestTimestamp = timestamp;
                    latestDocument = document;
                  }
                } else if (latestDocument == null) {
                  latestDocument = document;
                }
              }
            });
          } else if (data is Map<Object?, Object?>) {
            // Fallback: handle flat structure
            final flatData = data;
            latestDocument = Map<String, dynamic>.from(
              flatData.map((key, value) => MapEntry(key.toString(), value)),
            );
            allDocuments.add(latestDocument);
          }
          
          if (latestDocument != null) {
            final result = Map<String, dynamic>.from(latestDocument!);
            
            // Consolidate live effort: always set liveEffort = powerGeneratedInWatts
            final powerWatts = result['powerGeneratedInWatts'];
            if (powerWatts != null) {
              final effortValue = (powerWatts is num) 
                  ? powerWatts.toDouble() 
                  : (powerWatts is String ? double.tryParse(powerWatts) ?? 0.0 : 0.0);
              result['liveEffort'] = effortValue;
            } else {
              result['liveEffort'] = 0.0;
            }
            
            // Add live effort timestamp
            if (latestTimestamp != null) {
              result['liveEffortTimestamp'] = latestTimestamp;
            }
            
            // Start/restart staleness monitoring with latest data
            _startStalenessMonitoring(result, serviceTag);
            
            // Calculate today's aggregated data
            double todayDistance = 0.0;
            double todayWh = 0.0;
            
            for (final doc in allDocuments) {
              final timestampStr = doc['timestamp'] as String?;
              final timestamp = _parseIsoTimestamp(timestampStr);
              
              if (timestamp != null && _isToday(timestamp)) {
                // Sum distance
                final distance = doc['totalDistanceKm'];
                if (distance != null) {
                  final distanceValue = (distance is num) ? distance.toDouble() : 
                                     (distance is String) ? double.tryParse(distance) ?? 0.0 : 0.0;
                  todayDistance += distanceValue;
                }
                
                // Sum energy (Wh)
                final totalWh = doc['totalWh'];
                if (totalWh != null) {
                  final whValue = (totalWh is num) ? totalWh.toDouble() : 
                                (totalWh is String) ? double.tryParse(totalWh) ?? 0.0 : 0.0;
                  todayWh += whValue;
                }
              }
            }
            
            result['todayDistance'] = todayDistance;
            result['todayWh'] = todayWh;
            
            return result;
          }
        }
        return null;
      }).handleError((error) {
        // Stop monitoring on stream error
        _stopStalenessMonitoring();
        throw error;
      });
    });
  }

  // Get today's metrics from deviceEnergyData
  // Data is stored by service tag (e.g., "MNT 0001"), not by userId
  // New structure: deviceEnergyData/MNT0001/{document_id}/[fields]
  Future<Map<String, dynamic>?> getTodayMetrics() async {
    try {
      final userId = getCurrentuserTable();
      if (userId == null) return null;

      // First, get the user's service tag
      final serviceTagSnapshot = await _database.child('userTable/$userId/serviceTag').get();
      if (!serviceTagSnapshot.exists) return null;

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) return null;

      // Remove spaces and dashes from service tag for database lookup
      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();

      final snapshot = await _database.child('deviceEnergyData/$cleanServiceTag').get();
      
      if (snapshot.exists) {
        final data = snapshot.value;
        
        // Handle nested structure: find latest document
        if (data is Map<Object?, Object?>) {
          Map<String, dynamic>? latestDocument;
          DateTime? latestTimestamp;
          
          data.forEach((documentId, documentData) {
            if (documentData is Map<Object?, Object?>) {
              final document = Map<String, dynamic>.from(
                documentData.map((key, value) => MapEntry(key.toString(), value)),
              );
              
              final timestampStr = document['timestamp'] as String?;
              final timestamp = _parseIsoTimestamp(timestampStr);
              
              if (timestamp != null) {
                if (latestTimestamp == null || timestamp.isAfter(latestTimestamp!)) {
                  latestTimestamp = timestamp;
                  latestDocument = document;
                }
              } else if (latestDocument == null) {
                latestDocument = document;
              }
            }
          });
          
          if (latestDocument != null) {
            final result = Map<String, dynamic>.from(latestDocument!);
            // Keep totalWh as-is (no conversion)
            return result;
          }
        } else {
          // Fallback: handle flat structure
          final flatData = data as Map<Object?, Object?>;
          final result = Map<String, dynamic>.from(
            flatData.map((key, value) => MapEntry(key.toString(), value)),
          );
          
          // Keep totalWh as-is (no conversion)
          return result;
        }
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
  // Sums all 'payout' fields from transactions where mntTag matches user's service tag
  // New structure: transactions/STN0001/{transaction_id}/[fields]
  Future<double> getTotalRedeems() async {
    try {
      final userId = getCurrentuserTable();
      if (userId == null) return 0.0;

      // First, get the user's service tag
      final serviceTagSnapshot = await _database.child('userTable/$userId/serviceTag').get();
      if (!serviceTagSnapshot.exists) return 0.0;

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) return 0.0;

      // Remove spaces and dashes from service tag for database lookup
      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();

      // Fetch all transactions - iterate through nested structure
      final transactionsSnapshot = await _database.child('transactions').get();
      
      if (!transactionsSnapshot.exists) {
        print('No transactions found');
        return 0.0;
      }

      final transactions = transactionsSnapshot.value as Map<Object?, Object?>?;
      if (transactions == null) return 0.0;

      double totalRedeems = 0.0;

      // Iterate through station IDs (STN0001, STN0002, etc.)
      transactions.forEach((stationId, stationData) {
        if (stationData is Map<Object?, Object?>) {
          // Iterate through transaction IDs under each station
          stationData.forEach((transactionId, transactionData) {
            if (transactionData is Map<Object?, Object?>) {
              final transaction = Map<String, dynamic>.from(
                transactionData.map((key, value) => MapEntry(key.toString(), value)),
              );

              // Check if this transaction belongs to the user's service tag
              final mntTag = transaction['mntTag'] as String?;
              if (mntTag != null) {
                final cleanMntTag = mntTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
                if (cleanMntTag == cleanServiceTag) {
                  // Sum the payout (changed from 'amount')
                  final payout = transaction['payout'];
                  if (payout != null) {
                    final payoutValue = (payout is num) ? payout.toDouble() : 
                                      (payout is String) ? double.tryParse(payout) ?? 0.0 : 0.0;
                    totalRedeems += payoutValue;
                  }
                }
              }
            }
          });
        }
      });

      print('Total redeems calculated: $totalRedeems for service tag: $cleanServiceTag');
      return totalRedeems;
    } catch (e) {
      print('Error calculating total redeems: $e');
      return 0.0;
    }
  }

  // Get total generated (Wh) from transactions table
  // Sums all powerSubmitted_Ah values from transactions where mntTag matches user's service tag
  // New structure: transactions/STN0001/{transaction_id}/[fields]
  // Note: powerSubmitted_Ah is in Ampere-hours, convert to Wh using voltage
  Future<double> getTotalGenerated() async {
    try {
      final userId = getCurrentuserTable();
      if (userId == null) return 0.0;

      // First, get the user's service tag
      final serviceTagSnapshot = await _database.child('userTable/$userId/serviceTag').get();
      if (!serviceTagSnapshot.exists) return 0.0;

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) return 0.0;

      // Remove spaces and dashes from service tag for database lookup
      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();

      // Fetch all transactions - iterate through nested structure
      final transactionsSnapshot = await _database.child('transactions').get();
      
      if (!transactionsSnapshot.exists) {
        print('No transactions found for total generated');
        return 0.0;
      }

      final transactions = transactionsSnapshot.value as Map<Object?, Object?>?;
      if (transactions == null) return 0.0;

      double totalGenerated = 0.0;

      // Iterate through station IDs (STN0001, STN0002, etc.)
      transactions.forEach((stationId, stationData) {
        if (stationData is Map<Object?, Object?>) {
          // Iterate through transaction IDs under each station
          stationData.forEach((transactionId, transactionData) {
            if (transactionData is Map<Object?, Object?>) {
              final transaction = Map<String, dynamic>.from(
                transactionData.map((key, value) => MapEntry(key.toString(), value)),
              );

              // Check if this transaction belongs to the user's service tag
              final mntTag = transaction['mntTag'] as String?;
              if (mntTag != null) {
                final cleanMntTag = mntTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
                if (cleanMntTag == cleanServiceTag) {
                  // Get powerSubmitted_Ah (changed from 'powerSubmitted')
                  // powerSubmitted_Ah is in Ampere-hours, convert to kWh using voltage
                  final powerSubmittedAh = transaction['powerSubmitted_Ah'];
                  final voltage = transaction['voltage'];
                  
                  if (powerSubmittedAh != null && voltage != null) {
                    final ahValue = (powerSubmittedAh is num) ? powerSubmittedAh.toDouble() : 
                                   (powerSubmittedAh is String) ? double.tryParse(powerSubmittedAh) ?? 0.0 : 0.0;
                    final voltageValue = (voltage is num) ? voltage.toDouble() : 
                                        (voltage is String) ? double.tryParse(voltage) ?? 0.0 : 0.0;
                    
                    // Convert Ah to Wh: Wh = Ah * V
                    if (voltageValue > 0) {
                      final whValue = ahValue * voltageValue;
                      totalGenerated += whValue;
                    }
                  }
                }
              }
            }
          });
        }
      });

      print('Total generated calculated: ${totalGenerated.toStringAsFixed(2)} Wh for service tag: $cleanServiceTag');
      return totalGenerated;
    } catch (e) {
      print('Error calculating total generated: $e');
      return 0.0;
    }
  }

  // Get total batteries exchanged from transactions table
  // Counts all transactions where mntTag matches user's service tag
  // All transactions with matching mntTag are considered battery exchanges
  // New structure: transactions/STN0001/{transaction_id}/[fields]
  Future<int> getBatteriesExchanged() async {
    try {
      final userId = getCurrentuserTable();
      if (userId == null) return 0;

      // First, get the user's service tag
      final serviceTagSnapshot = await _database.child('userTable/$userId/serviceTag').get();
      if (!serviceTagSnapshot.exists) return 0;

      final serviceTag = serviceTagSnapshot.value as String?;
      if (serviceTag == null || serviceTag.isEmpty) return 0;

      // Remove spaces and dashes from service tag for database lookup
      final cleanServiceTag = serviceTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();

      // Fetch all transactions - iterate through nested structure
      final transactionsSnapshot = await _database.child('transactions').get();
      
      if (!transactionsSnapshot.exists) return 0;

      final transactions = transactionsSnapshot.value as Map<Object?, Object?>?;
      if (transactions == null) return 0;

      int batteryCount = 0;

      // Iterate through station IDs (STN0001, STN0002, etc.)
      transactions.forEach((stationId, stationData) {
        if (stationData is Map<Object?, Object?>) {
          // Iterate through transaction IDs under each station
          stationData.forEach((transactionId, transactionData) {
            if (transactionData is Map<Object?, Object?>) {
              final transaction = Map<String, dynamic>.from(
                transactionData.map((key, value) => MapEntry(key.toString(), value)),
              );

              final mntTag = transaction['mntTag'] as String?;
              if (mntTag != null) {
                final cleanMntTag = mntTag.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
                if (cleanMntTag == cleanServiceTag) {
                  // Count all transactions with matching mntTag as battery exchanges
                  batteryCount++;
                }
              }
            }
          });
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
import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/utils/constants.dart';
import 'package:lakbyke_mobile/utils/formatting.dart';
import 'package:lakbyke_mobile/widgets/index.dart';
import 'package:lakbyke_mobile/screens/home/welcome_modal.dart';
import 'package:lakbyke_mobile/screens/template/header.dart';
// import 'package:lakbyke_mobile/screens/template/chat_fab.dart';
import 'package:lakbyke_mobile/services/home.dart';
import 'package:lakbyke_mobile/screens/main_navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeService _homeService = HomeService();
  Map<String, dynamic>? _homeData;
  String? _serviceTag;
  bool _isLoading = true;
  static bool _welcomeModalShown = false; // Track if modal was shown in this session
  DateTime? _lastEffortTimestamp; // Track the last effort timestamp received
  DateTime? _currentTimestampFirstSeen; // Track when the current timestamp was first seen

  @override
  void initState() {
    super.initState();
    _initializeHome();
  }

  Future<void> _initializeHome() async {
    // Load initial data first
    await _loadHomeData();
    await _loadServiceTag();
    // Then set up real-time updates
    _setupRealtimeUpdates();
    // Set up periodic refresh for effort (every 30 seconds) to check for staleness
    _setupPeriodicEffortCheck();
    // Show welcome modal with yesterday's achievements
    _showWelcomeModal();
  }

  // Show welcome modal with yesterday's achievements (only once per session)
  Future<void> _showWelcomeModal() async {
    // Only show once per app session
    if (_welcomeModalShown) return;
    
    // Wait a bit for the home to load (reduced delay for faster UX)
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (!mounted) return;
    
    try {
      final yesterdayData = await _homeService.getYesterdayData();
      final yesterdayDistance = yesterdayData['yesterdayDistance'] as double? ?? 0.0;
      final yesterdayWh = yesterdayData['yesterdayWh'] as double? ?? 0.0;
      
      if (mounted) {
        _welcomeModalShown = true; // Mark as shown
        WelcomeModal.show(
          context,
          yesterdayDistance: yesterdayDistance,
          yesterdayWh: yesterdayWh,
        );
      }
    } catch (e) {
      // Error showing welcome modal
    }
  }

  // Set up periodic check to refresh effort data and detect staleness
  void _setupPeriodicEffortCheck() {
    // Check every 5 seconds to update stale indicator and reset effort to zero if stale
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          // Check if the same timestamp has been used for 10 seconds
          if (_lastEffortTimestamp != null && _currentTimestampFirstSeen != null) {
            final secondsSinceFirstSeen = DateTime.now().difference(_currentTimestampFirstSeen!).inSeconds;
            if (secondsSinceFirstSeen > 10) {
              // Same timestamp for more than 10 seconds, set effort to zero
              if (_homeData != null) {
                _homeData!['liveEffort'] = 0.0;
              }
            }
          } else {
            // No timestamp ever received, set effort to zero
            if (_homeData != null) {
              _homeData!['liveEffort'] = 0.0;
            }
          }
        });
        _setupPeriodicEffortCheck(); // Schedule next check
      }
    });
  }

  // Set up real-time stream for deviceEnergyData updates
  void _setupRealtimeUpdates() {
    _homeService.getHomeDataStream().listen(
      (deviceEnergyData) {
        if (deviceEnergyData != null) {
          // Check if we have a new effort timestamp
          final newEffortTimestamp = deviceEnergyData['liveEffortTimestamp'];
          DateTime? parsedTimestamp;
          if (newEffortTimestamp != null) {
            if (newEffortTimestamp is DateTime) {
              parsedTimestamp = newEffortTimestamp;
            } else if (newEffortTimestamp is String) {
              parsedTimestamp = DateTime.tryParse(newEffortTimestamp);
            }
          }
          
          // Update last effort timestamp and track when current timestamp was first seen
          if (parsedTimestamp != null) {
            // Check if this is the same timestamp as before
            final isSameTimestamp = _lastEffortTimestamp != null && 
                parsedTimestamp.isAtSameMomentAs(_lastEffortTimestamp!);
            
            if (!isSameTimestamp) {
              // New timestamp received, update and reset the first seen time
              _lastEffortTimestamp = parsedTimestamp;
              _currentTimestampFirstSeen = DateTime.now();
            } else if (_currentTimestampFirstSeen == null) {
              // Same timestamp but we haven't tracked when it was first seen
              _currentTimestampFirstSeen = DateTime.now();
            }
            // If same timestamp and we already have _currentTimestampFirstSeen, keep it
          }
          
          setState(() {
            // Merge real-time deviceEnergyData with existing transaction data
            if (_homeData != null) {
              // Preserve transaction data (totalRedeems, totalGenerated, batteriesExchanged)
              final totalRedeems = _homeData!['totalRedeems'];
              final totalGenerated = _homeData!['totalGenerated'];
              final batteriesExchanged = _homeData!['batteriesExchanged'];
              
              // Preserve today's data if not in stream update
              final todayDistance = deviceEnergyData['todayDistance'] ?? _homeData!['todayDistance'];
              final todayWh = deviceEnergyData['todayWh'] ?? _homeData!['todayWh'];
              
              // Update with new deviceEnergyData (includes live effort and today's data)
              _homeData = Map<String, dynamic>.from(deviceEnergyData);
              
              // Ensure today's data is set
              if (todayDistance != null) _homeData!['todayDistance'] = todayDistance;
              if (todayWh != null) _homeData!['todayWh'] = todayWh;
              
              // Restore transaction data
              if (totalRedeems != null) _homeData!['totalRedeems'] = totalRedeems;
              if (totalGenerated != null) _homeData!['totalGenerated'] = totalGenerated;
              if (batteriesExchanged != null) _homeData!['batteriesExchanged'] = batteriesExchanged;
            } else {
              // First update, just set the data
              _homeData = deviceEnergyData;
            }
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _homeService.getHomeData();
      if (data != null) {
        // Initialize last effort timestamp from initial data
        final initialEffortTimestamp = data['liveEffortTimestamp'];
        if (initialEffortTimestamp != null) {
          DateTime? parsedTimestamp;
          if (initialEffortTimestamp is DateTime) {
            parsedTimestamp = initialEffortTimestamp;
          } else if (initialEffortTimestamp is String) {
            parsedTimestamp = DateTime.tryParse(initialEffortTimestamp);
          }
          if (parsedTimestamp != null) {
            _lastEffortTimestamp = parsedTimestamp;
            _currentTimestampFirstSeen = DateTime.now();
          }
        }
      }
      setState(() {
        _homeData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadServiceTag() async {
    try {
      final tag = await _homeService.getServiceTag();
      setState(() {
        _serviceTag = tag;
      });
    } catch (e) {
      // Error loading service tag
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButton: const ChatFAB(), // Hidden for now
      // The body will handle the content, including the curved header
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Full-screen dark background (for the sides)
            Container(
              color: Colors.black, // The black sides of the screen
            ),

            // 2. The main scrollable content area
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 60), // Space for the top header bar
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white, // White background for the main content
                  ),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _loadHomeData();
                      await _loadServiceTag();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // --- Battery Status and Today's Metrics ---
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildBatteryStatus(),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(color: Colors.grey, thickness: 0.5),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                      child: Text(
                                        'metrics',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF317263),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(color: Colors.grey, thickness: 0.5),
                                    ),
                                  ],
                                ),
                                _buildTodayMetrics(),
                                const Divider(color: Colors.grey, thickness: 0.5),
                              ],
                            ),
                          ),

                          // --- Service Tag Section ---
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/tagicon2.png',
                                  width: 18.0,
                                  height: 18.0,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _serviceTag ?? 'Loading...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkText,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // --- Action Buttons Section (Total Generated, Redeems, Exchanged) ---
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                            child: _buildActionButtons(context),
                          ),
                          
                          // Add some bottom padding
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // 3. Fixed Header (App Bar) - This needs to be above the scrollable content
            const Header(),
          ],
        ),
      ),
    );
  }


  // Widget for the Battery Status
  Widget _buildBatteryStatus() {
    // Battery = mountBatteryPercentage from deviceEnergyData
    final batteryLevel = _homeData?['mountBatteryPercentage'] ?? 85;
    final batteryPercent = batteryLevel is int ? batteryLevel : (batteryLevel as num).toInt();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ResponsiveIcon(
          icon: Icons.battery_full,
          maxSizePercent: 0.12,
          color: AppColors.homePrimary,
          minSize: 40.0,
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Battery',
              style: TextStyle(fontSize: 20, color: AppColors.darkText),
            ),
            Text(
              _isLoading ? '...' : '$batteryPercent%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Check if effort data is stale (same timestamp for >10 seconds)
  bool _isEffortStale(DateTime? timestamp) {
    if (timestamp == null) return true;
    // Check if this timestamp matches the current one and has been the same for 10 seconds
    if (_lastEffortTimestamp != null && 
        _currentTimestampFirstSeen != null) {
      // Check if the timestamp matches the last one we're tracking
      if (timestamp.isAtSameMomentAs(_lastEffortTimestamp!)) {
        final secondsSinceFirstSeen = DateTime.now().difference(_currentTimestampFirstSeen!).inSeconds;
        return secondsSinceFirstSeen > 10;
      }
    }
    // If timestamp doesn't match or we don't have tracking info, consider it not stale (it might be new)
    return false;
  }

  // Widget for the Today's Metrics (Distance, Effort, Generated)
  Widget _buildTodayMetrics() {
    // Fields from deviceEnergyData:
    // Distance = todayDistance (sum of today's records)
    // Effort = liveEffort (latest powerGeneratedInWatts with timestamp)
    // Generated = todayWh (sum of today's records)
    
    // Safely extract and convert values
    final distanceValue = _homeData?['todayDistance'];
    final effortValue = _homeData?['liveEffort'] ?? _homeData?['powerGeneratedInWatts'];
    final effortTimestamp = _homeData?['liveEffortTimestamp'];
    final generatedValue = _homeData?['todayWh'];
    
    // Convert to numbers with safe fallback
    final distance = _convertToDouble(distanceValue) ?? 0.00;
    final generated = _convertToDouble(generatedValue) ?? 0.00;
    
    // Check if effort is stale and set to zero if stale
    DateTime? effortTime;
    if (effortTimestamp != null) {
      if (effortTimestamp is DateTime) {
        effortTime = effortTimestamp;
      } else if (effortTimestamp is String) {
        effortTime = DateTime.tryParse(effortTimestamp);
      }
    }
    final isStale = _isEffortStale(effortTime);
    // If stale (>30 seconds), set effort to zero
    final effort = isStale ? 0.00 : (_convertToDouble(effortValue) ?? 0.00);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MetricItem(
            icon: Icons.directions_bike,
            value: _isLoading ? '...' : '${distance.toStringAsFixed(1)}km',
            label: 'Distance',
            subtitle: 'Today',
          ),
          _MetricItem(
            icon: Icons.flash_on,
            value: _isLoading ? '...' : '${effort.toInt()}W',
            label: 'Effort',
            subtitle: isStale ? 'Stale' : 'Live',
            isLive: !isStale,
          ),
          _MetricItem(
            icon: Icons.check_box,
            value: _isLoading ? '...' : formatEnergy(generated),
            label: 'Generated',
            subtitle: 'Today',
          ),
        ],
      ),
    );
  }

  // Helper method to safely convert values to double
  double? _convertToDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Widget for the bottom action buttons
  Widget _buildActionButtons(BuildContext context) {
    // Determine the width for the two side-by-side buttons
    // Screen width - outer padding (40) - container padding (40) - spacing (20)
    final double buttonWidth = (MediaQuery.of(context).size.width - 40 - 40 - 20) / 2;

    final totalGenerated = (_homeData?['totalGenerated'] as num?)?.toDouble() ?? 0.0;
    final totalRedeems = (_homeData?['totalRedeems'] as num?)?.toDouble() ?? 0.0;
    final batteriesExchanged = (_homeData?['batteriesExchanged'] as num?)?.toInt() ?? 0;
    
    // Check if user has no data at all
    final hasNoData = !_isLoading && 
                      totalGenerated == 0.0 && 
                      totalRedeems == 0.0 && 
                      batteriesExchanged == 0;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Color(0xFF317263), // Dark green background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Show empty state message if no data
          if (hasNoData) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Colors.white.withOpacity(0.8), size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'No data yet. Start biking to generate energy and earn rewards!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Total Generated & Total Redeems Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Total Generated Button
              _ActionButton(
                icon: Icons.flash_on,
                title: 'Total Generated',
                value: _isLoading ? '...' : formatEnergy(totalGenerated),
                color: AppColors.homePrimary, // Dark Green
                width: buttonWidth,
                onViewHistory: () {
                  // Navigate to History screen with Energy History tab (index 0) within MainNavigation
                  MainNavigation.navigateToHistoryFromContext(context, initialTabIndex: 0);
                },
              ),
              // Total Redeems Button
              _ActionButton(
                icon: Icons.account_balance_wallet,
                title: 'Total Redeems',
                value: _isLoading ? '...' : '₱ ${totalRedeems.toInt()}',
                color: AppColors.homePrimary, // Dark Green
                width: buttonWidth,
                isCurrency: true,
                onViewHistory: () {
                  // Navigate to History screen with Transaction History tab (index 1) within MainNavigation
                  MainNavigation.navigateToHistoryFromContext(context, initialTabIndex: 1);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Batteries Exchanged Button (Full Width)
          _ActionButton(
            icon: Icons.battery_charging_full,
            title: _isLoading 
                ? 'Loading...' 
                : '$batteriesExchanged Batteries Exchanged',
            value: '', // No value displayed below the title
            color: AppColors.homePrimary, // Dark Green
            width: double.infinity,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}

// --- Helper Widgets for Reusability ---

// Widget for the 3 Metric Items (Distance, Effort, Generated)
class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String? subtitle;
  final bool isLive;

  const _MetricItem({
    required this.icon,
    required this.value,
    required this.label,
    this.subtitle,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ResponsiveIcon(
          icon: icon,
          maxSizePercent: 0.06,
          color: AppColors.homeAccent,
          minSize: 20.0,
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 2),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isLive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isLive ? Colors.green : Colors.grey,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLive)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isLive ? Colors.green.shade700 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// Widget for the main Action Buttons (Total Generated, Redeems, Exchanged)
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final double width;
  final bool isCurrency;
  final bool isFullWidth;
  final VoidCallback? onViewHistory;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.width,
    this.isCurrency = false,
    this.isFullWidth = false,
    this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onViewHistory,
        borderRadius: BorderRadius.circular(AppDimensions.homeActionButtonRadius),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(AppDimensions.homeActionButtonPadding),
          decoration: BoxDecoration(
            color: Color(0xFF317263), // Dark green background
            borderRadius: BorderRadius.circular(AppDimensions.homeActionButtonRadius),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
        crossAxisAlignment: isFullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (!isFullWidth)
            Column(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 40.0,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          if (isFullWidth)
            Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 32.0,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

          if (value.isNotEmpty) // Only show value if it's not empty
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onViewHistory,
                  child: Text(
                    'View History',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                      decoration: onViewHistory != null ? TextDecoration.underline : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
        ],
          ),
        ),
      ),
    );
  }
}

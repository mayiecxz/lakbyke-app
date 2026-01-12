import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/utils/constants.dart';
import 'package:lakbyke_mobile/widgets/index.dart';
import 'package:lakbyke_mobile/screens/template/header.dart';
import 'package:lakbyke_mobile/screens/template/screen_title.dart';
import 'package:lakbyke_mobile/services/dashboard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  Map<String, dynamic>? _dashboardData;
  String? _serviceTag;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadServiceTag();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _dashboardService.getDashboardData();
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadServiceTag() async {
    try {
      final tag = await _dashboardService.getServiceTag();
      setState(() {
        _serviceTag = tag;
      });
    } catch (e) {
      print('Error loading service tag: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _loadDashboardData();
                      await _loadServiceTag();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // --- DASHBOARD Header Area ---
                          const ScreenTitle(title: AppStrings.dashboard),
                          
                          // --- Battery Status and Today's Metrics ---
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                            child: Column(
                              children: [
                                _buildBatteryStatus(),
                                const SizedBox(height: 15),
                                const Divider(color: Colors.grey, thickness: 0.5),
                                _buildTodayMetrics(),
                                const Divider(color: Colors.grey, thickness: 0.5),
                              ],
                            ),
                          ),

                          // --- Service Tag Section ---
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  color: AppColors.dashboardPrimary,
                                  size: 18.0,
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
                            padding: const EdgeInsets.all(20.0),
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

  // Widget for the main "DASHBOARD" title and green background curve is now in ScreenTitle component.

  // Widget for the Battery Status
  Widget _buildBatteryStatus() {
    // Battery = mountBatteryPercentage from deviceEnergyData
    final batteryLevel = _dashboardData?['mountBatteryPercentage'] ?? 85;
    final batteryPercent = batteryLevel is int ? batteryLevel : (batteryLevel as num).toInt();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ResponsiveIcon(
          icon: Icons.battery_full,
          maxSizePercent: 0.12,
          color: AppColors.dashboardPrimary,
          minSize: 40.0,
        ),
        const SizedBox(width: 15),
        const Text(
          'Battery',
          style: TextStyle(fontSize: 20, color: AppColors.darkText),
        ),
        const SizedBox(width: 15),
        Text(
          _isLoading ? '...' : '$batteryPercent%',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  // Widget for the Today's Metrics (Distance, Effort, Generated)
  Widget _buildTodayMetrics() {
    // Fields from deviceEnergyData:
    // Distance = totalDistanceKm
    // Effort = powerGeneratedInWatts
    // Generated = totalKwh
    final distance = _dashboardData?['totalDistanceKm'] ?? 0.00;
    final effort = _dashboardData?['powerGeneratedInWatts'] ?? 0.00;
    final generated = _dashboardData?['totalKwh'] ?? 0.00;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MetricItem(
            icon: Icons.directions_bike,
            value: _isLoading ? '...' : '${(distance as num).toStringAsFixed(1)}km',
            label: 'Distance',
          ),
          _MetricItem(
            icon: Icons.flash_on,
            value: _isLoading ? '...' : '${(effort as num).toInt()}W',
            label: 'Effort',
          ),
          _MetricItem(
            icon: Icons.check_box,
            value: _isLoading ? '...' : '${(generated as num).toStringAsFixed(1)}kWh',
            label: 'Generated',
          ),
        ],
      ),
    );
  }

  // Widget for the bottom action buttons
  Widget _buildActionButtons(BuildContext context) {
    // Determine the width for the two side-by-side buttons
    final double buttonWidth = (MediaQuery.of(context).size.width - 40 - 20) / 2; // Screen width - padding - spacing

    final totalGenerated = _dashboardData?['totalGenerated'] ?? 0.0;
    final totalRedeems = _dashboardData?['totalRedeems'] ?? 0;
    final batteriesExchanged = _dashboardData?['batteriesExchanged'] ?? 0;

    return Column(
      children: [
        // Total Generated & Total Redeems Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Total Generated Button
            _ActionButton(
              icon: Icons.flash_on,
              title: 'Total Generated',
              value: _isLoading ? '...' : '${(totalGenerated as num).toStringAsFixed(2)}kWh',
              color: AppColors.dashboardPrimary, // Dark Green
              width: buttonWidth,
            ),
            // Total Redeems Button
            _ActionButton(
              icon: Icons.account_balance_wallet,
              title: 'Total Redeems',
              value: _isLoading ? '...' : '₱ ${(totalRedeems as num).toInt()}',
              color: AppColors.dashboardPrimary, // Dark Green
              width: buttonWidth,
              isCurrency: true,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Batteries Exchanged Button (Full Width)
        _ActionButton(
          icon: Icons.battery_charging_full,
          title: _isLoading 
              ? 'Loading...' 
              : '${(batteriesExchanged as num).toInt()} Batteries Exchanged',
          value: '', // No value displayed below the title
          color: AppColors.dashboardAccent, // Light Green/Teal
          width: double.infinity,
          isFullWidth: true,
        ),
      ],
    );
  }
}

// --- Helper Widgets for Reusability ---

// Widget for the 3 Metric Items (Distance, Effort, Generated)
class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetricItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ResponsiveIcon(
          icon: icon,
          maxSizePercent: 0.10,
          color: AppColors.dashboardAccent,
          minSize: 30.0,
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
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

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.width,
    this.isCurrency = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppDimensions.dashboardActionButtonPadding),
      decoration: BoxDecoration(
        color: isFullWidth ? Colors.white : color,
        borderRadius: BorderRadius.circular(AppDimensions.dashboardActionButtonRadius),
        border: isFullWidth ? Border.all(color: color, width: 2) : null,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isFullWidth ? color : AppColors.lightText,
                size: 28.0,
              ),
              const SizedBox(width: 8),
              if (!isFullWidth) // Title is separate for the full-width button
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isFullWidth ? color : AppColors.lightText,
                  ),
                ),
            ],
          ),
          if (isFullWidth) 
             Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 0),
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),

          if (value.isNotEmpty) // Only show value if it's not empty
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isFullWidth ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                Text(
                  'View History',
                  style: TextStyle(
                    fontSize: 12,
                    color: isFullWidth ? AppColors.darkText.withOpacity(0.7) : AppColors.lightText.withOpacity(0.7),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

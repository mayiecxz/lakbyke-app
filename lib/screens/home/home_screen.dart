import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/utils/constants.dart';
import 'package:lakbyke_mobile/utils/formatting.dart';
import 'package:lakbyke_mobile/widgets/index.dart';
import 'package:lakbyke_mobile/screens/home/welcome_modal.dart';
import 'package:lakbyke_mobile/screens/template/header.dart';
import 'package:lakbyke_mobile/features/home/providers/home_providers.dart';
import 'package:lakbyke_mobile/features/home/domain/models/home_data.dart';
import 'package:lakbyke_mobile/screens/main_navigation.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static bool _welcomeModalShown = false;

  @override
  void initState() {
    super.initState();
    // Show welcome modal after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeModal();
    });
  }

  Future<void> _showWelcomeModal() async {
    if (_welcomeModalShown) return;
    
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    
    try {
      final yesterdayData = await ref.read(yesterdayDataProvider.future);
      final yesterdayDistance = yesterdayData['yesterdayDistance'] as double? ?? 0.0;
      final yesterdayWh = yesterdayData['yesterdayWh'] as double? ?? 0.0;
      
      if (mounted) {
        _welcomeModalShown = true;
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

  @override
  Widget build(BuildContext context) {
    // Watch the homeDataStreamProvider (SINGLE Firebase listener!)
    final homeDataAsync = ref.watch(homeDataStreamProvider);
    final serviceTagAsync = ref.watch(serviceTagProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(color: Colors.black),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: homeDataAsync.when(
                    loading: () => const AppLoadingOverlay(message: 'Loading your ride data...'),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error loading data: $error'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.invalidate(homeDataStreamProvider);
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    data: (homeData) => RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(homeDataStreamProvider);
                        ref.invalidate(serviceTagProvider);
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  _buildBatteryStatus(homeData),
                                  const SizedBox(height: 15),
                                  Row(
                                    children: [
                                      const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
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
                                      const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                                    ],
                                  ),
                                  _buildTodayMetrics(homeData),
                                  const Divider(color: Colors.grey, thickness: 0.5),
                                ],
                              ),
                            ),
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
                                  serviceTagAsync.when(
                                    loading: () => const AppLoadingSpinner(size: AppSpinnerSize.small),
                                    error: (_, __) => const Text('Error loading tag'),
                                    data: (tag) => Text(
                                      tag ?? 'No tag',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.darkText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                              child: _buildActionButtons(context, homeData),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Header(),
          ],
        ),
      ),
    );
  }

  static const double _batteryChargeRatePer100Percent = 30.0; // ₱30 flat per 100% charge

  Widget _buildBatteryStatus(HomeData? homeData) {
    final batteryLevel = homeData?.mountBatteryPercentage;
    final bool hasBatteryData = batteryLevel != null;
    final int? batteryPercent = batteryLevel?.toInt();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ResponsiveIcon(
                icon: hasBatteryData ? Icons.battery_full : Icons.battery_unknown,
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
                  homeData == null
                      ? const SizedBox(
                          height: 48,
                          child: Center(child: AppLoadingSpinner(size: AppSpinnerSize.small)),
                        )
                      : Text(
                          batteryPercent != null ? '$batteryPercent%' : 'No battery detected',
                          style: TextStyle(
                            fontSize: batteryPercent != null ? 48 : 16,
                            fontWeight: FontWeight.bold,
                            color: batteryPercent != null
                                ? AppColors.darkText.withOpacity(0.8)
                                : AppColors.textSecondary,
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        _BatteryCostWidget(
          batteryPercent: batteryPercent,
          onTap: () => _showBatteryCostModal(context, batteryPercent),
        ),
      ],
    );
  }

  void _showBatteryCostModal(BuildContext context, int? batteryPercent) {
    final hasData = batteryPercent != null;
    final cost = hasData ? (batteryPercent / 100.0) * _batteryChargeRatePer100Percent : 0.0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Battery value',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF317263),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Equivalent price of your charged battery as of this moment, based on a flat rate per full charge.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.homeAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.homePrimary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formula',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Battery % × ₱${_batteryChargeRatePer100Percent.toStringAsFixed(0)}.00 per 100% charge',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Current battery',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasData ? '$batteryPercent%' : 'No battery data',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Current battery value',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF317263)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasData ? '₱${cost.toStringAsFixed(2)}' : '—',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF317263)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF317263),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayMetrics(HomeData? homeData) {
    final distance = homeData?.todayDistance ?? 0.0;
    final generated = homeData?.todayWh ?? 0.0;
    final effort = (homeData?.isEffortStale ?? true) ? 0.0 : (homeData?.liveEffort ?? 0.0);
    final isStale = homeData?.isEffortStale ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MetricItem(
            icon: Icons.directions_bike,
            value: homeData == null ? null : (distance.abs() >= 1000 ? '${formatCompactNumber(distance, 1)}km' : '${distance.toStringAsFixed(1)}km'),
            label: 'Distance',
            subtitle: 'Today',
          ),
          _MetricItem(
            icon: Icons.flash_on,
            value: homeData == null ? null : '${effort.toInt()}W',
            label: 'Effort',
            subtitle: isStale ? 'Stale' : 'Live',
            isLive: !isStale,
          ),
          _MetricItem(
            icon: Icons.check_box,
            value: homeData == null ? null : (generated >= 1000000 ? '${formatCompactNumber(generated / 1000)} kWh' : formatEnergy(generated)),
            label: 'Generated',
            subtitle: 'Today',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, HomeData? homeData) {
    final double buttonWidth = (MediaQuery.of(context).size.width - 40 - 40 - 20) / 2;

    final totalGenerated = homeData?.totalGenerated ?? 0.0;
    final totalRedeems = homeData?.totalRedeems ?? 0.0;
    final batteriesExchanged = homeData?.batteriesExchanged ?? 0;
    
    final hasNoData = homeData != null && totalGenerated == 0.0 && totalRedeems == 0.0 && batteriesExchanged == 0;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Color(0xFF317263),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
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
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ActionButton(
                icon: Icons.flash_on,
                title: 'Total Generated',
                value: homeData == null ? null : (totalGenerated >= 1000000 ? '${formatCompactNumber(totalGenerated / 1000)} kWh' : formatEnergy(totalGenerated)),
                color: AppColors.homePrimary,
                width: buttonWidth,
                onViewHistory: () => MainNavigation.navigateToHistoryFromContext(context, initialTabIndex: 0),
              ),
              _ActionButton(
                icon: Icons.account_balance_wallet,
                title: 'Total Redeems',
                value: homeData == null ? null : formatCompactCurrency(totalRedeems),
                color: AppColors.homePrimary,
                width: buttonWidth,
                isCurrency: true,
                onViewHistory: () => MainNavigation.navigateToHistoryFromContext(context, initialTabIndex: 1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ActionButton(
            icon: Icons.battery_charging_full,
            title: homeData == null ? null : '${batteriesExchanged >= 1000 ? formatCompactNumber(batteriesExchanged, 0) : batteriesExchanged} Batteries Exchanged',
            value: '',
            color: AppColors.homePrimary,
            width: double.infinity,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}

// --- Helper Widgets for Reusability ---

class _BatteryCostWidget extends StatelessWidget {
  final int? batteryPercent;
  final VoidCallback onTap;

  const _BatteryCostWidget({required this.batteryPercent, required this.onTap});

  static const double _ratePer100 = 30.0;

  @override
  Widget build(BuildContext context) {
    final hasData = batteryPercent != null;
    final cost = hasData ? (batteryPercent! / 100.0) * _ratePer100 : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.homeAccent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.homePrimary.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.monetization_on, color: AppColors.homePrimary, size: 22),
              const SizedBox(height: 4),
              Text(
                hasData ? '₱${cost.toStringAsFixed(0)}' : '—',
                style: TextStyle(
                  fontSize: hasData ? 18 : 14,
                  fontWeight: FontWeight.bold,
                  color: hasData ? AppColors.darkText : Colors.grey,
                ),
              ),
              Text(
                'Value',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget for the 3 Metric Items (Distance, Effort, Generated)
class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String? value;
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
        value != null
            ? Text(
                value!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              )
            : const AppLoadingSpinner(size: AppSpinnerSize.small),
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
  final String? title;
  final String? value;
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
            color: const Color(0xFF317263),
            borderRadius: BorderRadius.circular(AppDimensions.homeActionButtonRadius),
            border: Border.all(color: Colors.white, width: 2),
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
                    Icon(icon, color: Colors.white, size: 40.0),
                    const SizedBox(height: 8),
                    title != null
                        ? Text(
                            title!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : const AppLoadingSpinner(size: AppSpinnerSize.small, color: Colors.white),
                  ],
                ),
              if (isFullWidth)
                Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 32.0),
                    const SizedBox(width: 12),
                    Expanded(
                      child: title != null
                          ? Text(
                              title!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : const Center(child: AppLoadingSpinner(size: AppSpinnerSize.small, color: Colors.white)),
                    ),
                  ],
                ),
              if (value != null && value!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      value!,
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
                )
              else if (!isFullWidth && value == null)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: AppLoadingSpinner(size: AppSpinnerSize.small, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

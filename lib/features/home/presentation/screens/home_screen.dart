import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';
import 'package:lakbyke_mobile/core/formatting/formatting.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/index.dart';
import 'package:lakbyke_mobile/features/home/presentation/screens/welcome_modal.dart';
import 'package:lakbyke_mobile/features/home/providers/home_providers.dart';
import 'package:lakbyke_mobile/features/home/domain/models/home_data.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/app_router_controller.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/shell_navigator_key.dart';
import 'package:lakbyke_mobile/app/presentation/shell_routes.dart';
import 'package:lakbyke_mobile/features/home/presentation/components/battery_cost_widget.dart';
import 'package:lakbyke_mobile/features/home/presentation/components/battery_level_icon.dart';
import 'package:lakbyke_mobile/features/home/presentation/components/metric_item.dart';
import 'package:lakbyke_mobile/features/home/presentation/components/action_button.dart';

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
                padding: const EdgeInsets.only(top: 0),
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
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryStatus(HomeData? homeData) {
    final batteryLevel = homeData?.mountBatteryPercentage;
    final bool hasBatteryData = batteryLevel != null;
    final int? batteryPercent = batteryLevel?.toInt();
    final w = MediaQuery.of(context).size.width;
    final spacing = (w * 0.03).clamp(6.0, 14.0);
    final iconSize = (w * 0.14).clamp(40.0, 56.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              hasBatteryData
                  ? BatteryLevelIcon(
                      percentage: batteryPercent,
                      size: iconSize,
                    )
                  : Icon(
                      Icons.battery_unknown,
                      size: iconSize,
                      color: AppColors.homePrimary.withValues(alpha: 0.5),
                    ),
              SizedBox(width: spacing),
              Flexible(
                child: homeData == null
                    ? const SizedBox(
                        height: 48,
                        child: Center(child: AppLoadingSpinner(size: AppSpinnerSize.small)),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          batteryPercent != null ? '$batteryPercent%' : 'No battery detected',
                          style: TextStyle(
                            fontSize: batteryPercent != null ? 48 : 16,
                            fontWeight: FontWeight.bold,
                            color: batteryPercent != null
                                ? AppColors.darkText.withOpacity(0.8)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        SizedBox(width: spacing),
        BatteryCostWidget(
          batteryPercent: batteryPercent,
          onTap: () => _showBatteryCostModal(context, batteryPercent),
        ),
      ],
    );
  }

  void _showBatteryCostModal(BuildContext context, int? batteryPercent) {
    final hasData = batteryPercent != null;
    final rawCost = hasData ? (batteryPercent / 100.0) * BatteryCostWidget.ratePer100 : 0.0;
    final cost = hasData ? roundDownToMultipleOf5(rawCost).toDouble() : 0.0;

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
                      'Battery % × ₱${BatteryCostWidget.ratePer100.toStringAsFixed(0)}.00 per 100% charge, then rounded down to nearest ₱5',
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
                      hasData ? '₱${cost.toInt()}' : '—',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF317263)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Payout policy',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Payouts are issued in multiples of ₱5 only. Amounts shown are rounded down to the nearest ₱5 to reflect this limit.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.35),
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
          MetricItem(
            icon: Icons.directions_bike,
            value: homeData == null ? null : (distance.abs() >= 1000 ? '${formatCompactNumber(distance, 1)}km' : '${distance.toStringAsFixed(1)}km'),
            label: 'Distance',
            subtitle: 'Today',
          ),
          MetricItem(
            icon: Icons.flash_on,
            value: homeData == null ? null : '${effort.toInt()}W',
            label: 'Effort',
            subtitle: isStale ? 'Stale' : 'Live',
            isLive: !isStale,
          ),
          MetricItem(
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
              ActionButton(
                icon: Icons.flash_on,
                title: 'Total Generated',
                value: homeData == null ? null : (totalGenerated >= 1000000 ? '${formatCompactNumber(totalGenerated / 1000)} kWh' : formatEnergy(totalGenerated)),
                color: AppColors.homePrimary,
                width: buttonWidth,
                onViewHistory: () {
                  ref.read(shellNavigatorKeyProvider)?.currentState?.popUntil(
                    (route) => route.settings.name == ShellRoutes.dashboard,
                  );
                  ref.read(appRouterControllerProvider.notifier).navigateToHistoryFromDashboard(initialTabIndex: 0);
                },
              ),
              ActionButton(
                icon: Icons.account_balance_wallet,
                title: 'Total Redeems',
                value: homeData == null ? null : formatCompactCurrency(roundDownToMultipleOf5(totalRedeems)),
                color: AppColors.homePrimary,
                width: buttonWidth,
                isCurrency: true,
                onViewHistory: () {
                  ref.read(shellNavigatorKeyProvider)?.currentState?.popUntil(
                    (route) => route.settings.name == ShellRoutes.dashboard,
                  );
                  ref.read(appRouterControllerProvider.notifier).navigateToHistoryFromDashboard(initialTabIndex: 1);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          ActionButton(
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


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/index.dart';
import 'package:lakbyke_mobile/features/home/domain/models/home_data.dart';
import 'package:lakbyke_mobile/features/home/presentation/components/battery_cost_widget.dart';
import 'package:lakbyke_mobile/features/home/presentation/components/battery_level_icon.dart';
import 'package:lakbyke_mobile/features/home/presentation/widgets/battery_cost_modal.dart';

/// Top section: service tag + battery status in a container, battery value card on the same row.
class HomeBatterySection extends StatelessWidget {
  const HomeBatterySection({
    super.key,
    required this.homeData,
    required this.serviceTagAsync,
  });

  final HomeData? homeData;
  final AsyncValue<String?> serviceTagAsync;

  @override
  Widget build(BuildContext context) {
    final batteryPercent = homeData?.mountBatteryPercentage?.toInt();
    final w = MediaQuery.of(context).size.width;
    final spacing = (w * 0.03).clamp(6.0, 14.0);

    return SizedBox(
      height: 130,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ServiceTagRow(serviceTagAsync: serviceTagAsync),
                  const SizedBox(height: 10),
                  Expanded(child: _BatteryStatusRow(homeData: homeData)),
                ],
              ),
            ),
          ),
          SizedBox(width: spacing),
          BatteryCostWidget(
            batteryPercent: batteryPercent,
            onTap: () => BatteryCostModal.show(context, batteryPercent),
          ),
        ],
      ),
    );
  }
}

class _ServiceTagRow extends StatelessWidget {
  const _ServiceTagRow({required this.serviceTagAsync});

  final AsyncValue<String?> serviceTagAsync;

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

class _BatteryStatusRow extends StatelessWidget {
  const _BatteryStatusRow({required this.homeData});

  final HomeData? homeData;

  @override
  Widget build(BuildContext context) {
    final batteryLevel = homeData?.mountBatteryPercentage;
    final bool hasBatteryData = batteryLevel != null;
    final int? batteryPercent = batteryLevel?.toInt();
    final w = MediaQuery.of(context).size.width;
    final spacing = (w * 0.03).clamp(6.0, 14.0);
    final iconSize = (w * 0.14).clamp(40.0, 56.0);

    return Row(
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
    );
  }
}

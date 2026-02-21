import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';
import 'package:lakbyke_mobile/core/formatting/formatting.dart';
import 'package:lakbyke_mobile/features/home/domain/models/home_data.dart';
import 'package:lakbyke_mobile/features/home/presentation/components/action_button.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/app_router_controller.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/shell_navigator_key.dart';
import 'package:lakbyke_mobile/app/presentation/shell_routes.dart';

/// Green container with Total Generated, Total Redeems, and Batteries Exchanged.
class HomeActionButtons extends ConsumerWidget {
  const HomeActionButtons({super.key, this.homeData});

  final HomeData? homeData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double buttonWidth = (MediaQuery.of(context).size.width - 40 - 40 - 20) / 2;

    final totalGenerated = homeData?.totalGenerated ?? 0.0;
    final totalRedeems = homeData?.totalRedeems ?? 0.0;
    final batteriesExchanged = homeData?.batteriesExchanged ?? 0;

    final hasNoData = homeData != null && totalGenerated == 0.0 && totalRedeems == 0.0 && batteriesExchanged == 0;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF317263),
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
                title: 'Total \n Redeems',
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

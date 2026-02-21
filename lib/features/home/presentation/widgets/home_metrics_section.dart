import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/formatting/formatting.dart';
import 'package:lakbyke_mobile/features/home/domain/models/home_data.dart';
import 'package:lakbyke_mobile/features/home/presentation/components/metric_item.dart';

/// Section title row ("metrics") and today's distance, effort, generated metrics.
class HomeMetricsSection extends StatelessWidget {
  const HomeMetricsSection({super.key, this.homeData});

  final HomeData? homeData;

  @override
  Widget build(BuildContext context) {
    final distance = homeData?.todayDistance ?? 0.0;
    final generated = homeData?.todayWh ?? 0.0;
    final effort = (homeData?.isEffortStale ?? true) ? 0.0 : (homeData?.liveEffort ?? 0.0);
    final isStale = homeData?.isEffortStale ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                'metrics',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF317263),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
          ],
        ),
        Padding(
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
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lakbyke_mobile/shared/widgets/header.dart';
import 'package:lakbyke_mobile/shared/widgets/screen_title.dart';
import 'package:lakbyke_mobile/features/insights/providers/insights_providers.dart';
import 'package:lakbyke_mobile/core/utils/colors.dart';
import 'package:lakbyke_mobile/core/utils/dimensions.dart';
import 'package:lakbyke_mobile/shared/widgets/index.dart';
import 'package:lakbyke_mobile/features/insights/presentation/widgets/insights_widgets.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  void _setupErrorSnackbarListener() {
    ref.listen(insightsDataProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load insights: ${e.toString()}'),
              backgroundColor: AppColors.error,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () =>
                    ref.read(insightsDataProvider.notifier).refresh(),
              ),
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _setupErrorSnackbarListener();
    final asyncInsights = ref.watch(insightsDataProvider);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(color: Colors.black),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: kHeaderContentTopPadding),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: asyncInsights.when(
                    data: (model) {
                      final size = MediaQuery.sizeOf(context);
                      final layout = InsightsLayout(size);
                      return RefreshIndicator(
                        onRefresh: () =>
                            ref.read(insightsDataProvider.notifier).refresh(),
                        color: AppColors.homePrimary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const ScreenTitle(title: 'INSIGHTS'),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  (size.width * 0.04).clamp(12.0, 20.0),
                                  AppDimensions.paddingLarge,
                                  (size.width * 0.04).clamp(12.0, 20.0),
                                  (size.width * 0.08).clamp(24.0, 40.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InvestmentRecoveryCard(
                                        model: model, layout: layout),
                                    const SizedBox(
                                        height: AppDimensions.paddingLarge),
                                    ForecasterCard(
                                        model: model, layout: layout),
                                    const SizedBox(
                                        height: AppDimensions.paddingLarge),
                                    UnitHealthCard(
                                        model: model, layout: layout),
                                    const SizedBox(
                                        height: AppDimensions.paddingLarge),
                                    RiderPersonaCard(
                                        model: model, layout: layout),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const AppLoadingOverlay(
                        message: 'Loading your insights...'),
                    error: (e, _) => _buildErrorBody(context, e),
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

  Widget _buildErrorBody(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Could not load insights',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(insightsDataProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

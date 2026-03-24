import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/index.dart';
import 'package:lakbyke_mobile/features/home/presentation/screens/welcome_modal.dart';
import 'package:lakbyke_mobile/features/home/providers/home_providers.dart';
import 'package:lakbyke_mobile/features/home/presentation/widgets/home_battery_section.dart';
import 'package:lakbyke_mobile/features/home/presentation/widgets/home_metrics_section.dart';
import 'package:lakbyke_mobile/features/home/presentation/widgets/home_action_buttons.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeModal();
    });
  }

  Future<void> _showWelcomeModal() async {
    if (_welcomeModalShown) return;
    
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    
    try {
      final monthData = await ref.read(currentMonthDataProvider.future);
      final monthDistance = monthData['monthDistance'] as double? ?? 0.0;
      final monthWh = monthData['monthWh'] as double? ?? 0.0;
      
      if (mounted) {
        _welcomeModalShown = true;
        WelcomeModal.show(
          context,
          monthDistance: monthDistance,
          monthWh: monthWh,
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
                                  HomeBatterySection(
                                    homeData: homeData,
                                    serviceTagAsync: serviceTagAsync,
                                  ),
                                  const SizedBox(height: 15),
                                  HomeMetricsSection(homeData: homeData),
                                  const Divider(color: Colors.grey, thickness: 0.5),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              child: HomeActionButtons(homeData: homeData),
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
}


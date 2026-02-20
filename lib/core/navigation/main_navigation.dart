import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:lakbyke_mobile/features/maps/presentation/screens/maps_screen.dart';
import 'package:lakbyke_mobile/features/qr/presentation/screens/qr_scanner_screen.dart';
import 'package:lakbyke_mobile/features/insights/presentation/screens/insights_screen.dart';
import 'package:lakbyke_mobile/features/history/presentation/screens/combined_history_screen.dart';

/// Tab bar + FAB shell. State is driven by [initialIndex] and [initialHistoryTabIndex];
/// [onTabTapped] and [onHistoryTabChanged] must be called to update external state.
class MainNavigation extends StatelessWidget {
  const MainNavigation({
    super.key,
    required this.initialIndex,
    required this.initialHistoryTabIndex,
    required this.onTabTapped,
    required this.onHistoryTabChanged,
    this.slideDirection = 0.0,
  });

  final int initialIndex;
  final int initialHistoryTabIndex;
  final ValueChanged<int> onTabTapped;
  final ValueChanged<int> onHistoryTabChanged;
  final double slideDirection;

  static const int historyMainIndex = 4;
  static const int historyTabCount = 2;

  @override
  Widget build(BuildContext context) {
    return _MainNavigationContent(
      initialIndex: initialIndex,
      initialHistoryTabIndex: initialHistoryTabIndex,
      slideDirection: slideDirection,
      onTabTapped: onTabTapped,
      onHistoryTabChanged: onHistoryTabChanged,
    );
  }
}

class _MainNavigationContent extends StatelessWidget {
  const _MainNavigationContent({
    required this.initialIndex,
    required this.initialHistoryTabIndex,
    required this.slideDirection,
    required this.onTabTapped,
    required this.onHistoryTabChanged,
  });

  final int initialIndex;
  final int initialHistoryTabIndex;
  final double slideDirection;
  final ValueChanged<int> onTabTapped;
  final ValueChanged<int> onHistoryTabChanged;

  static const Color _activeColor = Color(0xFF317263);
  static const Color _accentColor = Color(0xFF70D2C8);

  List<Widget> _screens(int currentIndex) => [
    const HomeScreen(),
    MapsScreen(isActive: currentIndex == 1),
    QrScannerScreen(isActive: currentIndex == 2),
    const InsightsScreen(),
    CombinedHistoryScreen(
      initialTabIndex: initialHistoryTabIndex,
      onTabChanged: onHistoryTabChanged,
    ),
  ];

  void _onSwipeLeft() {
    if (initialIndex == MainNavigation.historyMainIndex) {
      if (initialHistoryTabIndex < MainNavigation.historyTabCount - 1) {
        onHistoryTabChanged(initialHistoryTabIndex + 1);
      }
    } else if (initialIndex < 4) {
      onTabTapped(initialIndex + 1);
    }
  }

  void _onSwipeRight() {
    if (initialIndex == MainNavigation.historyMainIndex) {
      if (initialHistoryTabIndex > 0) {
        onHistoryTabChanged(initialHistoryTabIndex - 1);
      } else {
        onTabTapped(initialIndex - 1);
      }
    } else if (initialIndex > 0) {
      onTabTapped(initialIndex - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          const threshold = 40.0;
          if (velocity < -threshold) {
            _onSwipeLeft();
          } else if (velocity > threshold) _onSwipeRight();
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(slideDirection * 0.2, 0),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: IndexedStack(
            key: ValueKey<int>(initialIndex),
            index: initialIndex,
            children: _screens(initialIndex),
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          onPressed: () => onTabTapped(2),
          elevation: 4,
          backgroundColor: initialIndex == 2 ? _accentColor : Colors.black,
          shape: CircleBorder(
            side: BorderSide(
              color: _accentColor,
              width: initialIndex == 2 ? 4 : 2,
            ),
          ),
          child: Icon(
            Icons.qr_code_scanner,
            size: 32,
            color: initialIndex == 2 ? Colors.black : _accentColor,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildModernNavBar(),
    );
  }

  Widget _buildModernNavBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10.0,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.2),
      height: 80,
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavPill(icon: Icons.directions_bike, label: 'Home', index: 0),
            _buildNavPill(icon: Icons.map_outlined, label: 'Maps', index: 1),
            const SizedBox(width: 40),
            _buildNavPill(icon: Icons.trending_up, label: 'Insights', index: 3),
            _buildNavPill(icon: Icons.history, label: 'History', index: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavPill({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = initialIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTabTapped(index),
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 20.0 : 0.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: isActive ? _activeColor.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: isActive ? _activeColor : Colors.grey.shade500,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? _activeColor : Colors.grey.shade500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

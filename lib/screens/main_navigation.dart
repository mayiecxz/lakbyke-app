import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/screens/home/home_screen.dart';
import 'package:lakbyke_mobile/screens/maps/maps_screen.dart';
import 'package:lakbyke_mobile/screens/qr/qr_scanner_screen.dart';
import 'package:lakbyke_mobile/screens/insights/insights_screen.dart';
import 'package:lakbyke_mobile/screens/history/combined_history_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainNavigation> createState() => _MainNavigationState();

  // Static method to find and navigate from child widgets
  static void navigateToHistoryFromContext(BuildContext context, {int initialTabIndex = 0}) {
    final state = context.findAncestorStateOfType<_MainNavigationState>();
    state?.navigateToHistory(initialTabIndex: initialTabIndex);
  }
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  double _slideDirection = 0.0; // Track slide direction for animations

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // Store history tab index to pass to CombinedHistoryScreen
  int _historyInitialTabIndex = 0;
  
  // Screens: QR scanner receives isActive so camera is only used when that tab is selected
  List<Widget> get _screens => [
    const HomeScreen(),
    const MapsScreen(),
    QrScannerScreen(isActive: _currentIndex == 2),
    const InsightsScreen(),
    CombinedHistoryScreen(initialTabIndex: _historyInitialTabIndex),
  ];

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      // Calculate slide direction before updating state
      _slideDirection = index > _currentIndex ? 1.0 : -1.0;
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // Method to navigate to history with specific tab index
  void navigateToHistory({int initialTabIndex = 0}) {
    _historyInitialTabIndex = initialTabIndex;
    _onTabTapped(4); // History is at index 4
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150), // Reduced from 300ms
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          // Simplified slide transition - faster
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(_slideDirection, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        child: IndexedStack(
          key: ValueKey<int>(_currentIndex),
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final bottomPadding = mediaQuery.padding.bottom;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.only(
          left: screenWidth * 0.01,
          right: screenWidth * 0.01,
          top: screenHeight * 0.008,
          bottom: bottomPadding > 0 ? bottomPadding : 1, // Align to bottom, prevent overflow
        ),
        constraints: BoxConstraints(
          minHeight: 84,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.directions_bike,
              label: 'Home',
              index: 0,
              isActive: _currentIndex == 0,
            ),
            _buildNavItem(
              icon: Icons.map,
              label: 'Maps',
              index: 1,
              isActive: _currentIndex == 1,
            ),
            _buildQrButton(),
            _buildNavItem(
              icon: Icons.trending_up,
              label: 'Insights',
              index: 3,
              isActive: _currentIndex == 3,
            ),
            _buildNavItem(
              icon: Icons.history,
              label: 'History',
              index: 4,
              isActive: _currentIndex == 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Responsive sizing based on screen dimensions
    final iconSize = isActive 
        ? (screenWidth * 0.06).clamp(26.0, 32.0) // Larger when active
        : (screenWidth * 0.055).clamp(22.0, 26.0);
    final fontSize = (screenWidth * 0.028).clamp(9.0, 12.0);
    final containerPadding = EdgeInsets.symmetric(
      horizontal: screenWidth * 0.02,
      vertical: screenHeight * 0.008,
    );
    
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100), // Reduced from 250ms
        curve: Curves.easeOut,
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
        padding: containerPadding,
        decoration: BoxDecoration(
          color: isActive 
              ? const Color(0xFF317263) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(
                  color: const Color(0xFF317263),
                  width: 2,
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onTabTapped(index),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : Colors.grey,
                  size: iconSize,
                ),
                SizedBox(height: screenHeight * 0.004),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: isActive ? Colors.white : Colors.grey,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrButton() {
    final isActive = _currentIndex == 2;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // Larger responsive sizing for QR button
    final buttonSize = (screenWidth * 0.18).clamp(70.0, 85.0);
    final iconSize = (screenWidth * 0.09).clamp(36.0, 44.0);
    
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: Offset(0, -(screenHeight * 0.015)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100), // Reduced from 250ms
              curve: Curves.easeOut,
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: isActive 
                    ? const Color(0xFF70D2C8) 
                    : const Color(0xFF70D2C8).withOpacity(0.9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.8),
                  width: isActive ? 4 : 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isActive 
                        ? const Color(0xFF70D2C8).withOpacity(0.4)
                        : Colors.black.withOpacity(0.25),
                    blurRadius: isActive ? 16 : 12,
                    offset: Offset(0, isActive ? 8 : 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onTabTapped(2),
                  borderRadius: BorderRadius.circular(buttonSize / 2),
                  child: Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

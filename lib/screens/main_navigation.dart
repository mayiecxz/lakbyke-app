import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/screens/dashboard/dashboard_screen.dart';
import 'package:lakbyke_mobile/screens/maps/maps_screen.dart';
import 'package:lakbyke_mobile/screens/qr/qr_scanner_screen.dart';
import 'package:lakbyke_mobile/screens/prediction/prediction_screen.dart';
import 'package:lakbyke_mobile/screens/history/combined_history_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MapsScreen(),
    const QrScannerScreen(),
    const PredictionScreen(),
    const CombinedHistoryScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
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
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.directions_bike,
                label: 'Dashboard',
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
                label: 'Prediction',
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
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF317263) : Colors.grey,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? const Color(0xFF317263) : Colors.grey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrButton() {
    final isActive = _currentIndex == 2;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, -12), // Elevate the button above the nav bar
            child: GestureDetector(
              onTap: () => _onTabTapped(2),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF317263),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8), // Extra space for the elevated button
          Text(
            'QR',
            style: TextStyle(
              fontSize: 10,
              color: isActive ? const Color(0xFF317263) : Colors.grey,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

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
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const MapsScreen(),
    const QrScannerScreen(),
    const InsightsScreen(),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
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
          height: 84, // Increased by 20% from 70
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.01, // Responsive horizontal padding
            vertical: screenHeight * 0.008, // Responsive vertical padding
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
      child: InkWell(
        onTap: () => _onTabTapped(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
          padding: containerPadding,
          decoration: BoxDecoration(
            color: isActive 
                ? const Color(0xFF317263).withOpacity(0.15) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(
                    color: const Color(0xFF317263),
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFF317263) : Colors.grey,
                size: iconSize,
              ),
              SizedBox(height: screenHeight * 0.004),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  color: isActive ? const Color(0xFF317263) : Colors.grey,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrButton() {
    final isActive = _currentIndex == 2;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Responsive sizing for QR button
    final buttonSize = (screenWidth * 0.14).clamp(56.0, 70.0);
    final iconSize = (screenWidth * 0.07).clamp(28.0, 36.0);
    final fontSize = (screenWidth * 0.028).clamp(9.0, 12.0);
    
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: Offset(0, -(screenHeight * 0.015)), // Responsive elevation
            child: GestureDetector(
              onTap: () => _onTabTapped(2),
              child: Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  color: isActive 
                      ? const Color(0xFF317263) 
                      : const Color(0xFF317263).withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? Colors.white : Colors.white.withOpacity(0.8),
                    width: isActive ? 4 : 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isActive 
                          ? const Color(0xFF317263).withOpacity(0.4)
                          : Colors.black.withOpacity(0.25),
                      blurRadius: isActive ? 16 : 12,
                      offset: Offset(0, isActive ? 8 : 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.01), // Responsive spacing
          Text(
            'QR',
            style: TextStyle(
              fontSize: fontSize,
              color: isActive ? const Color(0xFF317263) : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

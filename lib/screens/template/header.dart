import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/services/auth_service.dart';
import 'package:lakbyke_mobile/services/chatbot_service.dart';
import 'package:lakbyke_mobile/screens/onboarding/onboarding_screen.dart';
import 'package:lakbyke_mobile/widgets/validation_dialog.dart';
// import 'package:lakbyke_mobile/screens/account/account_settings_screen.dart'; // Temporarily hidden

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64); // Increased from 56 to 64 for extra padding

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: preferredSize.height,
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Extra top and bottom padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Spacer to balance the layout (same width as account button)
            const SizedBox(width: 48),
            // Logo (centered)
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/images/lakbike_logo4.png',
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Account button (right side)
            const _AccountButton(),
          ],
        ),
      ),
    );
  }
}

class _AccountButton extends StatefulWidget {
  const _AccountButton();

  @override
  State<_AccountButton> createState() => _AccountButtonState();
}

class _AccountButtonState extends State<_AccountButton> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100), // Reduced from 200ms
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showAccountMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset buttonPosition = button.localToGlobal(Offset.zero);
    final Size buttonSize = button.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPosition.dx + buttonSize.width - 200, // Align menu to right
        buttonPosition.dy + buttonSize.height + 8, // Below button with spacing
        overlay.size.width - buttonPosition.dx - buttonSize.width,
        overlay.size.height - buttonPosition.dy - buttonSize.height,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      items: <PopupMenuEntry<String>>[
        // Account Settings temporarily hidden - uncomment when ready
        PopupMenuItem<String>(
          value: 'logout',
          child: _AccountMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              _handleLogout(context);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    
    // Show confirmation dialog
    ValidationDialog.show(
      context,
      title: 'Confirm Logout',
      content: const Text('Are you sure you want to logout?'),
      confirmLabel: 'Logout',
      cancelLabel: 'Cancel',
      isDestructive: true,
      onConfirm: () async {
        try {
          // Delete chat history before logout
          final chatbotService = ChatbotService();
          await chatbotService.deleteChatHistory();
          
          // Sign out from auth service
          await _authService.signOut();
          
          // Navigate to onboarding and remove all previous routes
          if (navigator.mounted) {
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              (route) => false,
            );
          }
        } catch (e) {
          // Handle error silently or show a message
          if (navigator.mounted) {
            ScaffoldMessenger.of(navigator.context).showSnackBar(
              SnackBar(
                content: Text('Error during logout: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        _showAccountMenu(context);
      },
      onTapCancel: () => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.account_circle,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _AccountMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDestructive;
  final VoidCallback onTap;

  const _AccountMenuItem({
    required this.icon,
    required this.title,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.grey[700],
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.red : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

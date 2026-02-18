import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/app_router_controller.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';
import 'package:lakbyke_mobile/features/auth/presentation/screens/login/login_screen.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/index.dart';

// ============================================================================
// OnboardingScreen
// ============================================================================

/// OnboardingScreen is the entry point for unauthenticated users.
/// Displays the app branding, tagline, and action buttons (login/signup).
/// The login modal appears by default with a slide-up animation.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoginModalVisible = true;
  late final GlobalKey<_AnimatedLoginModalState> _modalKey;

  @override
  void initState() {
    super.initState();
    _modalKey = GlobalKey<_AnimatedLoginModalState>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _buildWaveBackground(),
            _buildMainContent(),
            if (_isLoginModalVisible) ..._buildLoginOverlay(),
          ],
        ),
      ),
    );
  }

  /// Builds the decorative wave-shaped background at the bottom.
  Widget _buildWaveBackground() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * AppDimensions.waveHeightRatio,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(
              MediaQuery.of(context).size.width * AppDimensions.waveCurveRatio,
            ),
            topRight: Radius.circular(
              MediaQuery.of(context).size.width * AppDimensions.waveCurveRatio,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the main content area: logo, tagline, and action buttons.
  Widget _buildMainContent() {
    return Column(
      children: [
        Expanded(
          child: _buildBrandingSection(),
        ),
        _buildActionButtons(),
      ],
    );
  }

  /// Builds the branding section with logo and tagline.
  Widget _buildBrandingSection() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogo(),
            const SizedBox(height: AppDimensions.spacingMedium),
            _buildTagline(),
          ],
        ),
      ),
    );
  }

  /// Builds the application logo.
  Widget _buildLogo() {
    return ResponsiveLogo(
      assetPath: AppAssets.logoMain,
      maxWidthPercent: 0.7,
      minWidth: 120.0,
    );
  }

  /// Builds the application tagline.
  Widget _buildTagline() {
    return Text(
      AppStrings.onboardingTagline,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
      textAlign: TextAlign.center,
    );
  }

  /// Builds the bottom action buttons (login and signup).
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingHorizontal,
      ).copyWith(
        bottom: AppDimensions.paddingBottom,
        top: AppDimensions.paddingTop,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildLoginButton(),
          ),
          const SizedBox(width: AppDimensions.spacingSmall),
          Expanded(
            child: _buildSignupButton(),
          ),
        ],
      ),
    );
  }

  /// Builds the login button (outlined style).
  Widget _buildLoginButton() {
    return OutlinedButton(
      onPressed: _showLoginModal,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primaryTeal),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.buttonPadding),
      ),
      child: Text(
        AppStrings.buttonLogin,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primaryTeal,
            ),
      ),
    );
  }

  /// Builds the signup button (filled style).
  Widget _buildSignupButton() {
    return ElevatedButton(
      onPressed: _handleSignupPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryTeal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.buttonPadding),
      ),
      child: Text(
        AppStrings.buttonSignup,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
            ),
      ),
    );
  }

  /// Builds the login modal overlay and dimmed background.
  List<Widget> _buildLoginOverlay() {
    return [
      Positioned.fill(
        child: GestureDetector(
          onTap: _handleBackgroundTap,
          child: Container(color: AppColors.overlayDim),
        ),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: _AnimatedLoginModal(
          key: _modalKey,
          onClosed: _hideLoginModal,
        ),
      ),
    ];
  }

  /// Shows the login modal.
  void _showLoginModal() {
    setState(() => _isLoginModalVisible = true);
  }

  /// Hides the login modal.
  void _hideLoginModal() {
    setState(() => _isLoginModalVisible = false);
  }

  /// Handles background tap: triggers modal dismiss animation.
  Future<void> _handleBackgroundTap() async {
    if (_modalKey.currentState != null) {
      await _modalKey.currentState!._dismiss();
    } else {
      _hideLoginModal();
    }
  }

  /// Handles signup button press. Navigate to unit QR scanner, then to signup with serviceTag.
  void _handleSignupPressed() {
    ref.read(appRouterControllerProvider.notifier).goToSignupQr();
  }
}

/// Private animated wrapper for the login modal.
/// Handles slide-up animation on show and slide-down on hide.
class _AnimatedLoginModal extends StatefulWidget {
  final VoidCallback? onClosed;

  const _AnimatedLoginModal({
    super.key,
    this.onClosed,
  });

  @override
  State<_AnimatedLoginModal> createState() => _AnimatedLoginModalState();
}

class _AnimatedLoginModalState extends State<_AnimatedLoginModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _controller.forward();
  }

  /// Initializes the slide-up animation controller.
  void _initializeAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.modalAnimationDuration,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.modalAnimationCurve,
      ),
    );
  }

  /// Dismisses the modal with reverse animation.
  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onClosed?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: LoginModal(onClose: _dismiss),
    );
  }
}

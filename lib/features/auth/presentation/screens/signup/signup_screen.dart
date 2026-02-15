import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/features/auth/providers/auth_providers.dart';
import 'package:lakbyke_mobile/features/account/data/repositories/user_repository.dart' show createUserInUserTable;
import 'package:lakbyke_mobile/core/constants/constants.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================================
// SignupScreen
// ============================================================================

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({
    super.key,
    required this.serviceTag,
  });

  /// Service tag from verified unit registration (after QR token verification).
  final String serviceTag;

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

/// Pattern: letters (A–Z, a–z), spaces, and dash (-) only.
final RegExp _namePattern = RegExp(r'^[a-zA-Z\- ]*$');

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _agreedToTerms = false;
  bool _termsError = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isSigningUp = false;
  bool _didSubmitOnce = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    setState(() => _didSubmitOnce = true);
    // 1. Form validation
    if (!_formKey.currentState!.validate()) return;

    // 2. Terms & Conditions validation
    if (!_agreedToTerms) {
      setState(() => _termsError = true);
      await _showErrorDialog(
        title: 'Terms required',
        message: AppStrings.errorTermsNotAccepted,
      );
      return;
    }
    setState(() => _termsError = false);

    if (_isSigningUp || !mounted) return;
    setState(() => _isSigningUp = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final middleName = _middleNameController.text.trim();
    final serviceTag = widget.serviceTag;

    try {
      // 3. Create Firebase Auth user
      final authService = ref.read(authServiceProvider);
      final cred = await authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;
      final user = cred.user!;

      // 4. Send email verification link to the given email
      try {
        await user.sendEmailVerification();
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSigningUp = false);
        await _showErrorDialog(
          title: 'Verification email issue',
          message: 'Account created but we could not send the verification email. '
              'Try signing in and request a new link from your account settings.',
        );
        return;
      }

      // 5. Write to Realtime Database userTable (serviceTag matches QR/token)
      await createUserInUserTable(
        uid: uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        middleName: middleName,
        serviceTag: serviceTag,
      );

      if (!mounted) return;
      setState(() => _isSigningUp = false);

      // 6. Show dialog first (before signOut), then sign out when user taps OK
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Check your email'),
            content: const Text(
              'Check your email to verify. '
              'A verification link was sent using Firebase. Once verified, log in to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  await authService.signOut();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isSigningUp = false);
      String message = 'Sign up failed. Please try again.';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered. Sign in or use a different email.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak. Use at least 8 characters with upper and lowercase letters, a number, and a special character.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      }
      await _showErrorDialog(title: 'Sign up failed', message: message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSigningUp = false);
      await _showErrorDialog(
        title: 'Sign up failed',
        message: 'Something went wrong. Please try again. If the problem continues, check your connection.',
      );
    }
  }

  Future<void> _showErrorDialog({required String title, required String message}) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // --- Validation Logic ---

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return AppStrings.errorEmptyEmail;
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return AppStrings.errorInvalidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.errorEmptyPassword;
    if (value.length < 8) return AppStrings.errorPasswordTooShort;
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return AppStrings.errorPasswordNoUppercase;
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return AppStrings.errorPasswordNoLowercase;
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return AppStrings.errorPasswordNoNumber;
    }
    if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) {
      return AppStrings.errorPasswordNoSpecial;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.errorConfirmPasswordEmpty;
    }
    if (value != _passwordController.text) {
      return AppStrings.errorConfirmPasswordMismatch;
    }
    return null;
  }

  /// First name & surname: required, letters and dash (-) only.
  String? _validateNameRequired(String? value) {
    if (value == null || value.isEmpty) return AppStrings.errorNameRequired;
    if (!_namePattern.hasMatch(value)) return AppStrings.errorNameFormat;
    return null;
  }

  /// Middle name: optional. If provided, letters, spaces, and dash (-) only.
  String? _validateMiddleName(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!_namePattern.hasMatch(value)) return AppStrings.errorNameFormat;
    return null;
  }

  Future<void> _openTermsAndConditions() async {
    final uri = Uri.parse(AppStrings.termsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // --- UI Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Service Tag: ${widget.serviceTag}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: _didSubmitOnce
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Text(
                      AppStrings.signupTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(
                          controller: _firstNameController,
                          label: AppStrings.firstNameLabel,
                          hintText: AppStrings.firstNameHint,
                          validator: _validateNameRequired,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _middleNameController,
                          label: AppStrings.middleNameLabel,
                          hintText: AppStrings.middleNameHint,
                          validator: _validateMiddleName,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _lastNameController,
                          label: AppStrings.lastNameLabel,
                          hintText: AppStrings.lastNameHint,
                          validator: _validateNameRequired,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _emailController,
                          label: AppStrings.emailLabel,
                          hintText: AppStrings.emailHint,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 20),
                        _buildPasswordField(
                          controller: _passwordController,
                          label: AppStrings.passwordLabel,
                          isVisible: _passwordVisible,
                          onVisibilityToggle: () {
                            setState(() => _passwordVisible = !_passwordVisible);
                          },
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 20),
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: AppStrings.confirmPasswordLabel,
                          isVisible: _confirmPasswordVisible,
                          onVisibilityToggle: () {
                            setState(() =>
                                _confirmPasswordVisible = !_confirmPasswordVisible);
                          },
                          validator: _validateConfirmPassword,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _agreedToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreedToTerms = value ?? false;
                                  if (_agreedToTerms) _termsError = false;
                                });
                              },
                              activeColor: AppColors.primary,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: RichText(
                                  text: TextSpan(
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.textSecondary),
                                    children: [
                                      TextSpan(text: AppStrings.termsAgreement),
                                      TextSpan(
                                        text: AppStrings.termsLink,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = _openTermsAndConditions,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_termsError) ...[
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.errorTermsNotAccepted,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSigningUp ? null : _handleSignup,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppDimensions.buttonPadding,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppDimensions.radiusRound),
                              ),
                            ),
                            child: _isSigningUp
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    AppStrings.signUpButton.toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: AppStrings.alreadyHaveAccount,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                  ),
                                  TextSpan(
                                    text: AppStrings.logIn,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? label,
    required String hintText,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surfaceDim,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    String? label,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: AppStrings.passwordHint,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surfaceDim,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: 14,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: AppColors.textSecondary,
          ),
          onPressed: onVisibilityToggle,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lakbyke_mobile/utils/constants.dart';
import 'package:lakbyke_mobile/widgets/service_tag_input.dart';

// ============================================================================
// SignupScreen
// ============================================================================

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _serviceTagController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _agreedToTerms = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _emailController.dispose();
    _serviceTagController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // UPDATED: Signup Logic with Email Verification
  Future<void> _handleSignup() async {
    // 1. Validation
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Conditions'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 2. Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 3. Create User in Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      String uid = user!.uid;

      // 4. SAVE TO REALTIME DATABASE
      DatabaseReference userRef = FirebaseDatabase.instance.ref("userTable/$uid");

      await userRef.set({
        'uid': uid,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'middleName': _middleNameController.text.trim(),
        'email': _emailController.text.trim(),
        'serviceTag': _serviceTagController.text.trim(),
        'createdAt': ServerValue.timestamp,
        'userRole': 'cyclist', 
      });

      // 5. SEND EMAIL VERIFICATION
      bool emailSent = false;
      String? emailError;
      if (!user.emailVerified) {
        try {
          await user.sendEmailVerification();
          emailSent = true;
          // Wait a moment to ensure email is queued
          await Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          emailError = 'Failed to send verification email: ${e.toString()}';
          emailSent = false;
        }
      }

      // 6. Hide Loading
      if (mounted) Navigator.pop(context);

      // 7. Show Success Dialog (user still signed in for resend functionality)
      if (mounted) {
        final userEmail = _emailController.text.trim();
        await showDialog(
          context: context,
          barrierDismissible: false, // User must click button
          builder: (BuildContext context) {
            return _EmailVerificationDialog(
              email: userEmail,
              emailSent: emailSent,
              emailError: emailError,
              onResend: () async {
                // Resend email verification (user is still signed in)
                try {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null && !currentUser.emailVerified) {
                    await currentUser.sendEmailVerification();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Verification email resent successfully! Please check your inbox.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to resend email: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              onClose: () async {
                // Sign out when closing dialog (prevent auto-login until verified)
                await FirebaseAuth.instance.signOut();
                // Close the dialog
                if (context.mounted) Navigator.of(context).pop();
                // Navigate back to Login Screen
                if (context.mounted) Navigator.of(context).pop();
              },
            );
          },
        );
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context); // Hide loading

      String errorMessage = 'Signup failed.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Hide loading
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Validation Logic (Unchanged) ---

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return AppStrings.errorEmptyEmail;
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return AppStrings.errorInvalidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.errorEmptyPassword;
    if (value.length < 6) return AppStrings.errorPasswordTooShort;
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) return 'This field is required';
    return null;
  }

  String? _validateServiceTag(String? value) {
    if (value == null || value.isEmpty) return 'Service tag is required';
    String cleaned = value.replaceAll(' ', '');
    if (cleaned.length != 7) return 'Service tag must be 7 alphanumeric characters';
    return null;
  }

  // --- UI Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title
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

                  // Fields
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(
                          controller: _firstNameController,
                          label: AppStrings.firstNameLabel,
                          hintText: AppStrings.firstNameHint,
                          validator: _validateRequired,
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: _lastNameController,
                          label: AppStrings.lastNameLabel,
                          hintText: AppStrings.lastNameHint,
                          validator: _validateRequired,
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: _middleNameController,
                          label: AppStrings.middleNameLabel,
                          hintText: AppStrings.middleNameHint,
                          validator: _validateRequired,
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

                        ServiceTagInput(
                          controller: _serviceTagController,
                          validator: _validateServiceTag,
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

                        // Terms
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _agreedToTerms,
                              onChanged: (value) {
                                setState(() => _agreedToTerms = value ?? false);
                              },
                              activeColor: AppColors.primary,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: AppStrings.termsAgreement,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: AppColors.textSecondary),
                                      ),
                                      TextSpan(
                                        text: AppStrings.termsLink,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                              decoration: TextDecoration.underline,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Signup Button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _handleSignup,
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
                            child: Text(
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

                        // Login Link
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
                                          decoration: TextDecoration.underline,
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

  // --- Helper Widgets ---

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

// Email Verification Dialog Widget
class _EmailVerificationDialog extends StatelessWidget {
  final String email;
  final bool emailSent;
  final String? emailError;
  final VoidCallback onResend;
  final VoidCallback onClose;

  const _EmailVerificationDialog({
    required this.email,
    required this.emailSent,
    this.emailError,
    required this.onResend,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            emailSent ? Icons.mark_email_read : Icons.error_outline,
            color: emailSent ? Colors.green : Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text("Verify your email"),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (emailSent) ...[
              const Text(
                "Account created successfully!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                "We have sent a verification link to:",
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Please check your email and click the link to verify your account before logging in.",
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "If you don't see the email, check your spam/junk folder.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Text(
                "Account created successfully!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                "However, there was an issue sending the verification email:",
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  emailError ?? 'Unknown error',
                  style: TextStyle(
                    color: Colors.red[900],
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Please try clicking 'Resend Email' below.",
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onResend,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh, size: 18),
              const SizedBox(width: 4),
              const Text("Resend Email"),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onClose,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
          child: const Text("OK, I'll check it"),
        ),
      ],
    );
  }
}
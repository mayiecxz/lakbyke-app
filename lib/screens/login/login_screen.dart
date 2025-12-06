import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/utils/constants.dart';
import 'package:lakbyke_mobile/screens/dashboard/dashboard_screen.dart';
import 'package:lakbyke_mobile/screens/signup/signup_screen.dart';
import 'package:lakbyke_mobile/widgets/index.dart';

/// LoginModal is a reusable, embeddable login dialog/modal widget. It does
/// not use a Scaffold (so it can appear inside other pages) and exposes a
/// [onClose] callback so parent widgets can hide the modal.
class LoginModal extends StatefulWidget {
  const LoginModal({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  State<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends State<LoginModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false; // For the "Remember Me" checkbox

  void _login() {
    if (_formKey.currentState!.validate()) {
      // 1. Keep your dummy data printing for debug/console tracking
      String email = _emailController.text;
      String password = _passwordController.text;
      
      print('Attempting login with:');
      print('Email: $email');
      print('Password: $password');
      print('Remember Me: $_rememberMe');

      // 2. Keep your temporary UI feedback (SnackBar)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.loginSuccess)),
      );

      // 3. Add the navigation command
      // Use pushReplacement to prevent the user from going back to the login page
      // by pressing the back button.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Full-width modal from bottom, matching dashboard style
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Centered title (no close button)
              Padding(
                padding: const EdgeInsets.all(AppDimensions.loginModalPadding),
                child: Center(
                  child: const Text(
                    AppStrings.loginTitle,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              
              // Form content with padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.loginModalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Email Input Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: AppStrings.emailLabel,
                        hintText: AppStrings.emailHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.formFieldRadius),
                          borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.formFieldRadius),
                          borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.formFieldRadius),
                          borderSide: const BorderSide(color: Color(0xFF70D2C8), width: 2),
                        ),
                        fillColor: Colors.grey[100],
                        filled: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.errorEmptyEmail;
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return AppStrings.errorInvalidEmail;
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),

                    // Password Input Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: AppStrings.passwordLabel,
                        hintText: AppStrings.passwordHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.formFieldRadius),
                          borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.formFieldRadius),
                          borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.formFieldRadius),
                          borderSide: const BorderSide(color: Color(0xFF70D2C8), width: 2),
                        ),
                        fillColor: Colors.grey[100],
                        filled: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.errorEmptyPassword;
                        }
                        if (value.length < 6) {
                          return AppStrings.errorPasswordTooShort;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    // Remember Me & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (bool? newValue) {
                                setState(() {
                                  _rememberMe = newValue ?? false;
                                });
                              },
                              activeColor: const Color(0xFF70D2C8),
                            ),
                            const Text('Remember Me'),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            print('Forgot Password Pressed');
                          },
                          child: const Text(
                            AppStrings.forgotPassword,
                            style: TextStyle(color: Color(0xFF70D2C8)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF70D2C8),
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          AppStrings.loginButton,
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Or Divider
                    Row(
                      children: [
                        const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            AppStrings.orDivider,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Google Login Button
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          print('Google Login Pressed');
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                          ),
                          child: Center(
                            child: ResponsiveImage(
                              assetPath: AppAssets.googleIcon,
                              maxWidthPercent: 0.15,
                              minWidth: 24.0,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Don't have an account? Sign up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            AppStrings.signUp,
                            style: TextStyle(
                              color: Color(0xFF70D2C8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

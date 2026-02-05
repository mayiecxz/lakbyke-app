import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/utils/constants.dart';
import 'package:lakbyke_mobile/screens/main_navigation.dart';
import 'package:lakbyke_mobile/screens/signup/signup_screen.dart';
import 'package:lakbyke_mobile/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

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
  final AuthService _authService = AuthService();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isSendingResetEmail = false; 

  // Updated Login Function with Email Verification Check
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Save email if remember me is checked
      await _saveRememberedEmail(_emailController.text.trim());
      
      // 1. Sign In with Firebase Auth
      User? user = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (user != null) { 
        // ---------------------------------------------------------
        // 2. NEW CHECK: Is Email Verified?
        // ---------------------------------------------------------
        if (!user.emailVerified) {
          // Failure: Email not verified
          await FirebaseAuth.instance.signOut(); // Kick them out immediately
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please verify your email address before logging in."),
                backgroundColor: Colors.orange, // Orange is good for warnings
                duration: Duration(seconds: 4),
              ),
            );
          }
          return; // Stop execution here
        }
        
        // ---------------------------------------------------------
        // 3. Continue to Database Check (Role & Existence)
        // ---------------------------------------------------------
        await _checkUserAndNavigate(user);
      } else {
        // --- FAILURE: Auth failed (Wrong email/pass) ---
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login failed. Please check your email and password."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Google Login Function - uses Firebase UID to check userTable
  Future<void> _loginWithGoogle() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);

    final result = await _authService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    switch (result) {
      case GoogleSignInSuccess(:final user):
        await _checkUserByUIDAndNavigate(user);
        break;
      case GoogleSignInCanceled():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign-in was canceled.'),
            backgroundColor: Colors.orange,
          ),
        );
        break;
      case GoogleSignInFailure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        break;
    }
  }

  // Function to check user by UID in userTable and navigate (for Google login)
  Future<void> _checkUserByUIDAndNavigate(User user) async {
    try {
      // Use Firebase UID directly to access userTable (UID is the key in userTable)
      final DatabaseReference userRef = 
          FirebaseDatabase.instance.ref("userTable/${user.uid}");
      
      final DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists) {
        // Convert the data to a Map to access fields easily
        final Map<dynamic, dynamic> userData = 
            snapshot.value as Map<dynamic, dynamic>;
        
        // CHECK ROLE: Only allow "cyclist" (using userRole field from userTable structure)
        String? role = userData['userRole'] as String?;

        if (role == 'cyclist') {
          // --- SUCCESS: UID found + Role is Cyclist ---
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.loginSuccess)),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainNavigation()),
            );
          }
        } else {
          // --- FAILURE: UID found, but WRONG role ---
          await FirebaseAuth.instance.signOut(); 
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Access Denied: Only cyclists can login here."),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // --- FAILURE: User authenticated, but NO record in database ---
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account not found in our records."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("System error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Common function to check user in database and navigate (for email/password login)
  Future<void> _checkUserAndNavigate(User user) async {
    try {
      final DatabaseReference userRef = 
          FirebaseDatabase.instance.ref("userTable/${user.uid}");
      
      final DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists) {
        // Convert the data to a Map to access fields easily
        final Map<dynamic, dynamic> userData = 
            snapshot.value as Map<dynamic, dynamic>;
        
        // CHECK ROLE: Only allow "cyclist" (using userRole field from userTable structure)
        String? role = userData['userRole'] as String?;

        if (role == 'cyclist') {
          // --- SUCCESS: Valid Credentials + Role is Cyclist ---
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.loginSuccess)),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainNavigation()),
            );
          }
        } else {
          // --- FAILURE: Correct credentials, but WRONG role ---
          await FirebaseAuth.instance.signOut(); 
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Access Denied: Only cyclists can login here."),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // --- FAILURE: User authenticated, but NO record in database ---
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account not found in our records."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("System error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  // Load remembered email from SharedPreferences
  Future<void> _loadRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberedEmail = prefs.getString('remembered_email');
      final shouldRemember = prefs.getBool('remember_me') ?? false;
      
      if (rememberedEmail != null && shouldRemember) {
        setState(() {
          _emailController.text = rememberedEmail;
          _rememberMe = true;
        });
      }
    } catch (e) {
      // Error loading preferences
    }
  }

  // Save email to SharedPreferences if remember me is checked
  Future<void> _saveRememberedEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('remembered_email', email);
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('remembered_email');
        await prefs.setBool('remember_me', false);
      }
    } catch (e) {
      // Error saving preferences
    }
  }

  // Check if email exists in database
  Future<bool> _checkEmailInDatabase(String email) async {
    try {
      final DatabaseReference userTableRef = FirebaseDatabase.instance.ref("userTable");
      final DataSnapshot snapshot = await userTableRef.get();
      
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;
        
        // Search through all users to find matching email
        for (var userEntry in users.entries) {
          final userData = userEntry.value as Map<dynamic, dynamic>?;
          if (userData != null) {
            final userEmail = userData['email'] as String?;
            if (userEmail != null && userEmail.toLowerCase() == email.toLowerCase()) {
              return true; // Email found in database
            }
          }
        }
      }
      return false; // Email not found
    } catch (e) {
      return false; // Error checking database
    }
  }

  // Forgot password functionality
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    
    // Check if email is entered
    if (email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your email address first.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Validate email format
    if (!email.contains('@') || !email.contains('.')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Check if email exists in database
    setState(() {
      _isSendingResetEmail = true;
    });

    final emailExistsInDb = await _checkEmailInDatabase(email);

    setState(() {
      _isSendingResetEmail = false;
    });

    if (!emailExistsInDb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No account found with this email address. Please sign up first.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: Color(0xFF70D2C8)),
            SizedBox(width: 8),
            Text('Reset Password'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We\'ll send a password reset link to:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF70D2C8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF70D2C8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() {
      _isSendingResetEmail = true;
    });

    final error = await _authService.sendPasswordResetEmail(email);

    if (!mounted) return;
    setState(() {
      _isSendingResetEmail = false;
    });

    if (mounted) {
      if (error == null) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to $email! Please check your inbox.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
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
              // Centered title
              const Padding(
                padding: EdgeInsets.all(AppDimensions.loginModalPadding),
                child: Center(
                  child: Text(
                    AppStrings.loginTitle,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.loginModalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Email Input
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

                    // Password Input
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
                          onPressed: _isSendingResetEmail ? null : _handleForgotPassword,
                          child: _isSendingResetEmail
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF70D2C8)),
                                  ),
                                )
                              : const Text(
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
                        onPressed: _isLoading ? null : _login, // Calls our updated logic
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF70D2C8),
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
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
                        onTap: _isGoogleLoading ? null : _loginWithGoogle,
                        child: Opacity(
                          opacity: _isGoogleLoading ? 0.6 : 1,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                            ),
                            child: Center(
                              child: _isGoogleLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF70D2C8)),
                                      ),
                                    )
                                  : Image.asset(
                                      'assets/images/google.png',
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.contain,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Sign up link
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
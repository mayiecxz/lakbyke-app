/// Centralized string constants for the entire application.
/// This makes localization and content updates easier in the future.
abstract class AppStrings {
  // Onboarding
  static const String onboardingTagline = 'Ride and power up your journey.';
  static const String buttonLogin = 'Log In?';
  static const String buttonSignup = 'Sign Up';

  // Authentication - Login
  static const String loginTitle = 'Welcome Back';
  static const String emailLabel = 'Email';
  static const String emailHint = 'email@example.com';
  static const String passwordLabel = 'Password';
  static const String passwordHint = '••••••••';
  static const String rememberMe = 'Remember Me';
  static const String forgotPassword = 'Forgot Password?';
  static const String loginButton = 'LOG IN';
  static const String orDivider = 'or';
  static const String googleLogin = 'Google Login';
  static const String noAccount = "Don't have an account? ";
  static const String signUp = 'Sign up';
  static const String signUpButton = 'Sign Up';
  static const String loginBtnText = 'Log In?';

  // Authentication - Signup
  static const String signupTitle = 'Get Started';
  static const String firstNameLabel = 'First Name';
  static const String firstNameHint = 'JUAN';
  static const String lastNameLabel = 'Last Name';
  static const String lastNameHint = 'CRUZ';
  static const String middleNameLabel = 'Middle Name (optional)';
  static const String middleNameHint = 'e.g. MARIA or leave blank';
  static const String usernameLabel = 'Username';
  static const String usernameHint = 'DELA';
  static const String serviceTagLabel = 'Service Tag';
  static const String serviceTagHint = 'M';
  static const String confirmPasswordLabel = 'Confirm Password';
  static const String termsAgreement = 'By signing up you agree to our ';
  static const String termsLink = 'Terms and Conditions';
  /// URL opened when user taps Terms and Conditions. Replace with your actual terms page.
  static const String termsUrl = 'https://www.example.com/terms';
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String logIn = 'Log in';

  // Validation Errors
  static const String errorEmptyEmail = 'Please enter your email';
  static const String errorInvalidEmail = 'Please enter a valid email';
  static const String errorEmptyPassword = 'Please enter your password';
  static const String errorPasswordTooShort = 'Password must be at least 8 characters';
  static const String errorPasswordNoUppercase = 'Password must contain at least one uppercase letter';
  static const String errorPasswordNoLowercase = 'Password must contain at least one lowercase letter';
  static const String errorPasswordNoNumber = 'Password must contain at least one number';
  static const String errorPasswordNoSpecial = 'Password must contain at least one special character';
  static const String errorConfirmPasswordEmpty = 'Please confirm your password';
  static const String errorConfirmPasswordMismatch = 'Passwords do not match';
  static const String errorNameRequired = 'This field is required';
  static const String errorNameFormat = 'Letters, spaces, and hyphen (-) only';
  static const String errorTermsNotAccepted = 'Please agree to the Terms and Conditions';

  // Success Messages
  static const String loginSuccess = 'Login successful! Navigating to Home...';

  // Home
  static const String home = 'Home';
  static const String battery = 'Battery';
  static const String distance = 'Distance';
  static const String effort = 'Effort';
  static const String generated = 'Generated';
  static const String totalGenerated = 'Total Generated';
  static const String totalRedeems = 'Total Redeems';
  static const String batteriesExchanged = '12 Batteries Exchanged';

  // Private constructor to prevent instantiation
  AppStrings._();
}

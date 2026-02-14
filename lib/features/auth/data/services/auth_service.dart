import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:lakbyke_mobile/features/chatbot/data/repositories/chatbot_repository.dart';

/// Result of Google sign-in: success with user, user canceled, or failure with message.
sealed class GoogleSignInResult {}

class GoogleSignInSuccess extends GoogleSignInResult {
  final User user;
  GoogleSignInSuccess(this.user);
}

class GoogleSignInCanceled extends GoogleSignInResult {}

class GoogleSignInFailure extends GoogleSignInResult {
  final String message;
  GoogleSignInFailure(this.message);
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;
  StreamSubscription<User?>? _authStateSubscription;
  User? _previousUser; // Track previous user state

  AuthService() {
    // Initialize GoogleSignIn with the appropriate client ID based on platform.
    // For Android: serverClientId (web client ID) is required so Firebase gets an idToken.
    // Ensure Android app SHA-1 (debug + release) is added in Firebase Console >
    // Project Settings > Your apps, and Google sign-in is enabled in Authentication.
    const String webClientId =
        '837322519755-g9o0lmbp2h6lrbf6nkli9ln2e92nlqrf.apps.googleusercontent.com';
    String? clientId;
    String? serverClientId;

    if (kIsWeb) {
      clientId = webClientId;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android: serverClientId must be the web client ID to get idToken for Firebase.
      serverClientId = webClientId;
      clientId = '837322519755-g798gc3hu4rd15p5dglbavsj9lg77alr.apps.googleusercontent.com';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      clientId = '837322519755-is4v2srtssi2ufhbddr33m7h2o5su625.apps.googleusercontent.com';
      serverClientId = webClientId;
    } else {
      // Desktop (Windows, macOS, Linux): use web client ID so sign-in is configured.
      clientId = webClientId;
      serverClientId = webClientId;
    }

    _googleSignIn = GoogleSignIn(
      clientId: clientId,
      serverClientId: serverClientId,
    );
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException {
      return null;
    } catch (_) {
      return null;
    }
  }

  // Sign in with Google. Returns Success(user), Canceled, or Failure(message).
  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // For web, use Firebase Auth's built-in Google Sign-In (avoids People API requirement)
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final UserCredential result = await _auth.signInWithPopup(googleProvider);
        return GoogleSignInSuccess(result.user!);
      } else {
        // For mobile/desktop: use google_sign_in package.
        // Sign out first so the account chooser is shown every time (user can pick a different account).
        await _googleSignIn.signOut();
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          return GoogleSignInCanceled();
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Firebase Auth requires idToken for Google credential. If null, config is wrong
        // (e.g. Android: app package must match Firebase, add SHA-1/SHA-256 in Firebase Console).
        if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
          return GoogleSignInFailure(
            'Google Sign-In configuration error. '
            'On Android: ensure app package matches Firebase and add SHA-1 in Firebase Console > Project settings > Your apps. See docs/ANDROID_GOOGLE_SIGNIN_SETUP.md',
          );
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        UserCredential result = await _auth.signInWithCredential(credential);
        return GoogleSignInSuccess(result.user!);
      }
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? e.code;
      return GoogleSignInFailure(
        msg.contains('network') || msg.contains('INTERNAL')
            ? 'Network error. Check your connection and try again.'
            : (e.message ?? 'Google sign-in failed. Please try again.'),
      );
    } catch (e) {
      final s = e.toString().toLowerCase();
      if (s.contains('cancel') || s.contains('dismissed') || s.contains('sign_in_canceled')) {
        return GoogleSignInCanceled();
      }
      return GoogleSignInFailure(
        'Google login failed. Please check your connection and try again.',
      );
    }
  }

  // Register with email and password
  Future<User?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Creates a Firebase Auth user and returns [UserCredential] for use in signup flow
  /// (e.g. send email verification, then write to userTable).
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final chatbotService = ChatbotRepository();
      await chatbotService.deleteChatHistory();
      await _auth.signOut();
      // Only sign out from google_sign_in on mobile platforms
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      // Error signing out
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Initialize auth state listener to detect session end
  void initializeAuthListener() {
    // Get initial user state
    _previousUser = _auth.currentUser;
    
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      // If previous user was logged in and current user is null, session ended
      if (_previousUser != null && user == null) {
        _handleSessionEnd();
      }
      _previousUser = user;
    });
  }

  // Handle session end
  Future<void> _handleSessionEnd() async {
    try {
      final chatbotService = ChatbotRepository();
      final userId = _previousUser?.uid;
      if (userId != null) {
        await chatbotService.deleteChatHistoryForUser(userId);
      }
    } catch (e) {
      // Error deleting chat history on session end
    }
  }

  // Dispose listener (optional cleanup)
  void disposeAuthListener() {
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
  }

  /// Change password using current password (no email/OTP). Returns null on success.
  /// Only works for email/password accounts. Use [currentUser] email + [currentPassword] to reauth, then set [newPassword].
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Not signed in.';
      final email = user.email;
      if (email == null || email.isEmpty) return 'No email linked to this account.';

      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Current password is incorrect.';
      }
      if (e.code == 'weak-password') return 'New password is too weak.';
      return e.message ?? 'Failed to change password.';
    } catch (e) {
      return 'Failed to change password. Please try again.';
    }
  }

  /// True if the current user can change password (has email/password provider).
  bool get canChangePassword {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  // Send password reset email
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No account found with this email address.';
      }
      return e.message ?? 'An error occurred. Please try again.';
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }
}

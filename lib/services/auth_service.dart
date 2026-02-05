import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
// import 'package:lakbyke_mobile/services/chatbot_service.dart'; // Commented out - chatbot disabled

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
    // For Android: also set serverClientId (web client ID) so Firebase can verify the ID token.
    // Ensure Android app SHA-1 (debug + release/upload) is added in Firebase Console >
    // Project Settings > Your apps, and Google sign-in is enabled in Authentication.
    String? clientId;
    String? serverClientId;

    if (kIsWeb) {
      // Web client ID (client_type: 3)
      clientId = '837322519755-g9o0lmbp2h6lrbf6nkli9ln2e92nlqrf.apps.googleusercontent.com';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android client ID; serverClientId = web client ID for Firebase token verification
      clientId = '837322519755-g798gc3hu4rd15p5dglbavsj9lg77alr.apps.googleusercontent.com';
      serverClientId = '837322519755-g9o0lmbp2h6lrbf6nkli9ln2e92nlqrf.apps.googleusercontent.com';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS client ID
      clientId = '837322519755-is4v2srtssi2ufhbddr33m7h2o5su625.apps.googleusercontent.com';
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
        // For mobile platforms (Android/iOS), use google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          return GoogleSignInCanceled();
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        UserCredential result = await _auth.signInWithCredential(credential);
        return GoogleSignInSuccess(result.user!);
      }
    } on FirebaseAuthException catch (e) {
      return GoogleSignInFailure(e.message ?? 'Google sign-in failed. Please try again.');
    } catch (e) {
      return GoogleSignInFailure(
        e.toString().contains('cancel') || e.toString().contains('dismissed')
            ? 'Sign-in was canceled.'
            : 'Google login failed. Please check your connection and try again.',
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

  // Sign out
  Future<void> signOut() async {
    try {
      // Delete chat history before signing out
      // final chatbotService = ChatbotService(); // Commented out - chatbot disabled
      // await chatbotService.deleteChatHistory();
      
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
      // final chatbotService = ChatbotService(); // Commented out - chatbot disabled
      // Use the previous user ID before it's cleared
      // final userId = _previousUser?.uid;
      // if (userId != null) {
      //   // Delete chat history for the user whose session ended
      //   await chatbotService.deleteChatHistoryForUser(userId);
      // }
    } catch (e) {
      // Error deleting chat history on session end
    }
  }

  // Dispose listener (optional cleanup)
  void disposeAuthListener() {
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
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

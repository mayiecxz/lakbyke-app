import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

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

/// Repository for authentication operations.
/// Handles Firebase Auth and Google Sign-In.
class AuthRepository {
  final FirebaseAuth _auth;
  late final GoogleSignIn _googleSignIn;

  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    // Initialize GoogleSignIn with the appropriate client ID based on platform.
    const String webClientId =
        '837322519755-g9o0lmbp2h6lrbf6nkli9ln2e92nlqrf.apps.googleusercontent.com';
    String? clientId;
    String? serverClientId;

    if (kIsWeb) {
      clientId = webClientId;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      serverClientId = webClientId;
      clientId = '837322519755-g798gc3hu4rd15p5dglbavsj9lg77alr.apps.googleusercontent.com';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      clientId = '837322519755-is4v2srtssi2ufhbddr33m7h2o5su625.apps.googleusercontent.com';
      serverClientId = webClientId;
    } else {
      clientId = webClientId;
      serverClientId = webClientId;
    }

    _googleSignIn = GoogleSignIn(
      clientId: clientId,
      serverClientId: serverClientId,
    );
  }

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Sign in with Google
  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final UserCredential result = await _auth.signInWithPopup(googleProvider);
        return GoogleSignInSuccess(result.user!);
      } else {
        await _googleSignIn.signOut();
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          return GoogleSignInCanceled();
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
          return GoogleSignInFailure(
            'Google Sign-In configuration error. '
            'On Android: ensure app package matches Firebase and add SHA-1 in Firebase Console > Project settings > Your apps.',
          );
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final result = await _auth.signInWithCredential(credential);
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

  /// Register with email and password
  Future<User?> register(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Creates a Firebase Auth user and returns UserCredential for use in signup flow
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      // Error signing out
    }
  }

  /// Change password using current password
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

  /// True if the current user can change password
  bool get canChangePassword {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  /// Send password reset email
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
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

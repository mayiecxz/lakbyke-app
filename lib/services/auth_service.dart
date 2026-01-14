import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    // Initialize GoogleSignIn with the appropriate client ID based on platform
    String? clientId;
    
    if (kIsWeb) {
      // Web client ID (client_type: 3)
      clientId = '837322519755-g9o0lmbp2h6lrbf6nkli9ln2e92nlqrf.apps.googleusercontent.com';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android client ID
      clientId = '837322519755-g798gc3hu4rd15p5dglbavsj9lg77alr.apps.googleusercontent.com';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS client ID
      clientId = '837322519755-is4v2srtssi2ufhbddr33m7h2o5su625.apps.googleusercontent.com';
    }
    
    _googleSignIn = GoogleSignIn(
      clientId: clientId,
    );
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('General Error signing in: $e');
      return null;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // For web, use Firebase Auth's built-in Google Sign-In (avoids People API requirement)
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        
        // Sign in with popup - this doesn't require People API
        final UserCredential result = await _auth.signInWithPopup(googleProvider);
        return result.user;
      } else {
        // For mobile platforms (Android/iOS), use google_sign_in package
        // Trigger the authentication flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) {
          // User canceled the sign-in
          return null;
        }

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        UserCredential result = await _auth.signInWithCredential(credential);
        return result.user;
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('General Error signing in with Google: $e');
      return null;
    }
  }

  // Register with email and password
  Future<User?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('General Error registering: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Only sign out from google_sign_in on mobile platforms
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}

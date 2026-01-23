import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
// import 'package:lakbyke_mobile/services/chatbot_service.dart'; // Commented out - chatbot disabled

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;
  StreamSubscription<User?>? _authStateSubscription;
  User? _previousUser; // Track previous user state

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
    } on FirebaseAuthException {
      return null;
    } catch (_) {
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
    } on FirebaseAuthException {
      return null;
    } catch (_) {
      return null;
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
}

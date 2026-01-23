import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Get user data from userTable
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return null;

      final snapshot = await _database.child('userTable/$userId').get();
      
      if (snapshot.exists) {
        final data = snapshot.value;
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user email in Firebase Auth and Realtime Database
  // Note: This requires the user to be re-authenticated first
  Future<bool> updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Use verifyBeforeUpdateEmail which sends a verification email
      // The email will be updated after the user clicks the verification link
      await user.verifyBeforeUpdateEmail(newEmail);

      // Update email in Realtime Database immediately (or wait for verification)
      // For now, we'll update it after verification
      final userId = getCurrentUserId();
      if (userId != null) {
        await _database.child('userTable/$userId/email').set(newEmail);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Update user password in Firebase Auth
  // Note: This requires the user to be re-authenticated first
  Future<bool> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Note: updatePassword requires recent authentication
      // In production, re-authenticate the user first using:
      // AuthCredential credential = EmailAuthProvider.credential(
      //   email: user.email!,
      //   password: currentPassword,
      // );
      // await user.reauthenticateWithCredential(credential);
      // Then call updatePassword
      await user.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      if (e.code == 'requires-recent-login') {
        // User needs to re-authenticate
        return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Send OTP to email for verification
  Future<bool> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await user.sendEmailVerification();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Send password reset email (for OTP verification)
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Verify OTP code (using email link verification or custom implementation)
  // Note: Firebase Auth doesn't have built-in OTP verification for email changes
  // We'll use email verification links or implement a custom OTP system
  Future<bool> verifyEmailOTP(String email, String code) async {
    // This is a placeholder - in production, you'd implement a custom OTP system
    // or use Firebase's email verification links
    // For now, we'll use email verification links
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await user.reload();
      return user.emailVerified;
    } catch (e) {
      return false;
    }
  }
}

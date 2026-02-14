import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakbyke_mobile/features/account/domain/models/user_model.dart';
import 'package:lakbyke_mobile/features/auth/data/services/otp_service.dart';

/// Creates a user document in Realtime Database userTable (e.g. after signup with verified serviceTag).
Future<void> createUserInUserTable({
  required String uid,
  required String email,
  required String firstName,
  required String lastName,
  required String middleName,
  required String serviceTag,
}) async {
  final ref = FirebaseDatabase.instance.ref('userTable/$uid');
  await ref.set({
    'uid': uid,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'middleName': middleName,
    'serviceTag': serviceTag,
    'role': 'cyclist',
    'userRole': 'cyclist',
    'accountStatus': 'active',
  });
  // createdAt is set on first login when email is verified (see login_screen).
}

class UserRepository {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OTPService _otpService = OTPService();

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Get user data from userTable and return as UserModel
  Future<UserModel?> getUserData() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return null;

      final snapshot = await _database.child('userTable/$userId').get();
      
      if (snapshot.exists) {
        final data = snapshot.value;
        if (data is Map) {
          return UserModel.fromMap(
            Map<String, dynamic>.from(data),
            userId,
          );
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get user data as Map (for backward compatibility)
  Future<Map<String, dynamic>?> getUserDataAsMap() async {
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

  // Send OTP for email change
  Future<Map<String, dynamic>> sendEmailChangeOTP(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      final currentEmail = user.email;
      if (currentEmail == null) {
        return {
          'success': false,
          'error': 'Current email not found',
        };
      }

      // Send OTP to current email for verification
      return await _otpService.sendOTP(
        email: currentEmail,
        purpose: 'changeEmail',
        newEmail: newEmail,
      );
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to send OTP: $e',
      };
    }
  }

  // Update user email after OTP verification
  Future<Map<String, dynamic>> updateEmailAfterOTP(String otpCode) async {
    try {
      // Verify OTP first
      final verificationResult = await _otpService.verifyOTP(
        otpCode: otpCode,
        purpose: 'changeEmail',
      );

      if (!verificationResult['success']) {
        return verificationResult;
      }

      final newEmail = verificationResult['newEmail'] as String?;
      if (newEmail == null) {
        return {
          'success': false,
          'error': 'New email not found in verification',
        };
      }

      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      // Update email in Firebase Auth
      await user.verifyBeforeUpdateEmail(newEmail);

      // Update email in Realtime Database
      final userId = getCurrentUserId();
      if (userId != null) {
        await _database.child('userTable/$userId/email').set(newEmail);
      }

      // Clean up OTP
      await _database.child('otpCodes/$userId/changeEmail').remove();

      return {
        'success': true,
        'message': 'Email updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to update email: $e',
      };
    }
  }

  // Send OTP for password change
  Future<Map<String, dynamic>> sendPasswordChangeOTP() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      final email = user.email;
      if (email == null) {
        return {
          'success': false,
          'error': 'Email not found',
        };
      }

      // Send OTP to email for verification
      return await _otpService.sendOTP(
        email: email,
        purpose: 'changePassword',
      );
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to send OTP: $e',
      };
    }
  }

  // Update user password after OTP verification
  Future<Map<String, dynamic>> updatePasswordAfterOTP({
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      // Verify OTP first
      final verificationResult = await _otpService.verifyOTP(
        otpCode: otpCode,
        purpose: 'changePassword',
      );

      if (!verificationResult['success']) {
        return verificationResult;
      }

      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      // Update password in Firebase Auth
      // Note: updatePassword may require recent authentication
      // If it fails with 'requires-recent-login', the user needs to re-authenticate
      await user.updatePassword(newPassword);

      // Clean up OTP
      final userId = getCurrentUserId();
      if (userId != null) {
        await _database.child('otpCodes/$userId/changePassword').remove();
      }

      return {
        'success': true,
        'message': 'Password updated successfully',
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return {
          'success': false,
          'error': 'Please re-authenticate to change your password',
        };
      }
      return {
        'success': false,
        'error': 'Failed to update password: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to update password: $e',
      };
    }
  }

  // Resend OTP for email change
  Future<Map<String, dynamic>> resendEmailChangeOTP(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      final currentEmail = user.email;
      if (currentEmail == null) {
        return {
          'success': false,
          'error': 'Current email not found',
        };
      }

      return await _otpService.resendOTP(
        email: currentEmail,
        purpose: 'changeEmail',
        newEmail: newEmail,
      );
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to resend OTP: $e',
      };
    }
  }

  // Resend OTP for password change
  Future<Map<String, dynamic>> resendPasswordChangeOTP() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      final email = user.email;
      if (email == null) {
        return {
          'success': false,
          'error': 'Email not found',
        };
      }

      return await _otpService.resendOTP(
        email: email,
        purpose: 'changePassword',
      );
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to resend OTP: $e',
      };
    }
  }

  // Verify OTP code (public method for dialog access)
  Future<Map<String, dynamic>> verifyOTP({
    required String otpCode,
    required String purpose,
  }) async {
    return await _otpService.verifyOTP(
      otpCode: otpCode,
      purpose: purpose,
    );
  }
}

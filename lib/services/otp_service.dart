import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling OTP generation, storage, and verification
/// 
/// Note: This service generates and stores OTP codes in Firebase Realtime Database.
/// To send OTP codes via email, you need to implement a backend service or
/// Firebase Cloud Function that sends emails. The OTP codes are stored with
/// expiration times for security.
class OTPService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Random _random = Random();

  // OTP expiration time in minutes
  static const int _otpExpirationMinutes = 10;

  /// Generate a 6-digit OTP code
  String _generateOTP() {
    return (100000 + _random.nextInt(900000)).toString();
  }

  /// Get current user ID
  String? _getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Send OTP code to email
  /// 
  /// This method:
  /// 1. Generates a 6-digit OTP code
  /// 2. Stores it in Firebase with expiration time
  /// 3. Returns the OTP code (in production, this would be sent via email)
  /// 
  /// IMPORTANT: In production, you need to implement email sending via:
  /// - Firebase Cloud Functions
  /// - Backend API service
  /// - Third-party email service (SendGrid, Mailgun, etc.)
  /// 
  /// The OTP code is stored at: otpCodes/{userId}/{purpose}/{otpCode}
  Future<Map<String, dynamic>> sendOTP({
    required String email,
    required String purpose, // 'changeEmail' or 'changePassword'
    String? newEmail, // For email changes
  }) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      // Generate OTP code
      final otpCode = _generateOTP();
      final expirationTime = DateTime.now()
          .add(Duration(minutes: _otpExpirationMinutes))
          .millisecondsSinceEpoch;

      // Store OTP in Firebase
      final otpData = {
        'code': otpCode,
        'email': email,
        'purpose': purpose,
        'expiresAt': expirationTime,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'verified': false,
        if (newEmail != null) 'newEmail': newEmail,
      };

      final otpPath = 'otpCodes/$userId/$purpose';
      await _database.child(otpPath).set(otpData);

      // TODO: Send OTP via email using backend service or Cloud Function
      // For now, we'll return the OTP code (in production, remove this)
      // In production, implement email sending:
      // - Call Cloud Function: sendOTPEmail(email: email, code: otpCode, purpose: purpose)
      // - Or call backend API endpoint

      return {
        'success': true,
        'otpCode': otpCode, // Remove this in production - only for testing
        'message': 'OTP code generated and stored',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to generate OTP: $e',
      };
    }
  }

  /// Verify OTP code
  Future<Map<String, dynamic>> verifyOTP({
    required String otpCode,
    required String purpose,
  }) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      final otpPath = 'otpCodes/$userId/$purpose';
      final snapshot = await _database.child(otpPath).get();

      if (!snapshot.exists) {
        return {
          'success': false,
          'error': 'OTP code not found or expired',
        };
      }

      final otpData = snapshot.value as Map<dynamic, dynamic>;
      final storedCode = otpData['code'] as String?;
      final expiresAt = otpData['expiresAt'] as int?;
      final isVerified = otpData['verified'] as bool? ?? false;

      // Check if already verified
      if (isVerified) {
        return {
          'success': false,
          'error': 'OTP code has already been used',
        };
      }

      // Check if expired
      if (expiresAt == null ||
          DateTime.now().millisecondsSinceEpoch > expiresAt) {
        // Clean up expired OTP
        await _database.child(otpPath).remove();
        return {
          'success': false,
          'error': 'OTP code has expired',
        };
      }

      // Verify code
      if (storedCode != otpCode) {
        return {
          'success': false,
          'error': 'Invalid OTP code',
        };
      }

      // Mark as verified
      await _database.child(otpPath).update({'verified': true});

      // Return OTP data for use in account updates
      return {
        'success': true,
        'email': otpData['email'] as String?,
        'newEmail': otpData['newEmail'] as String?,
        'purpose': otpData['purpose'] as String?,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to verify OTP: $e',
      };
    }
  }

  /// Resend OTP code
  Future<Map<String, dynamic>> resendOTP({
    required String email,
    required String purpose,
    String? newEmail,
  }) async {
    // Delete old OTP first
    final userId = _getCurrentUserId();
    if (userId != null) {
      try {
        await _database.child('otpCodes/$userId/$purpose').remove();
      } catch (e) {
        // Ignore errors when deleting
      }
    }

    // Generate and send new OTP
    return await sendOTP(
      email: email,
      purpose: purpose,
      newEmail: newEmail,
    );
  }

  /// Clean up expired OTP codes (can be called periodically)
  Future<void> cleanupExpiredOTPs() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) return;

      final snapshot = await _database.child('otpCodes/$userId').get();
      if (!snapshot.exists) return;

      final data = snapshot.value as Map<dynamic, dynamic>;
      final now = DateTime.now().millisecondsSinceEpoch;

      for (var entry in data.entries) {
        final purpose = entry.key as String;
        final otpData = entry.value as Map<dynamic, dynamic>;
        final expiresAt = otpData['expiresAt'] as int?;

        if (expiresAt != null && now > expiresAt) {
          await _database.child('otpCodes/$userId/$purpose').remove();
        }
      }
    } catch (e) {
      // Error cleaning up OTPs
    }
  }
}

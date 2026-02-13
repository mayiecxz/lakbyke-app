import 'dart:convert';
import 'package:http/http.dart' as http;

/// Sends OTP and other transactional emails via a backend API.
///
/// Set [API_URL] to your backend endpoint:
/// - Laravel: https://lakbyke.com/api/send-otp-email
/// - Firebase Cloud Function: https://us-central1-lakbyke-39f1f.cloudfunctions.net/sendOTPEmail
class EmailService {
  /// Backend URL for sending OTP emails. Must accept POST with
  /// { email, otpCode, purpose, newEmail? } and return { success, message? } or { success: false, error }.
  static const String API_URL = 'https://lakbyke.com/api/send-otp-email';

  /// Sends an OTP code to [email] for [purpose] (e.g. 'changeEmail', 'changePassword').
  /// [newEmail] is optional and used when purpose is 'changeEmail'.
  Future<Map<String, dynamic>> sendOTPEmail({
    required String email,
    required String otpCode,
    required String purpose,
    String? newEmail,
  }) async {
    if (API_URL == null || API_URL!.trim().isEmpty) {
      return {
        'success': false,
        'error': 'Email service not configured. Please set API_URL in EmailService.',
      };
    }

    try {
      final uri = Uri.parse(API_URL!.trim());
      final body = <String, dynamic>{
        'email': email,
        'otpCode': otpCode,
        'purpose': purpose,
        if (newEmail != null) 'newEmail': newEmail,
      };

      print('📧 Sending OTP email to: $email via $API_URL');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timed out'),
      );
      
      print('📧 Response status: ${response.statusCode}');
      print('📧 Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final success = data['success'] as bool? ?? true;
          return {
            'success': success,
            if (data.containsKey('message')) 'message': data['message'],
            if (data.containsKey('error') && !success) 'error': data['error'],
          };
        } catch (_) {
          return {'success': true, 'message': 'OTP email sent successfully'};
        }
      }

      String errorMsg = 'Failed to send OTP email';
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['error'] != null) {
          errorMsg = data['error'] as String;
        }
      } catch (_) {}

      // Handle specific status codes
      if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'Email service endpoint not found. Please configure the API endpoint.',
        };
      }

      if (response.statusCode >= 400 && response.statusCode < 500) {
        return {'success': false, 'error': errorMsg};
      }

      return {'success': false, 'error': '$errorMsg (${response.statusCode})'};
    } catch (e) {
      // Handle network errors, timeouts, etc.
      print('❌ Email service error: $e');
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socket') || 
          errorStr.contains('connection') || 
          errorStr.contains('failed host lookup') ||
          errorStr.contains('network') ||
          errorStr.contains('cors')) {
        return {
          'success': false,
          'error': 'Cannot connect to email service. Please check your internet connection and ensure the API endpoint is accessible.',
        };
      }
      if (errorStr.contains('timed out')) {
        return {
          'success': false,
          'error': 'Request timed out. The email service may be slow or unavailable.',
        };
      }
      return {
        'success': false,
        'error': 'Email service error: ${e.toString()}',
      };
    }
  }
}

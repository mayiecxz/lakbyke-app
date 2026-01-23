import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/utils/constants.dart';
import 'package:lakbyke_mobile/services/user_service.dart';

enum OTPPurpose {
  changeEmail,
  changePassword,
}

class OTPVerificationDialog extends StatefulWidget {
  final String email;
  final OTPPurpose purpose;
  final String? newEmail;

  const OTPVerificationDialog({
    super.key,
    required this.email,
    required this.purpose,
    this.newEmail,
  });

  @override
  State<OTPVerificationDialog> createState() => _OTPVerificationDialogState();
}

class _OTPVerificationDialogState extends State<OTPVerificationDialog> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final UserService _userService = UserService();
  bool _isLoading = false;
  bool _isSending = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _sendOTP();
    _startResendCountdown();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> result;
      
      if (widget.purpose == OTPPurpose.changeEmail) {
        // For email changes, send OTP to current email
        if (widget.newEmail == null) {
          throw Exception('New email is required for email change');
        }
        result = await _userService.sendEmailChangeOTP(widget.newEmail!);
      } else {
        // For password changes, send OTP to email
        result = await _userService.sendPasswordChangeOTP();
      }

      if (mounted) {
        setState(() {
          _isSending = false;
        });

        if (!result['success']) {
          setState(() {
            _errorMessage = result['error'] ?? 'Failed to send OTP. Please try again.';
          });
        } else {
          // Show OTP code in development (remove in production)
          // In production, the OTP will be sent via email through backend/Cloud Function
          if (result['otpCode'] != null) {
            // For development/testing only - remove in production
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('OTP Code (dev only): ${result['otpCode']}'),
                duration: const Duration(seconds: 5),
                backgroundColor: Colors.blue,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _errorMessage = 'Failed to send OTP: $e';
        });
      }
    }
  }

  void _startResendCountdown() {
    _resendCountdown = 60; // 60 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
        return _resendCountdown > 0;
      }
      return false;
    });
  }

  Future<void> _resendOTP() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> result;
      
      if (widget.purpose == OTPPurpose.changeEmail) {
        if (widget.newEmail == null) {
          throw Exception('New email is required for email change');
        }
        result = await _userService.resendEmailChangeOTP(widget.newEmail!);
      } else {
        result = await _userService.resendPasswordChangeOTP();
      }

      if (result['success']) {
        _startResendCountdown();
        // Show OTP code in development (remove in production)
        if (result['otpCode'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP Code (dev only): ${result['otpCode']}'),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to resend OTP. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to resend OTP: $e';
      });
    }

    if (mounted) {
      setState(() {
        _isResending = false;
      });
    }
  }

  void _onOTPChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Clear error message when user starts typing again
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyOTP() async {
    final otpCode = _otpControllers.map((c) => c.text).join();
    
    if (otpCode.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final purpose = widget.purpose == OTPPurpose.changeEmail
          ? 'changeEmail'
          : 'changePassword';

      // Verify OTP using the user service
      final verificationResult = await _userService.verifyOTP(
        otpCode: otpCode,
        purpose: purpose,
      );

      if (verificationResult['success'] == true) {
        if (mounted) {
          Navigator.of(context).pop({
            'success': true,
            'otpCode': otpCode,
            'purpose': purpose,
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = verificationResult['error'] ?? 'Invalid OTP code. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Verification failed: $e';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Verify Your Identity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            // Instructions
            Text(
              widget.purpose == OTPPurpose.changeEmail
                  ? 'We\'ve sent a 6-digit OTP code to ${widget.email}. Please check your email and enter the code below to verify your identity.'
                  : 'We\'ve sent a 6-digit OTP code to ${widget.email}. Please check your email and enter the code below to verify your identity before changing your password.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),

            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 45,
                  height: 55,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        borderSide: BorderSide(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        borderSide: BorderSide(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceDim,
                    ),
                    onChanged: (value) => _onOTPChanged(index, value),
                  ),
                ),
              ),
            ),

            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: AppDimensions.paddingSmall),
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppDimensions.paddingLarge),

            // Resend OTP
            Center(
              child: TextButton(
                onPressed: _resendCountdown > 0 || _isResending ? null : _resendOTP,
                child: _isResending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _resendCountdown > 0
                            ? 'Resend code in ${_resendCountdown}s'
                            : 'Resend code',
                        style: TextStyle(
                          color: _resendCountdown > 0
                              ? AppColors.textTertiary
                              : AppColors.primary,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: AppDimensions.paddingMedium),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Verify'),
                  ),
              ],
            ),

            // Loading indicator for sending
            if (_isSending)
              const Padding(
                padding: EdgeInsets.only(top: AppDimensions.paddingMedium),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

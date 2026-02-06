import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:lakbyke_mobile/services/unit_registration_service.dart';
import 'package:lakbyke_mobile/screens/signup/signup_screen.dart';

/// QR scanner screen for signup. Scanned QR contains a token; the token is verified
/// against Firebase `unitRegistration`. On success, navigates to [SignupScreen]
/// with the [serviceTag] shown at the top.
class SignupQrScreen extends StatefulWidget {
  const SignupQrScreen({super.key, this.isActive = true});

  /// When false, the camera is not started and a placeholder is shown.
  final bool isActive;

  @override
  State<SignupQrScreen> createState() => _SignupQrScreenState();
}

class _SignupQrScreenState extends State<SignupQrScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    autoStart: false,
  );

  bool _hasNavigated = false;
  bool _isVerifying = false;
  bool _isScanning = true;
  bool _hasScanned = false;
  bool _isCameraReady = false;
  /// Service tags that have already been used this session (block re-scan of same token).
  final Set<String> _usedServiceTags = {};

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestPermissionAndStart());
    }
  }

  @override
  void didUpdateWidget(covariant SignupQrScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;
    if (widget.isActive) {
      setState(() => _isCameraReady = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestPermissionAndStart());
    } else {
      _controller.stop();
      setState(() => _isCameraReady = false);
    }
  }

  Future<void> _requestPermissionAndStart() async {
    if (!mounted) return;
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      _controller.start();
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } else {
      if (mounted) {
        await _showErrorDialog(
          title: 'Camera required',
          message: 'Camera permission is needed to scan QR codes. Please enable it in settings.',
        );
      }
    }
  }

  Future<void> _showErrorDialog({required String title, required String message}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetAndResumeScanner() {
    setState(() {
      _isVerifying = false;
      _hasScanned = false;
      _isScanning = true;
    });
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture barcodeCapture) async {
    if (!_isScanning || _hasScanned || _hasNavigated || _isVerifying) return;

    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final rawValue = barcode.rawValue ?? barcode.displayValue ?? '';
    if (rawValue.isEmpty) return;

    final String token = rawValue.trim();
    log('QR scanned token: $token');

    setState(() {
      _hasScanned = true;
      _isScanning = false;
      _isVerifying = true;
    });
    _controller.stop();

    try {
      final result = await UnitRegistrationService.instance
          .verifyTokenAndGetServiceTag(token);

      if (!mounted) return;

      switch (result) {
        case VerifyTokenSuccess(:final serviceTag):
          if (_usedServiceTags.contains(serviceTag)) {
            _resetAndResumeScanner();
            await _showErrorDialog(
              title: 'Token already used',
              message: 'This unit has already been used in this session. Please scan a different unit QR code, or go back and continue with the signup form you opened.',
            );
            break;
          }
          _usedServiceTags.add(serviceTag);
          _hasNavigated = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => SignupScreen(serviceTag: serviceTag),
            ),
          );
          break;
        case VerifyTokenInvalidFormat():
          _resetAndResumeScanner();
          await _showErrorDialog(
            title: 'Invalid code',
            message: 'Please scan a valid unit token. The code should be in UUID format (e.g. e4eb7820-ca33-4690-b258-a6a68eea3422).',
          );
          break;
        case VerifyTokenNotFound():
          _resetAndResumeScanner();
          await _showErrorDialog(
            title: 'Token not found',
            message: 'No registration was found for this token. Please scan a valid unit QR code that was provided for cyclist signup.',
          );
          break;
        case VerifyTokenInvalidUnit():
          _resetAndResumeScanner();
          await _showErrorDialog(
            title: 'Unit not valid for signup',
            message: 'This unit is not registered for cyclist signup. The unit\'s service tag must start with MNT. Please use a valid unit QR code.',
          );
          break;
        case VerifyTokenAlreadyUsed():
          _resetAndResumeScanner();
          await _showErrorDialog(
            title: 'Token already used',
            message: 'This unit has already been used to create an account. Please sign in if you have an account, or use a different unit QR code.',
          );
          break;
      }
    } catch (e, st) {
      log('Verify token error', error: e, stackTrace: st);
      if (!mounted) return;
      _resetAndResumeScanner();
      await _showErrorDialog(
        title: 'Verification failed',
        message: 'Something went wrong while verifying the code. Please try again. If the problem continues, check your connection.',
      );
    }
  }

  void _toggleFlash() {
    _controller.toggleTorch();
  }

  void _switchCamera() {
    _controller.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final padding = mediaQuery.padding;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(color: Colors.black),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(color: Colors.white),
                child: widget.isActive
                    ? _buildScannerContent(padding)
                    : _buildPlaceholder(),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: const Text(
                  'Scan Unit QR',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Tap the QR button below to open the scanner',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScannerContent(EdgeInsets padding) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final shorterSide = w < h ? w : h;
        final cutOutSize = shorterSide * 0.78;
        final borderLength = (w * 0.08).clamp(25.0, 40.0);
        final borderWidth = (w * 0.01).clamp(3.0, 5.0);
        final borderRadius = (w * 0.04).clamp(12.0, 20.0);
        final instructionPadding = EdgeInsets.symmetric(
          horizontal: (w * 0.05).clamp(16.0, 24.0),
          vertical: (h * 0.012).clamp(8.0, 14.0),
        );
        final instructionMargin = EdgeInsets.symmetric(horizontal: (w * 0.05).clamp(16.0, 24.0));
        final instructionBorderRadius = (w * 0.03).clamp(10.0, 14.0);
        final iconSize = (w * 0.065).clamp(22.0, 30.0);
        final titleFontSize = (w * 0.036).clamp(12.0, 16.0);
        final subtitleFontSize = (w * 0.028).clamp(10.0, 12.0);

        if (!_isCameraReady) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF317263)),
                const SizedBox(height: 16),
                Text(
                  'Starting camera...',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ],
            ),
          );
        }

        if (_isVerifying) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF317263)),
                const SizedBox(height: 16),
                Text(
                  'Verifying token...',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: MobileScanner(
                controller: _controller,
                onDetect: _handleBarcode,
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                child: Container(
                  decoration: ShapeDecoration(
                    shape: _SignupQrOverlayShape(
                      borderColor: const Color(0xFF317263),
                      borderRadius: borderRadius,
                      borderLength: borderLength,
                      borderWidth: borderWidth,
                      cutOutSize: cutOutSize,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: (padding.top * 0.3).clamp(4.0, 16.0) + kToolbarHeight,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.flash_on, color: Colors.white),
                    onPressed: _toggleFlash,
                    tooltip: 'Toggle Flash',
                  ),
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                    onPressed: _switchCamera,
                    tooltip: 'Switch Camera',
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                margin: instructionMargin,
                padding: instructionPadding.copyWith(
                  bottom: instructionPadding.bottom + padding.bottom.clamp(0.0, 24.0),
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(instructionBorderRadius),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.white, size: iconSize),
                    SizedBox(height: (h * 0.006).clamp(4.0, 8.0)),
                    Text(
                      _hasScanned ? 'Verifying...' : 'Position QR code within the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!_hasScanned) ...[
                      SizedBox(height: (h * 0.003).clamp(2.0, 4.0)),
                      Text(
                        'The token will be verified and you will go to signup.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: subtitleFontSize,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom overlay shape for signup QR scanner
class _SignupQrOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const _SignupQrOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect r) {
      return Path()
        ..moveTo(r.left, r.bottom)
        ..lineTo(r.left, r.top + borderRadius)
        ..quadraticBezierTo(r.left, r.top, r.left + borderRadius, r.top)
        ..lineTo(r.right, r.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final cutOutSizeLocal = cutOutSize < width || cutOutSize < height
        ? (width < height ? width * 0.8 : height * 0.8)
        : cutOutSize;
    final cutOutLeft = (width - cutOutSizeLocal) / 2;
    final cutOutTop = (height - cutOutSizeLocal) / 2;
    final cutOutRight = cutOutLeft + cutOutSizeLocal;
    final cutOutBottom = cutOutTop + cutOutSizeLocal;

    final backgroundPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, width, height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(cutOutLeft, cutOutTop, cutOutRight, cutOutBottom),
          Radius.circular(borderRadius),
        ),
      );

    canvas.drawPath(backgroundPath, Paint()..color = overlayColor);

    final borderPath = Path()
      ..moveTo(cutOutLeft + borderRadius, cutOutTop)
      ..lineTo(cutOutLeft + borderLength, cutOutTop)
      ..moveTo(cutOutLeft, cutOutTop + borderRadius)
      ..lineTo(cutOutLeft, cutOutTop + borderLength)
      ..moveTo(cutOutRight - borderLength, cutOutTop)
      ..lineTo(cutOutRight - borderRadius, cutOutTop)
      ..moveTo(cutOutRight, cutOutTop + borderRadius)
      ..lineTo(cutOutRight, cutOutTop + borderLength)
      ..moveTo(cutOutRight - borderRadius, cutOutBottom)
      ..lineTo(cutOutRight - borderLength, cutOutBottom)
      ..moveTo(cutOutRight, cutOutBottom - borderRadius)
      ..lineTo(cutOutRight, cutOutBottom - borderLength)
      ..moveTo(cutOutLeft + borderLength, cutOutBottom)
      ..lineTo(cutOutLeft + borderRadius, cutOutBottom)
      ..moveTo(cutOutLeft, cutOutBottom - borderRadius)
      ..lineTo(cutOutLeft, cutOutBottom - borderLength);

    canvas.drawPath(
      borderPath,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return _SignupQrOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}

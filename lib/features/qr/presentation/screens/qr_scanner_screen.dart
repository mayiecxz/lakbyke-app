import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/header.dart';
import 'package:lakbyke_mobile/features/qr/domain/models/qr_scan_result.dart';
import 'package:lakbyke_mobile/features/qr/presentation/components/qr_scan_result_dialog.dart';
import 'package:lakbyke_mobile/features/history/providers/history_providers.dart';
// import 'package:lakbyke_mobile/core/presentation/widgets/chat_fab.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key, this.isActive = true});

  /// When false, the camera is not started and a placeholder is shown (request only when QR tab is opened).
  final bool isActive;

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    autoStart: false,
  );
  
  bool _isScanning = true;
  bool _hasScanned = false;
  /// True after camera has had time to initialize (avoids blocking UI on first frame).
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestPermissionAndStart());
    }
  }

  @override
  void didUpdateWidget(covariant QrScannerScreen oldWidget) {
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

  /// Request camera permission and start scanner asynchronously so the first frame
  /// does not block the UI. Loading state is shown until camera is ready.
  Future<void> _requestPermissionAndStart() async {
    if (!mounted) return;
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      _controller.start();
      // Allow camera init to complete off the UI thread; show loading until then.
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is needed to scan QR codes.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture barcodeCapture) {
    if (!_isScanning || _hasScanned) return;

    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      final rawValue = barcode.rawValue ?? '';
      if (rawValue.isNotEmpty) {
        setState(() {
          _hasScanned = true;
          _isScanning = false;
        });

        _controller.stop();

        final result = QrScanResult.fromBarcode(
          rawValue: rawValue,
          format: barcode.format.name,
        );
        _showScanResult(result);
      }
    }
  }

  void _showScanResult(QrScanResult scanResult) {
    final transactionRepo = ref.read(transactionRepositoryProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => QrScanResultDialog(
        scanResult: scanResult,
        transactionRepository: transactionRepo,
        onDismiss: () {
          Navigator.of(dialogContext).pop();
          _resetScanner();
        },
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _hasScanned = false;
      _isScanning = true;
    });
    _controller.start();
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
              child: Padding(
                padding: const EdgeInsets.only(top: kHeaderContentTopPadding),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: widget.isActive
                      ? _buildScannerContent(padding)
                      : _buildPlaceholder(),
                ),
              ),
            ),
            const Header(),
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
                    shape: QrScannerOverlayShape(
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
              top: (padding.top * 0.3).clamp(4.0, 16.0),
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
                      _hasScanned ? 'Scan Complete!' : 'Position QR code within the frame',
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
                        'The code will be scanned automatically',
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

// Custom overlay shape for QR scanner
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
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

    // Draw overlay
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

    // Draw border
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
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}

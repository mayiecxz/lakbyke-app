import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lakbyke_mobile/screens/template/header.dart';
// import 'package:lakbyke_mobile/screens/template/chat_fab.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  
  bool _isScanning = true;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    // Start scanner when screen is accessed
    // mobile_scanner will automatically request camera permission when needed
    _controller.start();
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
      final String code = barcodes.first.rawValue ?? '';
      if (code.isNotEmpty) {
        setState(() {
          _hasScanned = true;
          _isScanning = false;
        });
        
        _controller.stop();
        
        // Show result dialog
        _showScanResult(code);
      }
    }
  }

  void _showScanResult(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Color(0xFF317263)),
            SizedBox(width: 8),
            Text('QR Code Scanned'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scanned Content:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              code,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            child: const Text('Scan Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF317263),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
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
      appBar: const Header(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final shorterSide = w < h ? w : h;

          // Overlay: responsive to actual body size
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

          return Stack(
            fit: StackFit.expand,
            children: [
              // Camera fills entire body; cover so no letterboxing
              Positioned.fill(
                child: MobileScanner(
                  controller: _controller,
                  onDetect: _handleBarcode,
                  fit: BoxFit.cover,
                ),
              ),

              // Overlay with scanning area
              Positioned.fill(
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

              // Top controls
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

              // Bottom instructions: bar extends to bottom; safe area as inner padding so no white gap
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
      ),
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
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final _cutOutSize = cutOutSize < width || cutOutSize < height
        ? (width < height ? width * 0.8 : height * 0.8)
        : cutOutSize;
    final _cutOutLeft = (width - _cutOutSize) / 2;
    final _cutOutTop = (height - _cutOutSize) / 2;
    final _cutOutRight = _cutOutLeft + _cutOutSize;
    final _cutOutBottom = _cutOutTop + _cutOutSize;

    // Draw overlay
    final backgroundPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, width, height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(_cutOutLeft, _cutOutTop, _cutOutRight, _cutOutBottom),
          Radius.circular(borderRadius),
        ),
      );

    canvas.drawPath(backgroundPath, Paint()..color = overlayColor);

    // Draw border
    final borderPath = Path()
      ..moveTo(_cutOutLeft + borderRadius, _cutOutTop)
      ..lineTo(_cutOutLeft + borderLength, _cutOutTop)
      ..moveTo(_cutOutLeft, _cutOutTop + borderRadius)
      ..lineTo(_cutOutLeft, _cutOutTop + borderLength)
      ..moveTo(_cutOutRight - borderLength, _cutOutTop)
      ..lineTo(_cutOutRight - borderRadius, _cutOutTop)
      ..moveTo(_cutOutRight, _cutOutTop + borderRadius)
      ..lineTo(_cutOutRight, _cutOutTop + borderLength)
      ..moveTo(_cutOutRight - borderRadius, _cutOutBottom)
      ..lineTo(_cutOutRight - borderLength, _cutOutBottom)
      ..moveTo(_cutOutRight, _cutOutBottom - borderRadius)
      ..lineTo(_cutOutRight, _cutOutBottom - borderLength)
      ..moveTo(_cutOutLeft + borderLength, _cutOutBottom)
      ..lineTo(_cutOutLeft + borderRadius, _cutOutBottom)
      ..moveTo(_cutOutLeft, _cutOutBottom - borderRadius)
      ..lineTo(_cutOutLeft, _cutOutBottom - borderLength);

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

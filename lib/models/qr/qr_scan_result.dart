/// Result of a single QR/barcode scan for use in UI and services.
class QrScanResult {
  QrScanResult({
    required this.rawValue,
    this.format,
    DateTime? scannedAt,
  }) : _scannedAt = scannedAt ?? DateTime.now();

  final String rawValue;
  /// Barcode format label (e.g. "qrCode", "code128") when available.
  final String? format;
  final DateTime _scannedAt;
  DateTime get scannedAt => _scannedAt;

  /// Create from mobile_scanner Barcode. Pass rawValue and optional format string from the screen.
  factory QrScanResult.fromBarcode({required String rawValue, String? format}) {
    return QrScanResult(rawValue: rawValue, format: format);
  }
}

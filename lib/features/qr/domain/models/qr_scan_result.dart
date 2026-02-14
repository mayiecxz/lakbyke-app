/// Result of a single QR/barcode scan for use in UI and services.
/// When scanning a transaction QR, [rawValue] / [transactionUid] is the transaction UID.
class QrScanResult {
  QrScanResult({
    required this.rawValue,
    this.format,
    DateTime? scannedAt,
  }) : _scannedAt = scannedAt ?? DateTime.now();

  final String rawValue;
  /// For transaction QR scans, this is the transaction UID used to update the record.
  String get transactionUid => rawValue.trim();
  /// Barcode format label (e.g. "qrCode", "code128") when available.
  final String? format;
  final DateTime _scannedAt;
  DateTime get scannedAt => _scannedAt;

  /// Create from mobile_scanner Barcode. Pass rawValue and optional format string from the screen.
  factory QrScanResult.fromBarcode({required String rawValue, String? format}) {
    return QrScanResult(rawValue: rawValue, format: format);
  }
}

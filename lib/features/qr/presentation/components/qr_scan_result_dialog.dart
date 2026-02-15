import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/features/qr/domain/models/qr_scan_result.dart';
import 'package:lakbyke_mobile/features/history/data/repositories/transaction_repository.dart';

/// Dialog that updates the transaction by scanned UID and shows result.
class QrScanResultDialog extends StatefulWidget {
  const QrScanResultDialog({
    super.key,
    required this.scanResult,
    required this.transactionRepository,
    required this.onDismiss,
  });

  final QrScanResult scanResult;
  final TransactionRepository transactionRepository;
  final VoidCallback onDismiss;

  @override
  State<QrScanResultDialog> createState() => _QrScanResultDialogState();
}

class _QrScanResultDialogState extends State<QrScanResultDialog> {
  Map<String, dynamic>? _updateResult;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performUpdate();
  }

  Future<void> _performUpdate() async {
    final result = await widget.transactionRepository
        .updateTransactionForQrScan(widget.scanResult.transactionUid);
    if (!mounted) return;
    setState(() {
      _updateResult = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
            'Transaction UID:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          SelectableText(
            widget.scanResult.rawValue,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF317263),
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text('Updating transaction...'),
              ],
            )
          else if (_updateResult != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  (_updateResult!['success'] == true)
                      ? Icons.check_circle
                      : Icons.error,
                  color: (_updateResult!['success'] == true)
                      ? const Color(0xFF317263)
                      : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _updateResult!['success'] == true
                        ? (_updateResult!['message'] as String? ?? 'Transaction updated.')
                        : (_updateResult!['error'] as String? ?? 'Update failed.'),
                    style: TextStyle(
                      color: (_updateResult!['success'] == true)
                          ? const Color(0xFF317263)
                          : Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        if (!_isLoading) ...[
          TextButton(
            onPressed: widget.onDismiss,
            child: const Text('Scan Again'),
          ),
          ElevatedButton(
            onPressed: widget.onDismiss,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF317263),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ],
    );
  }
}

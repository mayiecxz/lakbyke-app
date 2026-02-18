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

  Widget _buildLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(value, style: const TextStyle(fontSize: 14)),
      ],
    );
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
            _buildLabelValue('Transaction token', widget.scanResult.rawValue),
            const SizedBox(height: 10),
            _buildLabelValue(
              'Station (STN)',
              _updateResult!['stnTag'] as String? ?? '—',
            ),
            const SizedBox(height: 10),
            _buildLabelValue(
              'Your unit (MNT)',
              _updateResult!['mntTag'] as String? ?? '—',
            ),
            if (_updateResult!['success'] == true) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF317263).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Proceed to this station to complete your battery swap or sale. This scan records your transaction for verification.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 12),
            ],
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

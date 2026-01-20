class ChatbotContextBuilder {
  static const Duration _liveEffortStaleAfter = Duration(seconds: 10);

  static String buildContextSection(Map<String, dynamic>? contextData) {
    if (contextData == null || contextData.isEmpty) return '';

    final lines = <String>[];

    _addIfPresent(lines, "Today's Energy Generated", contextData['todayWh'], suffix: 'Wh');
    _addIfPresent(lines, "Today's Distance", contextData['todayDistance'], suffix: 'km');
    _addIfPresent(lines, "Total Redeems", contextData['totalRedeems'], prefix: '₱');
    _addIfPresent(lines, "Total Generated", contextData['totalGenerated'], suffix: 'Wh');
    _addIfPresent(lines, "Batteries Exchanged", contextData['batteriesExchanged']);

    final effortLine = _buildLiveEffortLine(contextData);
    if (effortLine != null) {
      lines.add(effortLine);
    }

    final timestampLine = _buildLiveEffortTimestampLine(contextData);
    if (timestampLine != null) {
      lines.add(timestampLine);
    }

    if (lines.isEmpty) return '';
    return '\nADDITIONAL CONTEXT DATA:\n${lines.join('\n')}\n';
  }

  static String? _buildLiveEffortLine(Map<String, dynamic> contextData) {
    if (!contextData.containsKey('liveEffort')) return null;

    final rawEffort = contextData['liveEffort'];
    final effortValue = _toDouble(rawEffort);
    final isStale = _isLiveEffortStale(contextData);

    final displayValue = (isStale && effortValue != null) ? 0.0 : effortValue ?? rawEffort;
    return '- Live Effort (Current Power): $displayValue W';
  }

  static String? _buildLiveEffortTimestampLine(Map<String, dynamic> contextData) {
    if (!contextData.containsKey('liveEffortTimestamp')) return null;

    final timestamp = contextData['liveEffortTimestamp'];
    final timestampStr = _formatTimestamp(timestamp);
    if (timestampStr == null || timestampStr.isEmpty) return null;

    return '- Live Effort Timestamp: $timestampStr';
  }

  static bool _isLiveEffortStale(Map<String, dynamic> contextData) {
    final timestamp = contextData['liveEffortTimestamp'];
    final parsed = _parseTimestamp(timestamp);
    if (parsed == null) return false;
    return DateTime.now().difference(parsed) > _liveEffortStaleAfter;
  }

  static void _addIfPresent(
    List<String> lines,
    String label,
    dynamic value, {
    String? prefix,
    String? suffix,
  }) {
    if (value == null) return;
    final buffer = StringBuffer('- $label: ');
    if (prefix != null && prefix.isNotEmpty) buffer.write(prefix);
    buffer.write(value);
    if (suffix != null && suffix.isNotEmpty) buffer.write(' $suffix');
    lines.add(buffer.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) return DateTime.tryParse(timestamp);
    return null;
  }

  static String? _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is DateTime) return timestamp.toIso8601String();
    if (timestamp is String) return timestamp;
    return null;
  }
}

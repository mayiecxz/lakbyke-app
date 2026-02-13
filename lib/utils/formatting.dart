/// Utility functions for formatting data values
library;

/// Formats a number compactly when >= 1000 (e.g. 1220 → "1.2k", 1000 → "1.0k").
/// For values under 1000, returns [value].toStringAsFixed([maxDecimals]) (no "k").
String formatCompactNumber(num value, [int maxDecimals = 1]) {
  final abs = value.abs();
  if (abs >= 1000) {
    final scaled = value / 1000;
    return '${scaled.toStringAsFixed(maxDecimals)}k';
  }
  return value.toStringAsFixed(maxDecimals);
}

/// Formats currency with compact form when >= 1000 (e.g. 1220 → "₱1.2k").
/// For values under 1000, returns "₱" + value with 2 decimals.
String formatCompactCurrency(num value) {
  final abs = value.abs();
  if (abs >= 1000) {
    return '₱${formatCompactNumber(value)}';
  }
  return '₱${value.toStringAsFixed(2)}';
}

/// Formats energy value in Wh, converting to kWh if >= 1000 Wh
/// Returns a formatted string with appropriate unit
String formatEnergy(double whValue) {
  if (whValue >= 1000.0) {
    final kwhValue = whValue / 1000.0;
    return '${kwhValue.toStringAsFixed(2)} kWh';
  } else {
    return '${whValue.toStringAsFixed(2)} Wh';
  }
}

/// Formats energy value in Wh, converting to kWh if >= 1000 Wh
/// Returns a formatted string with appropriate unit (no decimal for Wh if < 10)
String formatEnergyCompact(double whValue) {
  if (whValue >= 1000.0) {
    final kwhValue = whValue / 1000.0;
    return '${kwhValue.toStringAsFixed(2)} kWh';
  } else if (whValue < 10.0) {
    return '${whValue.toStringAsFixed(2)} Wh';
  } else {
    return '${whValue.toStringAsFixed(1)} Wh';
  }
}

/// Utility functions for formatting data values

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

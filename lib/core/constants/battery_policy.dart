/// Battery policy constants (sell/swap rules to prevent deep discharge).
class BatteryPolicy {
  BatteryPolicy._();

  /// Minimum battery percentage allowed to sell or exchange (below this risks deep discharge).
  static const int minBatteryPercentToSell = 50;
}

/// Cost-Benefit Analysis (CBA) constants — single source of truth.
/// All values in PHP (₱). Used by cyclist_insights and UI for reference projections.
class CBAConstants {
  CBAConstants._();

  // === STATION CONSTANTS ===
  static const double stationCapex = 10844.00;
  static const double stationYearlyMaint = 1360.00;
  static const double stationDailyMaint = stationYearlyMaint / 365; // ~3.72
  static const double stationServiceFee = 5.00;
  static const int stationBreakevenMonths = 4; // Scenario B
  static const double stationRoiPercent = 222.3; // Scenario B

  // === CYCLIST CONSTANTS ===
  static const double cyclistCapex = 3792.00;
  /// ROI percent at which investment is considered recovered (breakeven).
  static const double cyclistRoiRecoveredPercent = 100.0;
  static const double cyclistYearlyMaint = 700.00;
  static const double cyclistDailyMaint = cyclistYearlyMaint / 365; // ~1.91
  static const int cyclistBreakevenMonths = 8;

  // === SCENARIOS (Buyback Price) ===
  static const double buybackLow = 10.00;
  static const double buybackOptimal = 60.00; // Full battery value (₱)
  static const double buybackHigh = 60.00;

  // === ENERGY ===
  static const double batteryCapacityWh = 72.0;
  static const String batteryUnitLabel = '1 Unit (72Wh)';

  // === SEMESTER DATES (configurable per semester) ===
  static final DateTime semesterStart = DateTime(2025, 8, 18);
  static final DateTime semesterEnd = DateTime(2026, 3, 27);
}

import 'package:lakbyke_mobile/features/insights/domain/cba_constants.dart';

/// Cyclist-only CBA calculations: net daily, reference monthly gross (22 school days), breakeven message.
/// No Firebase — pure functions using [CBAConstants].
class CyclistInsights {
  CyclistInsights._();

  /// Returns NET daily earnings (Gross - Maint).
  /// Default is Optimal Scenario (₱30).
  static double netDailyEarnings({double buybackPrice = CBAConstants.buybackOptimal}) {
    return buybackPrice - CBAConstants.cyclistDailyMaint;
  }

  /// Returns projected monthly earnings (Gross).
  /// Defaults to 22 school days to match thesis / CBA paper logic.
  static double projectedMonthlyGross({int days = 22}) {
    return CBAConstants.buybackOptimal * days;
  }

  /// Message for motivation/tips: optimal rate and cyclist breakeven.
  static String get breakevenMessage {
    return 'Based on the optimal rate of ₱${CBAConstants.buybackOptimal.toStringAsFixed(0)}, cyclists typically break even in ${CBAConstants.cyclistBreakevenMonths} months.';
  }
}

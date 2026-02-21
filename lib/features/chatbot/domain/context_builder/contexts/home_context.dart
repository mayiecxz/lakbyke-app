import 'package:lakbyke_mobile/core/formatting/formatting.dart';
import 'package:lakbyke_mobile/features/home/domain/models/home_data.dart';
import 'package:lakbyke_mobile/features/home/presentation/components/battery_cost_widget.dart';

/// Builds chatbot context from Home feature: battery, today's metrics, totals, equivalent price.
/// Use only these values in the prompt; never invent.
class HomeContext {
  /// Formats home data for the chatbot. Returns empty string if [data] is null.
  static String build(HomeData? data) {
    if (data == null) return '';
    final parts = <String>[];

    // Battery percentage / stats
    if (data.mountBatteryPercentage != null) {
      parts.add('Battery: ${data.mountBatteryPercentage!.toStringAsFixed(0)}%');
    } else {
      parts.add('Battery: N/A');
    }

    // Equivalent price of current battery charge (same formula as BatteryCostWidget)
    final batteryPercent = data.mountBatteryPercentage?.toInt();
    if (batteryPercent != null) {
      final rawCost = (batteryPercent / 100.0) * BatteryCostWidget.ratePer100;
      final cost = roundDownToMultipleOf5(rawCost).toDouble();
      parts.add('Equivalent battery value: ₱${cost.toInt()}');
    } else {
      parts.add('Equivalent battery value: N/A');
    }

    // Today's metrics including live effort
    parts.add('Today generated: ${data.todayWh.toStringAsFixed(2)} kWh');
    parts.add('Today distance: ${data.todayDistance.toStringAsFixed(2)} km');
    if (data.liveEffort > 0 && !data.isEffortStale) {
      parts.add('Live effort: ${data.liveEffort.toStringAsFixed(0)} W');
    } else {
      parts.add('Live effort: no recent pedal data');
    }

    // Totals
    parts.add('Total generated: ${data.totalGenerated.toStringAsFixed(2)} kWh');
    parts.add('Total redeemed: ${data.totalRedeems.toStringAsFixed(2)} kWh');
    parts.add('Batteries exchanged: ${data.batteriesExchanged}');

    return 'HOME / DASHBOARD (use only these values):\n${parts.join('. ')}.\n\n';
  }
}

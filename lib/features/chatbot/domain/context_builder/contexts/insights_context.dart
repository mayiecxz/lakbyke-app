import 'package:intl/intl.dart';
import 'package:lakbyke_mobile/core/formatting/formatting.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_model.dart';

/// Builds chatbot context from Insights feature: investment recovery, projected earnings, unit health, badge.
/// Use only these values in the prompt; never invent.
class InsightsContext {
  /// Formats insights data for the chatbot. Returns empty string if [model] is null.
  static String build(InsightsModel? model) {
    if (model == null) return '';
    final parts = <String>[];

    // Current investment recovery progress
    parts.add('Investment recovery: ${model.roiProgressFormatted}%');
    parts.add('Remaining to breakeven: ${formatCompactCurrency(model.remainingToBreakeven)}');
    parts.add('Breakeven: ${model.breakevenDateFormatted}');

    // Projected semester earnings (based on current set date)
    parts.add(
      'Projected semester earnings: ${formatCompactCurrency(model.projectedSemesterEarnings)} (semester end: ${DateFormat('MMM d, y').format(model.semesterEndDate)}, ${model.remainingSchoolDays} school days left)',
    );

    // Unit health
    parts.add('Unit health: ${model.unitHealthLabel} (${model.unitHealthStatus})');
    parts.add('Unit health note: ${model.unitHealthDescription}');
    parts.add('Total distance: ${model.totalDistanceKm.toStringAsFixed(1)} km');

    // Badge (rider persona)
    if (model.hasEnoughDataForPersona) {
      parts.add('Badge / rider persona: ${model.riderPersonaName}');
      parts.add('Persona advice: ${model.riderPersonaAdvice}');
    } else {
      parts.add('Badge / rider persona: Not enough data yet');
    }

    return 'INSIGHTS (use only these values):\n${parts.join('. ')}.\n\n';
  }
}

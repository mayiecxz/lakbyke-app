import 'package:flutter_test/flutter_test.dart';
import 'package:lakbyke_mobile/features/insights/domain/cba_constants.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_calculations.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_model.dart';

void main() {
  group('InsightsCalculations.classifyUnitHealth', () {
    test('totalDistanceKm < 500 -> excellent', () {
      expect(InsightsCalculations.classifyUnitHealth(0), 'excellent');
      expect(InsightsCalculations.classifyUnitHealth(499), 'excellent');
    });

    test('totalDistanceKm >= 500 and < 2000 -> bolt_check', () {
      expect(InsightsCalculations.classifyUnitHealth(500), 'bolt_check');
      expect(InsightsCalculations.classifyUnitHealth(1999), 'bolt_check');
    });

    test('totalDistanceKm >= 2000 -> motor_inspection', () {
      expect(InsightsCalculations.classifyUnitHealth(2000), 'motor_inspection');
      expect(InsightsCalculations.classifyUnitHealth(5000), 'motor_inspection');
    });
  });

  group('InsightsCalculations.classifyRiderPersona', () {
    test('early_bird: average hour 6–10', () {
      final ts = [
        DateTime(2025, 1, 1, 7, 0),
        DateTime(2025, 1, 2, 8, 0),
        DateTime(2025, 1, 3, 9, 0),
      ];
      expect(InsightsCalculations.classifyRiderPersona(ts), 'early_bird');
    });

    test('peak_provider: average hour 10–15', () {
      final ts = [
        DateTime(2025, 1, 1, 11, 0),
        DateTime(2025, 1, 2, 12, 0),
        DateTime(2025, 1, 3, 13, 0),
      ];
      expect(InsightsCalculations.classifyRiderPersona(ts), 'peak_provider');
    });

    test('sunset_cruiser: average hour 15–20', () {
      final ts = [
        DateTime(2025, 1, 1, 16, 0),
        DateTime(2025, 1, 2, 17, 0),
        DateTime(2025, 1, 3, 18, 0),
      ];
      expect(InsightsCalculations.classifyRiderPersona(ts), 'sunset_cruiser');
    });

    test('unknown: average hour outside ranges', () {
      final ts = [
        DateTime(2025, 1, 1, 2, 0),
        DateTime(2025, 1, 2, 3, 0),
      ];
      expect(InsightsCalculations.classifyRiderPersona(ts), 'unknown');
    });

    test('empty list -> unknown', () {
      expect(InsightsCalculations.classifyRiderPersona([]), 'unknown');
    });
  });

  group('InsightsCalculations.estimateBreakevenDate', () {
    test('no earnings (remainingDebt > 0, dailyAvg 0): null', () {
      expect(
        InsightsCalculations.estimateBreakevenDate(3792, 0),
        isNull,
      );
    });

    test('already recovered (remainingDebt 0): null', () {
      expect(
        InsightsCalculations.estimateBreakevenDate(0, 100),
        isNull,
      );
    });

    test('partial recovery: returns date ~remainingDebt/dailyAvg days from now', () {
      final now = DateTime(2025, 6, 1);
      final result = InsightsCalculations.estimateBreakevenDate(3600, 100, now);
      expect(result, isNotNull);
      expect(result!.difference(now).inDays, 36);
    });
  });

  group('InsightsCalculations.countRemainingSchoolDays', () {
    test('from after end: 0', () {
      final from = DateTime(2026, 4, 1);
      final end = DateTime(2026, 3, 27);
      expect(InsightsCalculations.countRemainingSchoolDays(from, end), 0);
    });

    test('same day weekday: 1', () {
      final from = DateTime(2025, 6, 2); // Monday
      final end = DateTime(2025, 6, 2);
      expect(InsightsCalculations.countRemainingSchoolDays(from, end), 1);
    });

    test('semester projection with 0 days remaining when from > end', () {
      final end = CBAConstants.semesterEnd;
      final from = end.add(const Duration(days: 1));
      expect(InsightsCalculations.countRemainingSchoolDays(from, end), 0);
    });
  });

  group('InsightsModel getters', () {
    test('hasRecoveredInvestment when roiProgressPercent >= 100', () {
      final model = InsightsModel(
        totalEarnings: 3792,
        initialInvestment: 3792,
        roiProgressPercent: 100,
        remainingToBreakeven: 0,
        estimatedBreakevenDate: null,
        dailyAverageEarnings: 100,
        projectedSemesterEarnings: 0,
        semesterEndDate: DateTime(2026, 3, 27),
        remainingSchoolDays: 0,
        bonusEarningsFor15MinMore: 0,
        totalDistanceKm: 0,
        unitHealthStatus: 'excellent',
        unitHealthLabel: 'Condition: Excellent',
        unitHealthDescription: 'No maintenance actions needed.',
        mntTag: 'MNT0001',
        riderPersona: 'unknown',
        riderPersonaName: 'Unknown',
        riderPersonaAdvice: 'Complete at least 3 rides.',
        averageRideHour: 0,
        peakStationHour: 12,
        recentRideTimestamps: [],
        hasEnoughDataForPersona: false,
      );
      expect(model.hasRecoveredInvestment, isTrue);
      expect(model.breakevenDateFormatted, 'Already recovered!');
    });

    test('roiProgressFormatted has one decimal', () {
      final model = InsightsModel(
        totalEarnings: 100,
        initialInvestment: 3792,
        roiProgressPercent: 2.6,
        remainingToBreakeven: 3692,
        estimatedBreakevenDate: null,
        dailyAverageEarnings: 10,
        projectedSemesterEarnings: 0,
        semesterEndDate: DateTime(2026, 3, 27),
        remainingSchoolDays: 0,
        bonusEarningsFor15MinMore: 0,
        totalDistanceKm: 0,
        unitHealthStatus: 'excellent',
        unitHealthLabel: 'Condition: Excellent',
        unitHealthDescription: 'No maintenance actions needed.',
        mntTag: 'MNT0001',
        riderPersona: 'unknown',
        riderPersonaName: 'Unknown',
        riderPersonaAdvice: 'Complete at least 3 rides.',
        averageRideHour: 0,
        peakStationHour: 12,
        recentRideTimestamps: [],
        hasEnoughDataForPersona: false,
      );
      expect(model.roiProgressFormatted, '2.6');
    });
  });
}

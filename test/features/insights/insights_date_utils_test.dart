import 'package:flutter_test/flutter_test.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_date_utils.dart';

void main() {
  group('subtractCalendarMonths', () {
    test('subtracts one month within same year', () {
      final date = DateTime(2025, 3, 15);
      expect(subtractCalendarMonths(date, 1), DateTime(2025, 2, 15));
    });

    test('handles year rollover', () {
      final date = DateTime(2025, 2, 10);
      expect(subtractCalendarMonths(date, 1), DateTime(2025, 1, 10));
      expect(subtractCalendarMonths(date, 2), DateTime(2024, 12, 10));
      expect(subtractCalendarMonths(date, 14), DateTime(2023, 12, 10));
    });

    test('clamps day to last day of target month', () {
      final date = DateTime(2025, 3, 31);
      final result = subtractCalendarMonths(date, 1);
      expect(result.year, 2025);
      expect(result.month, 2);
      expect(result.day, 28); // Feb has 28 days in 2025
    });

    test('zero months returns same date', () {
      final date = DateTime(2025, 6, 15);
      expect(subtractCalendarMonths(date, 0), date);
    });
  });

  group('isTimestampInWindow', () {
    test('includes timestamp on start boundary', () {
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 7);
      final onStart = DateTime(2025, 1, 1, 0, 0, 0);
      expect(isTimestampInWindow(onStart, start, end), isTrue);
    });

    test('includes timestamp on end boundary', () {
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 7);
      final onEnd = DateTime(2025, 1, 7, 23, 59, 59);
      expect(isTimestampInWindow(onEnd, start, end), isTrue);
    });

    test('excludes timestamp before start', () {
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 7);
      final before = DateTime(2024, 12, 31);
      expect(isTimestampInWindow(before, start, end), isFalse);
    });

    test('excludes timestamp after end', () {
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 7);
      final after = DateTime(2025, 1, 8);
      expect(isTimestampInWindow(after, start, end), isFalse);
    });

    test('includes timestamp in middle', () {
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 7);
      final mid = DateTime(2025, 1, 4, 12, 30);
      expect(isTimestampInWindow(mid, start, end), isTrue);
    });
  });
}

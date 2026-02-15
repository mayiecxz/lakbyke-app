import 'package:shared_preferences/shared_preferences.dart';

const String _keySemesterEnd = 'insights_semester_end_ms';
const String _keySemesterStart = 'insights_semester_start_ms';

/// Persists custom semester start/end for insights. Falls back to app defaults when not set.
class SemesterConfigStorage {
  const SemesterConfigStorage._();

  static Future<DateTime?> loadSemesterEnd() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_keySemesterEnd);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<DateTime?> loadSemesterStart() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_keySemesterStart);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> saveSemesterEnd(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySemesterEnd, date.millisecondsSinceEpoch);
  }

  static Future<void> saveSemesterStart(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySemesterStart, date.millisecondsSinceEpoch);
  }

  static Future<void> clearSemester() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySemesterEnd);
    await prefs.remove(_keySemesterStart);
  }
}

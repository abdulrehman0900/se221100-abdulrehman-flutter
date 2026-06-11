import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/course_model.dart';

class CourseLocalStore {
  static const String _coursesKey = 'cached_courses';
  static const String _lastSyncKey = 'cached_courses_synced_at';

  /// Persists [courses] locally, replacing any previously cached list.
  Future<void> saveCourses(List<Course> courses) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(courses.map((c) => c.toCacheMap()).toList());
    await prefs.setString(_coursesKey, encoded);
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Reads the cached courses, or an empty list if nothing is stored or the
  /// stored data is corrupt.
  Future<List<Course>> getCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_coursesKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException {
      // Corrupt cache — drop it so we start clean next time.
      await prefs.remove(_coursesKey);
      return [];
    }
  }

  /// Whether any course data is currently cached.
  Future<bool> hasCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_coursesKey);
    return raw != null && raw.isNotEmpty;
  }

  /// The time of the last successful sync, or null if never synced.
  Future<DateTime?> lastSyncedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSyncKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  /// Clears all cached course data.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_coursesKey);
    await prefs.remove(_lastSyncKey);
  }
}

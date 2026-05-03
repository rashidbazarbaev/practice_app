import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_lesson.dart';

/// Fetches schedule from OMSU eservice.
/// The site uses XHR requests to its internal API — we replicate those.
///
/// Endpoint pattern (observed via Network tab):
///   POST https://eservice.omsu.ru/schedule/
///   Content-Type: application/x-www-form-urlencoded
///   Body: group=<groupName>&week=<weekNumber>
///
/// The response is JSON with a lessons array.
/// Since there is no official API, we handle errors gracefully and
/// fall back to cached data when the site is unavailable.
class ScheduleService {
  static const _baseUrl = 'https://eservice.omsu.ru';
  static const _cacheKey = 'schedule_cache';
  static const _cacheGroupKey = 'schedule_cache_group';
  static const _cacheWeekKey = 'schedule_cache_week';

  // ── Public API ────────────────────────────────────────────────────────────

  /// Fetch schedule for [group] and [weekOffset] (0 = current week).
  /// Returns lessons sorted by date+time.
  /// Throws [ScheduleException] on network/parse errors (caller shows UI).
  Future<List<ScheduleLesson>> fetchSchedule({
    required String group,
    int weekOffset = 0,
  }) async {
    try {
      final lessons = await _fetchFromNetwork(group, weekOffset);
      await _cacheSchedule(lessons, group, weekOffset);
      return lessons;
    } catch (e) {
      // Try cache fallback
      final cached = await _loadFromCache(group, weekOffset);
      if (cached != null) return cached;
      throw ScheduleException('Не удалось загрузить расписание: $e');
    }
  }

  /// Load cached schedule without network request.
  Future<List<ScheduleLesson>?> getCachedSchedule(
      String group, int weekOffset) async {
    return _loadFromCache(group, weekOffset);
  }

  // ── Network ───────────────────────────────────────────────────────────────

  Future<List<ScheduleLesson>> _fetchFromNetwork(
      String group, int weekOffset) async {
    // Calculate the week number (ISO week of year)
    final now = DateTime.now();
    final targetDate = now.add(Duration(days: weekOffset * 7));
    final weekNum = _isoWeekNumber(targetDate);

    // Try multiple endpoint patterns observed on the site
    List<ScheduleLesson>? result;

    // Attempt 1: JSON API endpoint
    result = await _tryJsonEndpoint(group, weekNum, targetDate);
    if (result != null) return result;

    // Attempt 2: Alternative endpoint
    result = await _tryAltEndpoint(group, weekNum, targetDate);
    if (result != null) return result;

    throw ScheduleException('Сервер расписания недоступен');
  }

  Future<List<ScheduleLesson>?> _tryJsonEndpoint(
      String group, int weekNum, DateTime weekDate) async {
    try {
      final uri = Uri.parse('$_baseUrl/schedule/');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'X-Requested-With': 'XMLHttpRequest',
              'Accept': 'application/json',
              'Referer': '$_baseUrl/',
            },
            body: {
              'group': group,
              'week': weekNum.toString(),
              'action': 'getSchedule',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _parseResponse(response.body, weekDate);
      }
    } catch (_) {}
    return null;
  }

  Future<List<ScheduleLesson>?> _tryAltEndpoint(
      String group, int weekNum, DateTime weekDate) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl/schedule/getSchedule?group=${Uri.encodeComponent(group)}&week=$weekNum');
      final response = await http.get(
        uri,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _parseResponse(response.body, weekDate);
      }
    } catch (_) {}
    return null;
  }

  // ── Parsing ───────────────────────────────────────────────────────────────

  List<ScheduleLesson> _parseResponse(String body, DateTime weekDate) {
    final dynamic decoded = jsonDecode(body);
    final lessons = <ScheduleLesson>[];

    if (decoded is List) {
      // Array of lessons
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final date = _parseLessonDate(item, weekDate);
          lessons.add(ScheduleLesson.fromOmsuJson(item, date));
        }
      }
    } else if (decoded is Map<String, dynamic>) {
      // Object with days as keys or a "lessons" array
      final data = decoded['lessons'] ?? decoded['data'] ?? decoded['schedule'];
      if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            final date = _parseLessonDate(item, weekDate);
            lessons.add(ScheduleLesson.fromOmsuJson(item, date));
          }
        }
      } else {
        // Try iterating over day keys (Mon=1..Sun=7)
        for (int day = 1; day <= 7; day++) {
          final dayData = decoded[day.toString()] ?? decoded['$day'];
          if (dayData is List) {
            final date = _mondayOfWeek(weekDate)
                .add(Duration(days: day - 1));
            for (final item in dayData) {
              if (item is Map<String, dynamic>) {
                lessons.add(ScheduleLesson.fromOmsuJson(item, date));
              }
            }
          }
        }
      }
    }

    lessons.sort((a, b) {
      final dateCmp = a.date.compareTo(b.date);
      if (dateCmp != 0) return dateCmp;
      return a.lessonNumber.compareTo(b.lessonNumber);
    });

    return lessons;
  }

  DateTime _parseLessonDate(Map<String, dynamic> json, DateTime weekDate) {
    // Try explicit date field
    final dateStr = json['date']?.toString() ?? json['lessonDate']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      try {
        return DateTime.parse(dateStr);
      } catch (_) {}
      // Try dd.MM.yyyy
      final parts = dateStr.split('.');
      if (parts.length == 3) {
        try {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        } catch (_) {}
      }
    }
    // Fall back to day-of-week field
    final dow = json['dayOfWeek'] ?? json['day'] ?? json['weekDay'];
    if (dow != null) {
      final dayNum = int.tryParse(dow.toString()) ?? 1;
      return _mondayOfWeek(weekDate).add(Duration(days: dayNum - 1));
    }
    return weekDate;
  }

  // ── Cache ─────────────────────────────────────────────────────────────────

  String _cacheKeyFor(String group, int weekOffset) =>
      '${_cacheKey}_${group}_$weekOffset';

  Future<void> _cacheSchedule(
      List<ScheduleLesson> lessons, String group, int weekOffset) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(lessons.map((l) => l.toJson()).toList());
    await prefs.setString(_cacheKeyFor(group, weekOffset), json);
    await prefs.setString(_cacheGroupKey, group);
    await prefs.setInt(_cacheWeekKey, weekOffset);
  }

  Future<List<ScheduleLesson>?> _loadFromCache(
      String group, int weekOffset) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_cacheKeyFor(group, weekOffset));
    if (json == null) return null;
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => ScheduleLesson.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<String?> getCachedGroup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheGroupKey);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  DateTime _mondayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  int _isoWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final firstMonday = startOfYear.weekday <= 4
        ? startOfYear.subtract(Duration(days: startOfYear.weekday - 1))
        : startOfYear
            .add(Duration(days: DateTime.daysPerWeek - startOfYear.weekday + 1));
    final diff = date.difference(firstMonday).inDays;
    return (diff / 7).floor() + 1;
  }
}

class ScheduleException implements Exception {
  final String message;
  ScheduleException(this.message);

  @override
  String toString() => message;
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_lesson.dart';

/// Fetches schedule from OMSU eservice official API.
/// Base URL: https://eservice.omsu.ru/schedule/backend
///
/// Flow:
///   1. GET /dict/groups  — get all groups (cached 1 hour)
///   2. Find groupId by name (case-insensitive)
///   3. GET /schedule/group/{groupId}  — get full schedule
class ScheduleService {
  static const _baseUrl = 'https://eservice.omsu.ru/schedule/backend';
  static const _cacheScheduleKey = 'schedule_cache_v2';
  static const _cacheGroupsKey = 'schedule_groups_cache';
  static const _cacheGroupsTimeKey = 'schedule_groups_cache_time';
  static const _savedGroupIdKey = 'schedule_saved_group_id';
  static const _savedGroupNameKey = 'schedule_saved_group_name';
  static const _groupsCacheDuration = Duration(hours: 1);
  static const _timeout = Duration(seconds: 5);

  // ── Public API ────────────────────────────────────────────────────────────

  /// Fetch full schedule for [groupName].
  /// Returns all available lessons sorted by date + lesson number.
  /// Throws [ScheduleException] on errors.
  Future<List<ScheduleLesson>> fetchSchedule({
    required String groupName,
  }) async {
    try {
      final groupId = await _resolveGroupId(groupName);
      final lessons = await _fetchLessons(groupId, groupName);
      await _cacheSchedule(lessons, groupName);
      return lessons;
    } on ScheduleException {
      rethrow;
    } catch (e) {
      // Try cache fallback
      final cached = await loadFromCache(groupName);
      if (cached != null && cached.isNotEmpty) return cached;
      throw ScheduleException('Не удалось загрузить расписание: $e');
    }
  }

  /// Load cached schedule without network request.
  Future<List<ScheduleLesson>?> loadFromCache(String groupName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_cacheScheduleKey}_$groupName';
    final json = prefs.getString(key);
    if (json == null) return null;
    try {
      final list = jsonDecode(json) as List;
      final lessons = list
          .map((e) => ScheduleLesson.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      // Invalidate cache if subjects are empty (stale data from old format)
      if (lessons.isNotEmpty && lessons.every((l) => l.subject.isEmpty)) {
        await _clearScheduleCache(groupName);
        return null;
      }
      return lessons;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearScheduleCache(String groupName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_cacheScheduleKey}_$groupName');
  }

  /// Returns the last saved group name (from previous session).
  Future<String?> getSavedGroupName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedGroupNameKey);
  }

  /// Returns all group names for autocomplete (from cache or network).
  Future<List<String>> getGroupNames() async {
    final groups = await _loadGroups();
    return groups.map((g) => g['name'] as String).toList();
  }

  // ── Step 1: resolve groupId ───────────────────────────────────────────────

  Future<int> _resolveGroupId(String groupName) async {
    // Check if we already saved this group's id
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(_savedGroupNameKey);
    final savedId = prefs.getInt(_savedGroupIdKey);
    if (savedName != null &&
        savedId != null &&
        savedName.trim().toLowerCase() == groupName.trim().toLowerCase()) {
      return savedId;
    }

    final groups = await _loadGroups();
    final match = groups.firstWhere(
      (g) =>
          (g['name'] as String).trim().toLowerCase() ==
          groupName.trim().toLowerCase(),
      orElse: () => {},
    );

    if (match.isEmpty) {
      throw ScheduleException(
          'Группа "$groupName" не найдена. Проверьте название.');
    }

    final groupId = match['id'] as int;
    await prefs.setInt(_savedGroupIdKey, groupId);
    await prefs.setString(_savedGroupNameKey, groupName.trim());
    return groupId;
  }

  // ── Step 2: load groups list (with 1-hour cache) ──────────────────────────

  Future<List<Map<String, dynamic>>> _loadGroups() async {
    final prefs = await SharedPreferences.getInstance();

    // Check cache freshness
    final cachedTime = prefs.getInt(_cacheGroupsTimeKey);
    final cachedJson = prefs.getString(_cacheGroupsKey);
    if (cachedTime != null && cachedJson != null) {
      final age = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(cachedTime));
      if (age < _groupsCacheDuration) {
        try {
          final list = jsonDecode(cachedJson) as List;
          return list.cast<Map<String, dynamic>>();
        } catch (_) {}
      }
    }

    // Fetch from network
    final uri = Uri.parse('$_baseUrl/dict/groups');
    final response = await http.get(uri).timeout(_timeout);

    if (response.statusCode != 200) {
      throw ScheduleException(
          'Ошибка загрузки списка групп (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['success'] != true) {
      throw ScheduleException('Сервер вернул ошибку при загрузке групп');
    }

    final data = (decoded['data'] as List).cast<Map<String, dynamic>>();

    // Save to cache
    await prefs.setString(_cacheGroupsKey, jsonEncode(data));
    await prefs.setInt(
        _cacheGroupsTimeKey, DateTime.now().millisecondsSinceEpoch);

    return data;
  }

  // ── Step 3: fetch schedule for groupId ───────────────────────────────────

  Future<List<ScheduleLesson>> _fetchLessons(
      int groupId, String groupName) async {
    final uri = Uri.parse('$_baseUrl/schedule/group/$groupId');
    final response = await http.get(uri).timeout(_timeout);

    if (response.statusCode != 200) {
      throw ScheduleException(
          'Ошибка загрузки расписания (${response.statusCode})');
    }

    // Debug: print first 500 chars of response to see real API format
    // debugPrint('[ScheduleService] response (first 500): ...');

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final days = decoded['data'] as List?;
    if (days == null) {
      throw ScheduleException('Неожиданный формат ответа сервера');
    }

    final lessons = <ScheduleLesson>[];
    for (final dayEntry in days) {
      final dayStr = dayEntry['day'] as String; // "dd.MM.yyyy"
      final date = _parseDate(dayStr);
      final lessonList = dayEntry['lessons'] as List? ?? [];
      for (final l in lessonList) {
        lessons.add(ScheduleLesson.fromOmsuJson(
          l as Map<String, dynamic>,
          date,
          groupName,
        ));
      }
    }

    lessons.sort((a, b) {
      final d = a.date.compareTo(b.date);
      return d != 0 ? d : a.lessonNumber.compareTo(b.lessonNumber);
    });

    return lessons;
  }

  // ── Cache ─────────────────────────────────────────────────────────────────

  Future<void> _cacheSchedule(
      List<ScheduleLesson> lessons, String groupName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_cacheScheduleKey}_$groupName';
    await prefs.setString(
        key, jsonEncode(lessons.map((l) => l.toJson()).toList()));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Parse "dd.MM.yyyy" → DateTime
  DateTime _parseDate(String s) {
    final parts = s.split('.');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }
}

class ScheduleException implements Exception {
  final String message;
  ScheduleException(this.message);

  @override
  String toString() => message;
}

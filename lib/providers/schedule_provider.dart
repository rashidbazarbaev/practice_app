import 'package:flutter/material.dart';
import '../models/schedule_lesson.dart';
import '../models/task.dart';
import '../services/schedule_service.dart';

enum ScheduleLoadState { idle, loading, loaded, error, cached }

class ScheduleProvider extends ChangeNotifier {
  final ScheduleService _service = ScheduleService();

  List<ScheduleLesson> _lessons = [];
  ScheduleLoadState _loadState = ScheduleLoadState.idle;
  String _errorMessage = '';
  String _group = '';
  DateTime? _lastUpdated;

  List<ScheduleLesson> get lessons => _lessons;
  ScheduleLoadState get loadState => _loadState;
  String get errorMessage => _errorMessage;
  String get group => _group;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isLoading => _loadState == ScheduleLoadState.loading;
  bool get hasData => _lessons.isNotEmpty;

  // ── Grouped by day ────────────────────────────────────────────────────────

  Map<DateTime, List<ScheduleLesson>> get lessonsByDay {
    final map = <DateTime, List<ScheduleLesson>>{};
    for (final l in _lessons) {
      final day = DateTime(l.date.year, l.date.month, l.date.day);
      map.putIfAbsent(day, () => []).add(l);
    }
    return map;
  }

  List<ScheduleLesson> getLessonsForDay(DateTime day) {
    return _lessons.where((l) {
      return l.date.year == day.year &&
          l.date.month == day.month &&
          l.date.day == day.day;
    }).toList();
  }

  List<ScheduleLesson> get todayLessons => getLessonsForDay(DateTime.now());

  /// Unique subject names from the loaded schedule, sorted alphabetically.
  List<String> get uniqueSubjectNames {
    final names = _lessons
        .map((l) => l.subject)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return names;
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadSchedule({
    required String group,
    bool forceRefresh = false,
  }) async {
    if (group.isEmpty) return;

    _group = group;
    _loadState = ScheduleLoadState.loading;
    _errorMessage = '';
    notifyListeners();

    // Try cache first unless forcing refresh
    if (!forceRefresh) {
      final cached = await _service.loadFromCache(group);
      if (cached != null && cached.isNotEmpty) {
        _lessons = cached;
        _loadState = ScheduleLoadState.cached;
        notifyListeners();
        // Refresh in background
        _refreshInBackground(group);
        return;
      }
    }

    try {
      _lessons = await _service.fetchSchedule(groupName: group);
      _lastUpdated = DateTime.now();
      _loadState = ScheduleLoadState.loaded;
    } on ScheduleException catch (e) {
      _errorMessage = e.message;
      _loadState = ScheduleLoadState.error;
    } catch (e) {
      _errorMessage = 'Неизвестная ошибка: $e';
      _loadState = ScheduleLoadState.error;
    }
    notifyListeners();
  }

  Future<void> _refreshInBackground(String group) async {
    try {
      final fresh = await _service.fetchSchedule(groupName: group);
      _lessons = fresh;
      _lastUpdated = DateTime.now();
      _loadState = ScheduleLoadState.loaded;
      notifyListeners();
    } catch (_) {
      // Keep cached data, silently ignore
    }
  }

  Future<void> refresh() async {
    await loadSchedule(group: _group, forceRefresh: true);
  }

  /// Try to restore last used group from storage on app start.
  Future<void> restoreLastGroup() async {
    final saved = await _service.getSavedGroupName();
    if (saved != null && saved.isNotEmpty) {
      await loadSchedule(group: saved);
    }
  }

  /// Returns group name suggestions for autocomplete.
  Future<List<String>> getGroupSuggestions(String query) async {
    try {
      final all = await _service.getGroupNames();
      if (query.isEmpty) return all.take(20).toList();
      final q = query.trim().toLowerCase();
      return all.where((n) => n.toLowerCase().contains(q)).take(20).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Suggest deadlines from schedule ──────────────────────────────────────

  List<DateTime> suggestDeadlines(String subjectName) {
    final now = DateTime.now();
    return _lessons
        .where((l) =>
            l.date.isAfter(now) &&
            l.subject.toLowerCase().contains(subjectName.toLowerCase()))
        .map((l) => l.date)
        .take(3)
        .toList();
  }

  Task? buildSuggestedTask({
    required ScheduleLesson lesson,
    required String taskId,
  }) {
    final deadline = lesson.date.subtract(const Duration(hours: 1));
    if (deadline.isBefore(DateTime.now())) return null;

    return Task(
      id: taskId,
      title: 'Подготовка к: ${lesson.subject}',
      description: '${lesson.type} • ${lesson.teacher}',
      subjectId: lesson.subject.toLowerCase().replaceAll(' ', '_'),
      subjectName: lesson.subject,
      deadline: deadline,
      recommendedStartDate: deadline.subtract(const Duration(days: 2)),
      status: TaskStatus.pending,
      priority: TaskPriority.medium,
      type: TaskType.assignment,
      complexityNote: 'Предложено из расписания',
      createdAt: DateTime.now(),
    );
  }
}

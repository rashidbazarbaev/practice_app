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
  int _weekOffset = 0;
  DateTime? _lastUpdated;

  List<ScheduleLesson> get lessons => _lessons;
  ScheduleLoadState get loadState => _loadState;
  String get errorMessage => _errorMessage;
  String get group => _group;
  int get weekOffset => _weekOffset;
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

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadSchedule({
    required String group,
    int weekOffset = 0,
    bool forceRefresh = false,
  }) async {
    if (group.isEmpty) return;

    _group = group;
    _weekOffset = weekOffset;
    _loadState = ScheduleLoadState.loading;
    _errorMessage = '';
    notifyListeners();

    // Try cache first if not forcing refresh
    if (!forceRefresh) {
      final cached = await _service.getCachedSchedule(group, weekOffset);
      if (cached != null && cached.isNotEmpty) {
        _lessons = cached;
        _loadState = ScheduleLoadState.cached;
        notifyListeners();
        // Then refresh in background
        _refreshInBackground(group, weekOffset);
        return;
      }
    }

    try {
      _lessons = await _service.fetchSchedule(
        group: group,
        weekOffset: weekOffset,
      );
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

  Future<void> _refreshInBackground(String group, int weekOffset) async {
    try {
      final fresh = await _service.fetchSchedule(
        group: group,
        weekOffset: weekOffset,
      );
      _lessons = fresh;
      _lastUpdated = DateTime.now();
      _loadState = ScheduleLoadState.loaded;
      notifyListeners();
    } catch (_) {
      // Keep cached data, silently ignore
    }
  }

  Future<void> refresh() async {
    await loadSchedule(
      group: _group,
      weekOffset: _weekOffset,
      forceRefresh: true,
    );
  }

  void loadDemoSchedule(String group) {
    _group = group;
    _lessons = _buildDemoLessons();
    _lastUpdated = DateTime.now();
    _loadState = ScheduleLoadState.loaded;
    notifyListeners();
  }

  List<ScheduleLesson> _buildDemoLessons() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    ScheduleLesson make(int dayOffset, String time, String end,
        String subj, String teacher, String room, String type, int num) {
      return ScheduleLesson(
        id: '$dayOffset-$num',
        subject: subj,
        teacher: teacher,
        room: room,
        type: type,
        date: monday.add(Duration(days: dayOffset)),
        timeStart: time,
        timeEnd: end,
        lessonNumber: num,
        group: _group,
      );
    }

    return [
      make(0, '08:00', '09:35', 'Математический анализ', 'Смирнов А.В.', '301', 'Лекция', 1),
      make(0, '09:45', '11:20', 'Программирование', 'Петрова Е.С.', 'Лаб. 12', 'Лабораторная', 2),
      make(0, '11:30', '13:05', 'Физика', 'Козлов Д.М.', '205', 'Лекция', 3),
      make(1, '08:00', '09:35', 'История', 'Новикова Л.П.', '401', 'Семинар', 1),
      make(1, '09:45', '11:20', 'Английский язык', 'Белова О.А.', '102', 'Практика', 2),
      make(1, '11:30', '13:05', 'Математический анализ', 'Смирнов А.В.', '301', 'Практика', 3),
      make(2, '08:00', '09:35', 'Программирование', 'Петрова Е.С.', 'Лаб. 12', 'Лабораторная', 1),
      make(2, '09:45', '11:20', 'Физика', 'Козлов Д.М.', 'Лаб. 5', 'Лабораторная', 2),
      make(3, '08:00', '09:35', 'Английский язык', 'Белова О.А.', '102', 'Практика', 1),
      make(3, '09:45', '11:20', 'История', 'Новикова Л.П.', '401', 'Лекция', 2),
      make(3, '11:30', '13:05', 'Программирование', 'Петрова Е.С.', '301', 'Лекция', 3),
      make(4, '08:00', '09:35', 'Математический анализ', 'Смирнов А.В.', '301', 'Лекция', 1),
      make(4, '09:45', '11:20', 'Физика', 'Козлов Д.М.', '205', 'Практика', 2),
    ];
  }

  void changeWeek(int offset) {
    _weekOffset = offset;
    loadSchedule(group: _group, weekOffset: offset);
  }

  void setGroup(String group) {
    _group = group;
    notifyListeners();
  }

  // ── Suggest deadlines from schedule ──────────────────────────────────────

  /// Returns suggested deadline dates based on upcoming lessons for a subject.
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

  /// Build suggested Task from a lesson (for quick task creation).
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
      recommendedStartDate:
          deadline.subtract(const Duration(days: 2)),
      status: TaskStatus.pending,
      priority: TaskPriority.medium,
      type: TaskType.assignment,
      complexityNote: 'Предложено из расписания',
      createdAt: DateTime.now(),
    );
  }
}

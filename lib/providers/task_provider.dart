import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  final _uuid = const Uuid();

  List<Task> get tasks => _tasks;

  List<Task> get pendingTasks => _tasks
      .where((t) =>
          t.status == TaskStatus.pending ||
          t.status == TaskStatus.inProgress)
      .toList()
    ..sort((a, b) => a.deadline.compareTo(b.deadline));

  List<Task> get upcomingTasks => pendingTasks.take(5).toList();

  List<Task> get overdueTasks => _tasks.where((t) => t.isOverdue).toList();

  List<Task> getTasksForDay(DateTime day) {
    return _tasks.where((t) {
      return t.deadline.year == day.year &&
          t.deadline.month == day.month &&
          t.deadline.day == day.day;
    }).toList();
  }

  List<Task> getTasksForSubject(String subjectId) =>
      _tasks.where((t) => t.subjectId == subjectId).toList();

  Map<DateTime, List<Task>> get tasksByDay {
    final map = <DateTime, List<Task>>{};
    for (final task in _tasks) {
      final day = DateTime(
          task.deadline.year, task.deadline.month, task.deadline.day);
      map.putIfAbsent(day, () => []).add(task);
    }
    return map;
  }

  int get completedCount =>
      _tasks.where((t) => t.status == TaskStatus.completed).length;

  int get totalCount => _tasks.length;

  /// Returns count of completed tasks per weekday for the current week.
  /// Index 0 = Monday, 6 = Sunday.
  List<int> get completedPerWeekday {
    final now = DateTime.now();
    // Start of current week (Monday)
    final weekStart =
        DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final counts = List<int>.filled(7, 0);
    for (final task in _tasks) {
      if (task.status == TaskStatus.completed) {
        final day = DateTime(
            task.deadline.year, task.deadline.month, task.deadline.day);
        final diff = day.difference(weekStart).inDays;
        if (diff >= 0 && diff < 7) {
          counts[diff]++;
        }
      }
    }
    return counts;
  }

  TaskProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('tasks');
    if (json != null) {
      final list = jsonDecode(json) as List;
      _tasks = list.map((e) => Task.fromJson(e)).toList();
      _updateOverdueStatuses();
    }
    notifyListeners();
  }

  void _updateOverdueStatuses() {
    final now = DateTime.now();
    for (final task in _tasks) {
      if (task.deadline.isBefore(now) &&
          task.status != TaskStatus.completed) {
        task.status = TaskStatus.overdue;
      }
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'tasks', jsonEncode(_tasks.map((t) => t.toJson()).toList()));
  }

  Future<void> addTask(Task task) async {
    _tasks.add(task);
    await _saveData();
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      await _saveData();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    await _saveData();
    notifyListeners();
  }

  Future<void> completeTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(status: TaskStatus.completed);
      await _saveData();
      notifyListeners();
    }
  }

  String newTaskId() => _uuid.v4();

  /// Simple heuristic for recommended start date
  DateTime computeRecommendedStart(DateTime deadline, TaskPriority priority) {
    final daysBeforeMap = {
      TaskPriority.low: 1,
      TaskPriority.medium: 2,
      TaskPriority.high: 3,
      TaskPriority.critical: 5,
    };
    return deadline.subtract(Duration(days: daysBeforeMap[priority] ?? 2));
  }
}

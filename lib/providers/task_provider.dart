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
      .where((t) => t.status == TaskStatus.pending || t.status == TaskStatus.inProgress)
      .toList()
    ..sort((a, b) => a.deadline.compareTo(b.deadline));

  List<Task> get upcomingTasks => pendingTasks.take(5).toList();

  List<Task> get overdueTasks =>
      _tasks.where((t) => t.isOverdue).toList();

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
    } else {
      _tasks = _mockTasks();
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

  List<Task> _mockTasks() {
    final now = DateTime.now();
    return [
      Task(
        id: _uuid.v4(),
        title: 'Лабораторная работа №3',
        description: 'Реализовать алгоритм сортировки на Python',
        subjectId: 'prog',
        subjectName: 'Программирование',
        deadline: now.add(const Duration(days: 2)),
        recommendedStartDate: now.subtract(const Duration(days: 1)),
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        type: TaskType.assignment,
        estimatedMinutes: 120,
        complexityNote: 'Средняя сложность',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Task(
        id: _uuid.v4(),
        title: 'Контрольная по матанализу',
        description: 'Темы: пределы, производные, интегралы',
        subjectId: 'math',
        subjectName: 'Математический анализ',
        deadline: now.add(const Duration(days: 5)),
        recommendedStartDate: now.add(const Duration(days: 1)),
        status: TaskStatus.pending,
        priority: TaskPriority.critical,
        type: TaskType.exam,
        estimatedMinutes: 90,
        complexityNote: 'Высокая сложность',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Task(
        id: _uuid.v4(),
        title: 'Эссе по истории',
        description: 'Тема: Реформы Петра I и их влияние',
        subjectId: 'hist',
        subjectName: 'История',
        deadline: now.add(const Duration(days: 7)),
        status: TaskStatus.pending,
        priority: TaskPriority.medium,
        type: TaskType.assignment,
        estimatedMinutes: 60,
        complexityNote: 'Низкая сложность',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        id: _uuid.v4(),
        title: 'Словарный диктант',
        description: 'Unit 5-6, 50 слов',
        subjectId: 'eng',
        subjectName: 'Английский язык',
        deadline: now.add(const Duration(days: 1)),
        status: TaskStatus.pending,
        priority: TaskPriority.high,
        type: TaskType.exam,
        estimatedMinutes: 30,
        complexityNote: 'Низкая сложность',
        createdAt: now,
      ),
      Task(
        id: _uuid.v4(),
        title: 'Отчёт по физике',
        description: 'Лабораторная работа: законы Ньютона',
        subjectId: 'phys',
        subjectName: 'Физика',
        deadline: now.subtract(const Duration(days: 1)),
        status: TaskStatus.overdue,
        priority: TaskPriority.high,
        type: TaskType.assignment,
        estimatedMinutes: 90,
        complexityNote: 'Средняя сложность',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Task(
        id: _uuid.v4(),
        title: 'Домашнее задание по матанализу',
        description: 'Задачи 1-15 из главы 4',
        subjectId: 'math',
        subjectName: 'Математический анализ',
        deadline: now.subtract(const Duration(days: 3)),
        status: TaskStatus.completed,
        priority: TaskPriority.medium,
        type: TaskType.assignment,
        estimatedMinutes: 60,
        actualMinutes: 75,
        complexityNote: 'Средняя сложность',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
    ];
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
    return deadline
        .subtract(Duration(days: daysBeforeMap[priority] ?? 2));
  }
}

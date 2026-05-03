import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/pomodoro_session.dart';

class PomodoroProvider extends ChangeNotifier {
  PomodoroState _state = PomodoroState.idle;
  int _workMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  int _sessionsBeforeLongBreak = 4;

  int _secondsRemaining = 0;
  int _completedSessions = 0;
  Timer? _timer;
  String? _currentTaskId;
  String? _currentTaskTitle;

  List<PomodoroSession> _sessions = [];
  final _uuid = const Uuid();

  PomodoroState get state => _state;
  int get secondsRemaining => _secondsRemaining;
  int get completedSessions => _completedSessions;
  int get workMinutes => _workMinutes;
  int get shortBreakMinutes => _shortBreakMinutes;
  int get longBreakMinutes => _longBreakMinutes;
  int get sessionsBeforeLongBreak => _sessionsBeforeLongBreak;
  List<PomodoroSession> get sessions => _sessions;
  String? get currentTaskTitle => _currentTaskTitle;

  bool get isRunning => _timer != null && _timer!.isActive;

  int get totalMinutesStudied {
    return _sessions
        .where((s) => s.completed)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  PomodoroProvider() {
    _secondsRemaining = _workMinutes * 60;
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('pomodoro_sessions');
    if (json != null) {
      final list = jsonDecode(json) as List;
      _sessions = list.map((e) => PomodoroSession.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'pomodoro_sessions',
        jsonEncode(_sessions.map((s) => s.toJson()).toList()));
  }

  void setTask(String? taskId, String? taskTitle) {
    _currentTaskId = taskId;
    _currentTaskTitle = taskTitle;
    notifyListeners();
  }

  void start() {
    if (_state == PomodoroState.idle) {
      _state = PomodoroState.working;
      _secondsRemaining = _workMinutes * 60;
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void resume() {
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _state = PomodoroState.idle;
    _secondsRemaining = _workMinutes * 60;
    notifyListeners();
  }

  void _tick(Timer timer) {
    if (_secondsRemaining > 0) {
      _secondsRemaining--;
      notifyListeners();
    } else {
      _onTimerComplete();
    }
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _timer = null;

    if (_state == PomodoroState.working) {
      _completedSessions++;
      final session = PomodoroSession(
        id: _uuid.v4(),
        taskId: _currentTaskId,
        taskTitle: _currentTaskTitle,
        startTime: DateTime.now().subtract(Duration(minutes: _workMinutes)),
        endTime: DateTime.now(),
        durationMinutes: _workMinutes,
        completed: true,
      );
      _sessions.add(session);
      _saveSessions();

      if (_completedSessions % _sessionsBeforeLongBreak == 0) {
        _state = PomodoroState.longBreak;
        _secondsRemaining = _longBreakMinutes * 60;
      } else {
        _state = PomodoroState.shortBreak;
        _secondsRemaining = _shortBreakMinutes * 60;
      }
    } else {
      _state = PomodoroState.idle;
      _secondsRemaining = _workMinutes * 60;
    }
    notifyListeners();
  }

  void skipToNext() {
    _timer?.cancel();
    _timer = null;
    _onTimerComplete();
  }

  void updateSettings({
    int? workMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
  }) {
    _workMinutes = workMinutes ?? _workMinutes;
    _shortBreakMinutes = shortBreakMinutes ?? _shortBreakMinutes;
    _longBreakMinutes = longBreakMinutes ?? _longBreakMinutes;
    _sessionsBeforeLongBreak =
        sessionsBeforeLongBreak ?? _sessionsBeforeLongBreak;
    if (_state == PomodoroState.idle) {
      _secondsRemaining = _workMinutes * 60;
    }
    notifyListeners();
  }

  String get formattedTime {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

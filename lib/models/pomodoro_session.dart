enum PomodoroState { idle, working, shortBreak, longBreak }

class PomodoroSession {
  final String id;
  final String? taskId;
  final String? taskTitle;
  final DateTime startTime;
  DateTime? endTime;
  int durationMinutes;
  bool completed;

  PomodoroSession({
    required this.id,
    this.taskId,
    this.taskTitle,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.completed,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'taskTitle': taskTitle,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'durationMinutes': durationMinutes,
        'completed': completed,
      };

  factory PomodoroSession.fromJson(Map<String, dynamic> json) =>
      PomodoroSession(
        id: json['id'],
        taskId: json['taskId'],
        taskTitle: json['taskTitle'],
        startTime: DateTime.parse(json['startTime']),
        endTime:
            json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
        durationMinutes: json['durationMinutes'],
        completed: json['completed'],
      );
}

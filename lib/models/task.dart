enum TaskStatus { pending, inProgress, completed, overdue }

enum TaskPriority { low, medium, high, critical }

enum TaskType { assignment, exam, reminder, other }

class Task {
  final String id;
  String title;
  String description;
  String subjectId;
  String subjectName;
  DateTime deadline;
  DateTime? recommendedStartDate;
  TaskStatus status;
  TaskPriority priority;
  TaskType type;
  int? estimatedMinutes; // AI stub: complexity estimate
  int? actualMinutes;
  String? complexityNote; // AI stub
  DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectId,
    required this.subjectName,
    required this.deadline,
    this.recommendedStartDate,
    required this.status,
    required this.priority,
    required this.type,
    this.estimatedMinutes,
    this.actualMinutes,
    this.complexityNote,
    required this.createdAt,
  });

  bool get isOverdue =>
      deadline.isBefore(DateTime.now()) && status != TaskStatus.completed;

  bool get isUrgent =>
      deadline.difference(DateTime.now()).inDays <= 1 &&
      status != TaskStatus.completed;

  bool get isSoon =>
      deadline.difference(DateTime.now()).inDays <= 3 &&
      deadline.difference(DateTime.now()).inDays > 1 &&
      status != TaskStatus.completed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'deadline': deadline.toIso8601String(),
        'recommendedStartDate': recommendedStartDate?.toIso8601String(),
        'status': status.index,
        'priority': priority.index,
        'type': type.index,
        'estimatedMinutes': estimatedMinutes,
        'actualMinutes': actualMinutes,
        'complexityNote': complexityNote,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        subjectId: json['subjectId'],
        subjectName: json['subjectName'],
        deadline: DateTime.parse(json['deadline']),
        recommendedStartDate: json['recommendedStartDate'] != null
            ? DateTime.parse(json['recommendedStartDate'])
            : null,
        status: TaskStatus.values[json['status']],
        priority: TaskPriority.values[json['priority']],
        type: TaskType.values[json['type']],
        estimatedMinutes: json['estimatedMinutes'],
        actualMinutes: json['actualMinutes'],
        complexityNote: json['complexityNote'],
        createdAt: DateTime.parse(json['createdAt']),
      );

  Task copyWith({
    String? title,
    String? description,
    String? subjectId,
    String? subjectName,
    DateTime? deadline,
    DateTime? recommendedStartDate,
    TaskStatus? status,
    TaskPriority? priority,
    TaskType? type,
    int? estimatedMinutes,
    int? actualMinutes,
    String? complexityNote,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        subjectId: subjectId ?? this.subjectId,
        subjectName: subjectName ?? this.subjectName,
        deadline: deadline ?? this.deadline,
        recommendedStartDate: recommendedStartDate ?? this.recommendedStartDate,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        type: type ?? this.type,
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
        actualMinutes: actualMinutes ?? this.actualMinutes,
        complexityNote: complexityNote ?? this.complexityNote,
        createdAt: createdAt,
      );
}

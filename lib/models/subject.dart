class Subject {
  final String id;
  String name;
  String teacher;
  double currentGrade; // 0-100
  double targetGrade;
  int totalTasks;
  int completedTasks;
  String color; // hex color string

  Subject({
    required this.id,
    required this.name,
    required this.teacher,
    required this.currentGrade,
    required this.targetGrade,
    required this.totalTasks,
    required this.completedTasks,
    required this.color,
  });

  double get progress =>
      totalTasks == 0 ? 0 : completedTasks / totalTasks;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'teacher': teacher,
        'currentGrade': currentGrade,
        'targetGrade': targetGrade,
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'color': color,
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'],
        name: json['name'],
        teacher: json['teacher'],
        currentGrade: (json['currentGrade'] as num).toDouble(),
        targetGrade: (json['targetGrade'] as num).toDouble(),
        totalTasks: json['totalTasks'],
        completedTasks: json['completedTasks'],
        color: json['color'],
      );

  Subject copyWith({
    String? name,
    String? teacher,
    double? currentGrade,
    double? targetGrade,
    int? totalTasks,
    int? completedTasks,
    String? color,
  }) =>
      Subject(
        id: id,
        name: name ?? this.name,
        teacher: teacher ?? this.teacher,
        currentGrade: currentGrade ?? this.currentGrade,
        targetGrade: targetGrade ?? this.targetGrade,
        totalTasks: totalTasks ?? this.totalTasks,
        completedTasks: completedTasks ?? this.completedTasks,
        color: color ?? this.color,
      );
}

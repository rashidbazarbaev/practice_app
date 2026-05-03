class Student {
  final String id;
  String name;
  String faculty;
  int course;
  double gpa;
  String? avatarPath;

  Student({
    required this.id,
    required this.name,
    required this.faculty,
    required this.course,
    required this.gpa,
    this.avatarPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'faculty': faculty,
        'course': course,
        'gpa': gpa,
        'avatarPath': avatarPath,
      };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'],
        name: json['name'],
        faculty: json['faculty'],
        course: json['course'],
        gpa: (json['gpa'] as num).toDouble(),
        avatarPath: json['avatarPath'],
      );

  Student copyWith({
    String? name,
    String? faculty,
    int? course,
    double? gpa,
    String? avatarPath,
  }) =>
      Student(
        id: id,
        name: name ?? this.name,
        faculty: faculty ?? this.faculty,
        course: course ?? this.course,
        gpa: gpa ?? this.gpa,
        avatarPath: avatarPath ?? this.avatarPath,
      );
}

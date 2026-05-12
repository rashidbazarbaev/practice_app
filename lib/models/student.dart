class Student {
  final String id;
  String name;
  String faculty;
  int course;
  String? avatarPath;

  Student({
    required this.id,
    required this.name,
    required this.faculty,
    required this.course,
    this.avatarPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'faculty': faculty,
        'course': course,
        'avatarPath': avatarPath,
      };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'],
        name: json['name'],
        faculty: json['faculty'],
        course: json['course'],
        avatarPath: json['avatarPath'],
      );

  Student copyWith({
    String? name,
    String? faculty,
    int? course,
    String? avatarPath,
  }) =>
      Student(
        id: id,
        name: name ?? this.name,
        faculty: faculty ?? this.faculty,
        course: course ?? this.course,
        avatarPath: avatarPath ?? this.avatarPath,
      );
}

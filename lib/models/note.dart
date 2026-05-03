class Note {
  final String id;
  String title;
  String content;
  String subjectId;
  String subjectName;
  DateTime createdAt;
  DateTime updatedAt;
  List<String> tags;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.subjectId,
    required this.subjectName,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'tags': tags,
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        subjectId: json['subjectId'],
        subjectName: json['subjectName'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        tags: List<String>.from(json['tags']),
      );

  Note copyWith({
    String? title,
    String? content,
    String? subjectId,
    String? subjectName,
    List<String>? tags,
  }) =>
      Note(
        id: id,
        title: title ?? this.title,
        content: content ?? this.content,
        subjectId: subjectId ?? this.subjectId,
        subjectName: subjectName ?? this.subjectName,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        tags: tags ?? this.tags,
      );
}

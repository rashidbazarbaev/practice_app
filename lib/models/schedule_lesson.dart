/// Lesson time slots per OMSU schedule.
const Map<int, (String, String)> kLessonTimes = {
  1: ('08:45', '10:20'),
  2: ('10:30', '12:05'),
  3: ('12:45', '14:20'),
  4: ('14:30', '16:05'),
  5: ('16:15', '17:50'),
  6: ('18:00', '19:35'),
};

class ScheduleLesson {
  final String id;
  final String subject;
  final String teacher;
  final String room;
  final String type;
  final DateTime date;
  final String timeStart;
  final String timeEnd;
  final int lessonNumber;
  final String group;
  final String? subgroup;

  ScheduleLesson({
    required this.id,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.type,
    required this.date,
    required this.timeStart,
    required this.timeEnd,
    required this.lessonNumber,
    required this.group,
    this.subgroup,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'teacher': teacher,
        'room': room,
        'type': type,
        'date': date.toIso8601String(),
        'timeStart': timeStart,
        'timeEnd': timeEnd,
        'lessonNumber': lessonNumber,
        'group': group,
        'subgroup': subgroup,
      };

  factory ScheduleLesson.fromJson(Map<String, dynamic> json) => ScheduleLesson(
        id: json['id'] ?? '',
        subject: json['subject'] ?? '',
        teacher: json['teacher'] ?? '',
        room: json['room'] ?? '',
        type: json['type'] ?? '',
        date: DateTime.parse(json['date']),
        timeStart: json['timeStart'] ?? '',
        timeEnd: json['timeEnd'] ?? '',
        lessonNumber: json['lessonNumber'] ?? 0,
        group: json['group'] ?? '',
        subgroup: json['subgroup'],
      );

  /// Parse from OMSU API format:
  /// {
  ///   "id": 43337893,
  ///   "day": "30.12.2025",
  ///   "time": 3,
  ///   "lesson": "Программная инженерия Лек",
  ///   "type_work": "Лек",
  ///   "teacher": "Лейхтер Сергей Владимирович",
  ///   "group": "МИБ-201-О-01",
  ///   "auditCorps": "4-309",
  ///   "subgroupName": null
  /// }
  factory ScheduleLesson.fromOmsuJson(
    Map<String, dynamic> json,
    DateTime date,
    String groupName,
  ) {
    final lessonNum = (json['time'] as num?)?.toInt() ?? 0;
    final times = kLessonTimes[lessonNum] ?? ('', '');

    // type_work is a separate field — use it directly
    final typeWork = (json['type_work'] as String? ?? '').trim();

    // lesson field contains "SubjectName Type" — strip the type suffix if present
    final rawLesson = (json['lesson'] as String? ?? '').trim();
    final subject = typeWork.isNotEmpty && rawLesson.endsWith(typeWork)
        ? rawLesson.substring(0, rawLesson.length - typeWork.length).trim()
        : rawLesson;

    return ScheduleLesson(
      id: '${json['id'] ?? '${date.toIso8601String()}_$lessonNum'}',
      subject: subject.isNotEmpty ? subject : rawLesson,
      teacher: (json['teacher'] as String? ?? '').trim(),
      room: (json['auditCorps'] as String? ?? '').trim(),
      type: typeWork,
      date: date,
      timeStart: times.$1,
      timeEnd: times.$2,
      lessonNumber: lessonNum,
      group: (json['group'] as String? ?? groupName).trim(),
      subgroup: json['subgroupName'] as String?,
    );
  }

  /// Splits "Математика Лек" → ("Математика", "Лек") — kept for potential reuse
  static String stripTypeSuffix(String raw, String type) {
    if (type.isNotEmpty && raw.endsWith(type)) {
      return raw.substring(0, raw.length - type.length).trim();
    }
    return raw;
  }
}

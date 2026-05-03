class ScheduleLesson {
  final String id;
  final String subject;
  final String teacher;
  final String room;
  final String type; // лекция, практика, лаб
  final DateTime date;
  final String timeStart;
  final String timeEnd;
  final int lessonNumber;
  final String group;

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
      );

  /// Parse from OMSU eservice JSON format
  factory ScheduleLesson.fromOmsuJson(
      Map<String, dynamic> json, DateTime date) {
    return ScheduleLesson(
      id: '${date.toIso8601String()}_${json['lessonNumber']}_${json['subject']}',
      subject: _str(json['subject'] ?? json['disc'] ?? json['name'] ?? ''),
      teacher: _str(json['teacher'] ?? json['prep'] ?? ''),
      room: _str(json['room'] ?? json['aud'] ?? ''),
      type: _str(json['type'] ?? json['kindName'] ?? ''),
      date: date,
      timeStart: _str(json['timeStart'] ?? json['beginLesson'] ?? ''),
      timeEnd: _str(json['timeEnd'] ?? json['endLesson'] ?? ''),
      lessonNumber: _int(json['lessonNumber'] ?? json['number'] ?? 0),
      group: _str(json['group'] ?? json['groupName'] ?? ''),
    );
  }

  static String _str(dynamic v) => v?.toString() ?? '';
  static int _int(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}

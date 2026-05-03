import '../models/task.dart';
import '../models/subject.dart';
import '../models/schedule_lesson.dart';

/// Rule-based recommendation engine.
/// Designed so that in the future the rules can be replaced by an ML model
/// or a remote AI API call — just swap out [generateRecommendations].
class RecommendationService {
  List<Recommendation> generateRecommendations({
    required List<Task> tasks,
    required List<Subject> subjects,
    required List<ScheduleLesson> todayLessons,
    required double gpa,
  }) {
    final recs = <Recommendation>[];
    final now = DateTime.now();

    // ── Overdue tasks ─────────────────────────────────────────────────────
    final overdue = tasks.where((t) => t.isOverdue).toList();
    if (overdue.isNotEmpty) {
      recs.add(Recommendation(
        id: 'overdue',
        type: RecommendationType.urgent,
        title: 'Просроченные задачи',
        body:
            'У вас ${overdue.length} просроченных задач. Разберитесь с ними в первую очередь: '
            '${overdue.take(2).map((t) => '"${t.title}"').join(', ')}.',
        priority: 10,
      ));
    }

    // ── Urgent deadlines today/tomorrow ───────────────────────────────────
    final urgent = tasks
        .where((t) =>
            t.status != TaskStatus.completed &&
            t.deadline.difference(now).inHours <= 24 &&
            !t.isOverdue)
        .toList();
    if (urgent.isNotEmpty) {
      recs.add(Recommendation(
        id: 'urgent_today',
        type: RecommendationType.urgent,
        title: 'Дедлайн сегодня',
        body:
            '${urgent.length} задач с дедлайном в ближайшие 24 часа. '
            'Используйте Pomodoro для концентрации.',
        priority: 9,
      ));
    }

    // ── Today's schedule ──────────────────────────────────────────────────
    if (todayLessons.isNotEmpty) {
      final subjects = todayLessons.map((l) => l.subject).toSet();
      recs.add(Recommendation(
        id: 'today_schedule',
        type: RecommendationType.schedule,
        title: 'Занятия сегодня',
        body:
            'Сегодня ${todayLessons.length} занятий: ${subjects.take(3).join(', ')}. '
            'Подготовьте материалы заранее.',
        priority: 8,
      ));
    }

    // ── Low grade subjects ────────────────────────────────────────────────
    final lowGrade = subjects
        .where((s) => s.currentGrade < s.targetGrade - 10)
        .toList()
      ..sort((a, b) =>
          (a.currentGrade - a.targetGrade)
              .compareTo(b.currentGrade - b.targetGrade));
    if (lowGrade.isNotEmpty) {
      final s = lowGrade.first;
      recs.add(Recommendation(
        id: 'low_grade_${s.id}',
        type: RecommendationType.study,
        title: 'Подтяните "${s.name}"',
        body:
            'Текущий балл ${s.currentGrade.toInt()}%, цель ${s.targetGrade.toInt()}%. '
            'Уделите этому предмету больше времени.',
        priority: 7,
      ));
    }

    // ── Productivity tip ──────────────────────────────────────────────────
    final completedToday = tasks
        .where((t) =>
            t.status == TaskStatus.completed &&
            t.createdAt.day == now.day)
        .length;
    if (completedToday > 0) {
      recs.add(Recommendation(
        id: 'productivity',
        type: RecommendationType.positive,
        title: 'Отличная работа!',
        body:
            'Сегодня вы выполнили $completedToday задач. '
            'Продолжайте в том же темпе!',
        priority: 3,
      ));
    }

    // ── GPA tip ───────────────────────────────────────────────────────────
    if (gpa < 3.5) {
      recs.add(Recommendation(
        id: 'gpa_low',
        type: RecommendationType.study,
        title: 'Повысьте GPA',
        body:
            'Ваш GPA ${gpa.toStringAsFixed(1)}. Сосредоточьтесь на предметах '
            'с наибольшим отставанием от цели.',
        priority: 6,
      ));
    } else if (gpa >= 4.5) {
      recs.add(Recommendation(
        id: 'gpa_high',
        type: RecommendationType.positive,
        title: 'Высокий GPA',
        body:
            'GPA ${gpa.toStringAsFixed(1)} — отличный результат! '
            'Поддерживайте текущий темп.',
        priority: 2,
      ));
    }

    // ── Study time tip ────────────────────────────────────────────────────
    final hour = now.hour;
    if (hour >= 9 && hour < 12) {
      recs.add(Recommendation(
        id: 'morning_tip',
        type: RecommendationType.tip,
        title: 'Утреннее время',
        body:
            'Сейчас оптимальное время для сложных задач. '
            'Мозг наиболее продуктивен с 9 до 12.',
        priority: 1,
      ));
    } else if (hour >= 20) {
      recs.add(Recommendation(
        id: 'evening_tip',
        type: RecommendationType.tip,
        title: 'Вечерний режим',
        body:
            'Вечером лучше повторять пройденный материал, '
            'а не изучать новое. Не забудьте отдохнуть.',
        priority: 1,
      ));
    }

    // Sort by priority descending, take top 5
    recs.sort((a, b) => b.priority.compareTo(a.priority));
    return recs.take(5).toList();
  }
}

enum RecommendationType { urgent, schedule, study, positive, tip }

class Recommendation {
  final String id;
  final RecommendationType type;
  final String title;
  final String body;
  final int priority; // higher = more important

  const Recommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.priority,
  });

  int get iconCodePoint {
    switch (type) {
      case RecommendationType.urgent:
        return 0xe002;
      case RecommendationType.schedule:
        return 0xe0ed;
      case RecommendationType.study:
        return 0xe80c;
      case RecommendationType.positive:
        return 0xe838;
      case RecommendationType.tip:
        return 0xe90f;
    }
  }

  int get colorValue {
    switch (type) {
      case RecommendationType.urgent:
        return 0xFFF44336;
      case RecommendationType.schedule:
        return 0xFF2196F3;
      case RecommendationType.study:
        return 0xFFFF9800;
      case RecommendationType.positive:
        return 0xFF4CAF50;
      case RecommendationType.tip:
        return 0xFF9C27B0;
    }
  }
}

// ignore_for_file: unused_element

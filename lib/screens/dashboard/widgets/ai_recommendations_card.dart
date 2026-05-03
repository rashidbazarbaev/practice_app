import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/student_provider.dart';
import '../../../providers/schedule_provider.dart';
import '../../../services/recommendation_service.dart';

class AiRecommendationsCard extends StatelessWidget {
  const AiRecommendationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    final studentProv = context.watch<StudentProvider>();
    final scheduleProv = context.watch<ScheduleProvider>();
    final theme = Theme.of(context);

    final recs = RecommendationService().generateRecommendations(
      tasks: taskProv.tasks,
      subjects: studentProv.subjects,
      todayLessons: scheduleProv.todayLessons,
      gpa: studentProv.student?.gpa ?? 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Рекомендации',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Smart',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Всё под контролем! Нет срочных рекомендаций.',
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
              )
            else
              ...recs.map((r) => _RecommendationItem(rec: r)),
          ],
        ),
      ),
    );
  }
}

class _RecommendationItem extends StatelessWidget {
  final Recommendation rec;

  const _RecommendationItem({required this.rec});

  @override
  Widget build(BuildContext context) {
    final color = Color(rec.colorValue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_iconData(rec.type), size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  rec.body,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconData(RecommendationType type) {
    switch (type) {
      case RecommendationType.urgent:
        return Icons.warning_amber_outlined;
      case RecommendationType.schedule:
        return Icons.schedule_outlined;
      case RecommendationType.study:
        return Icons.school_outlined;
      case RecommendationType.positive:
        return Icons.star_outline;
      case RecommendationType.tip:
        return Icons.lightbulb_outline;
    }
  }
}

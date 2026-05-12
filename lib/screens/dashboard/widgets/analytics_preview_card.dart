import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/student_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../utils/color_utils.dart';

class AnalyticsPreviewCard extends StatelessWidget {
  const AnalyticsPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<StudentProvider>().subjects;
    final taskProv = context.watch<TaskProvider>();
    final theme = Theme.of(context);

    final weeklyDone = taskProv.completedPerWeekday.reduce((a, b) => a + b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Успеваемость',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (subjects.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${subjects.length} предм.',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (subjects.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Добавьте предметы, чтобы увидеть аналитику',
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
              )
            else
              // Show up to 4 subjects sorted by gap (worst first)
              ...([...subjects]
                    ..sort((a, b) =>
                        (a.currentGrade - a.targetGrade)
                            .compareTo(b.currentGrade - b.targetGrade)))
                  .take(4)
                  .map((s) => _SubjectBar(subject: s)),

            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 12, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  'Выполнено задач на этой неделе: $weeklyDone',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectBar extends StatelessWidget {
  final dynamic subject;

  const _SubjectBar({required this.subject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ColorUtils.fromHex(subject.color as String);
    final current = (subject.currentGrade as double).clamp(0.0, 100.0);
    final target = (subject.targetGrade as double).clamp(0.0, 100.0);
    final gap = target - current;
    final isOnTarget = gap <= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject.name as String,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${current.toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isOnTarget ? const Color(0xFF4CAF50) : color,
                ),
              ),
              if (!isOnTarget) ...[
                const SizedBox(width: 4),
                Text(
                  '/ ${target.toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final w = constraints.maxWidth;
              return Stack(
                children: [
                  // Target bar (background)
                  Container(
                    height: 7,
                    width: w * (target / 100),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Current bar (foreground)
                  Container(
                    height: 7,
                    width: w * (current / 100),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class GpaCard extends StatelessWidget {
  final double gpa;
  final int completedTasks;
  final int totalTasks;
  final int overdueTasks;

  const GpaCard({
    super.key,
    required this.gpa,
    required this.completedTasks,
    required this.totalTasks,
    required this.overdueTasks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // GPA circle
            _GpaCircle(gpa: gpa),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Средний балл',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatItem(
                        label: 'Выполнено',
                        value: '$completedTasks/$totalTasks',
                        color: const Color(0xFF4CAF50),
                        icon: Icons.check_circle_outline,
                      ),
                      const SizedBox(width: 16),
                      _StatItem(
                        label: 'Просрочено',
                        value: '$overdueTasks',
                        color: const Color(0xFFF44336),
                        icon: Icons.warning_amber_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GpaCircle extends StatelessWidget {
  final double gpa;

  const _GpaCircle({required this.gpa});

  Color get _color {
    if (gpa >= 4.5) return const Color(0xFF4CAF50);
    if (gpa >= 3.5) return const Color(0xFF2196F3);
    if (gpa >= 2.5) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _color, width: 4),
        color: _color.withOpacity(0.1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              gpa.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _color,
              ),
            ),
            Text(
              'GPA',
              style: TextStyle(
                fontSize: 11,
                color: _color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

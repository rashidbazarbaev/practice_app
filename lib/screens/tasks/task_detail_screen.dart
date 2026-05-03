import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';
import '../../utils/color_utils.dart';
import '../../utils/label_utils.dart';
import '../../utils/date_utils.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final taskProv = context.read<TaskProvider>();
    final theme = Theme.of(context);
    final priorityColor = ColorUtils.taskPriorityColor(task.priority);
    final statusColor = ColorUtils.taskStatusColor(task.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задача'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => TaskFormScreen(task: task)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          LabelUtils.taskStatus(task.status),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          LabelUtils.taskPriority(task.priority),
                          style: TextStyle(
                            color: priorityColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          LabelUtils.taskType(task.type),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    task.title,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.subjectName,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(task.description),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Dates card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.event,
                    label: 'Дедлайн',
                    value: AppDateUtils.formatDateTime(task.deadline),
                    valueColor:
                        ColorUtils.deadlineColor(task.deadline, task.status),
                  ),
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.play_circle_outline,
                    label: 'Рекомендуемое начало',
                    value: task.recommendedStartDate != null
                        ? AppDateUtils.formatDate(task.recommendedStartDate!)
                        : 'Не указано',
                  ),
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.add_circle_outline,
                    label: 'Создано',
                    value: AppDateUtils.formatDate(task.createdAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // AI stub card
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: theme.colorScheme.onSecondaryContainer,
                          size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'AI-анализ (заглушка)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.timer_outlined,
                    label: 'Оценка времени',
                    value: task.estimatedMinutes != null
                        ? '~${task.estimatedMinutes} мин'
                        : 'Не оценено',
                  ),
                  const Divider(height: 16),
                  _InfoRow(
                    icon: Icons.psychology_outlined,
                    label: 'Сложность',
                    value: task.complexityNote ?? 'Не оценено',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          if (task.status != TaskStatus.completed)
            FilledButton.icon(
              onPressed: () {
                taskProv.completeTask(task.id);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Отметить выполненным'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF4CAF50),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => TaskFormScreen(task: task)),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Редактировать'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/task_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/task.dart';
import '../../models/subject.dart';
import '../../utils/color_utils.dart';
import '../subjects/subject_form_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    final studentProv = context.watch<StudentProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryRow(taskProv: taskProv),
          const SizedBox(height: 16),
          _SubjectProgressCard(subjects: studentProv.subjects),
          const SizedBox(height: 16),
          _TaskDistributionCard(tasks: taskProv.tasks),
          const SizedBox(height: 16),
          _WeeklyActivityCard(tasks: taskProv.tasks),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final TaskProvider taskProv;

  const _SummaryRow({required this.taskProv});

  @override
  Widget build(BuildContext context) {
    final completionRate = taskProv.totalCount == 0
        ? 0.0
        : taskProv.completedCount / taskProv.totalCount;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Выполнено',
            value: '${taskProv.completedCount}',
            subtitle: 'задач',
            color: const Color(0xFF4CAF50),
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Всего',
            value: '${taskProv.totalCount}',
            subtitle: 'задач',
            color: const Color(0xFF2196F3),
            icon: Icons.assignment_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Выполнения',
            value: '${(completionRate * 100).toInt()}%',
            subtitle: 'процент',
            color: const Color(0xFFFF9800),
            icon: Icons.pie_chart_outline,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectProgressCard extends StatelessWidget {
  final List<Subject> subjects;

  const _SubjectProgressCard({required this.subjects});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (subjects.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.school_outlined, color: theme.colorScheme.outline),
              const SizedBox(width: 12),
              Text(
                'Нет предметов',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = [...subjects]
      ..sort((a, b) =>
          (a.currentGrade - a.targetGrade)
              .compareTo(b.currentGrade - b.targetGrade));

    final avg = subjects.fold<double>(
            0, (s, e) => s + e.currentGrade) /
        subjects.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Прогресс по предметам',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Ср. ${avg.toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sorted.map((s) => _SubjectBar(subject: s)),
          ],
        ),
      ),
    );
  }
}

class _SubjectBar extends StatelessWidget {
  final Subject subject;

  const _SubjectBar({required this.subject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ColorUtils.fromHex(subject.color);
    final progress = subject.currentGrade.clamp(0.0, 100.0);
    final isDone = progress >= 100;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubjectFormScreen(subject: subject),
        ),
      ),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                subject.name,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 10,
                  backgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDone ? const Color(0xFF4CAF50) : color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 42,
              child: Text(
                isDone ? 'Сдан' : '${progress.toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDone ? const Color(0xFF4CAF50) : color,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskDistributionCard extends StatelessWidget {
  final List<Task> tasks;

  const _TaskDistributionCard({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final counts = {
      TaskStatus.completed: 0,
      TaskStatus.inProgress: 0,
      TaskStatus.pending: 0,
      TaskStatus.overdue: 0,
    };
    for (final t in tasks) {
      counts[t.status] = (counts[t.status] ?? 0) + 1;
    }

    final total = tasks.length;
    if (total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Нет данных')),
        ),
      );
    }

    final sections = [
      PieChartSectionData(
        value: counts[TaskStatus.completed]!.toDouble(),
        color: const Color(0xFF4CAF50),
        title: '${counts[TaskStatus.completed]}',
        radius: 50,
        titleStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        value: counts[TaskStatus.inProgress]!.toDouble(),
        color: const Color(0xFF2196F3),
        title: '${counts[TaskStatus.inProgress]}',
        radius: 50,
        titleStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        value: counts[TaskStatus.pending]!.toDouble(),
        color: const Color(0xFFFF9800),
        title: '${counts[TaskStatus.pending]}',
        radius: 50,
        titleStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        value: counts[TaskStatus.overdue]!.toDouble(),
        color: const Color(0xFFF44336),
        title: '${counts[TaskStatus.overdue]}',
        radius: 50,
        titleStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ].where((s) => s.value > 0).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Распределение задач',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 35,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PieLegend(
                          color: const Color(0xFF4CAF50),
                          label: 'Выполнено',
                          count: counts[TaskStatus.completed]!),
                      _PieLegend(
                          color: const Color(0xFF2196F3),
                          label: 'В процессе',
                          count: counts[TaskStatus.inProgress]!),
                      _PieLegend(
                          color: const Color(0xFFFF9800),
                          label: 'Ожидает',
                          count: counts[TaskStatus.pending]!),
                      _PieLegend(
                          color: const Color(0xFFF44336),
                          label: 'Просрочено',
                          count: counts[TaskStatus.overdue]!),
                    ],
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

class _PieLegend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _PieLegend(
      {required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyActivityCard extends StatelessWidget {
  final List<Task> tasks;

  const _WeeklyActivityCard({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProv = context.read<TaskProvider>();
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    // Real data: completed tasks per weekday of current week
    final counts = taskProv.completedPerWeekday;
    final maxY = counts.reduce((a, b) => a > b ? a : b).toDouble();
    final chartMax = maxY < 3 ? 5.0 : maxY + 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Активность за неделю',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: chartMax,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem(
                        '${counts[group.x]} задач',
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= days.length) {
                            return const SizedBox.shrink();
                          }
                          // Highlight today
                          final todayIndex =
                              DateTime.now().weekday - 1; // 0=Mon
                          return Text(
                            days[i],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: i == todayIndex
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: i == todayIndex
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    7,
                    (i) {
                      final todayIndex = DateTime.now().weekday - 1;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: counts[i].toDouble(),
                            color: i == todayIndex
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary
                                    .withValues(alpha: 0.5),
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

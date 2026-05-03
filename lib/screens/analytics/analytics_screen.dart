import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/task_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../models/task.dart';
import '../../utils/color_utils.dart';
import '../../utils/label_utils.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    final studentProv = context.watch<StudentProvider>();
    final pomodoroProv = context.watch<PomodoroProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary stats
          _SummaryRow(
            taskProv: taskProv,
            pomodoroMinutes: pomodoroProv.totalMinutesStudied,
          ),
          const SizedBox(height: 16),

          // Grade chart
          _GradeChart(subjects: studentProv.subjects),
          const SizedBox(height: 16),

          // Task distribution pie
          _TaskDistributionCard(tasks: taskProv.tasks),
          const SizedBox(height: 16),

          // Weekly activity
          _WeeklyActivityCard(tasks: taskProv.tasks),
          const SizedBox(height: 16),

          // Subject performance
          _SubjectPerformanceCard(subjects: studentProv.subjects),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final TaskProvider taskProv;
  final int pomodoroMinutes;

  const _SummaryRow(
      {required this.taskProv, required this.pomodoroMinutes});

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
            label: 'Процент',
            value: '${(completionRate * 100).toInt()}%',
            subtitle: 'выполнения',
            color: const Color(0xFF2196F3),
            icon: Icons.pie_chart_outline,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Pomodoro',
            value: '${pomodoroMinutes ~/ 60}ч',
            subtitle: '${pomodoroMinutes % 60}мин',
            color: const Color(0xFFFF5722),
            icon: Icons.timer_outlined,
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

class _GradeChart extends StatelessWidget {
  final List subjects;

  const _GradeChart({required this.subjects});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mock monthly grade data
    final mockData = [
      [68.0, 72.0, 75.0, 78.0, 80.0, 83.0],
      [85.0, 87.0, 88.0, 90.0, 91.0, 92.0],
      [55.0, 58.0, 62.0, 63.0, 65.0, 65.0],
    ];

    final colors = [
      theme.colorScheme.primary,
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
    ];

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
                  'Успеваемость по месяцам',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Mock данные',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 20,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.outline),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          const months = [
                            'Сен',
                            'Окт',
                            'Ноя',
                            'Дек',
                            'Янв',
                            'Фев'
                          ];
                          final i = v.toInt();
                          if (i < 0 || i >= months.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(months[i],
                              style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.outline));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 5,
                  minY: 40,
                  maxY: 100,
                  lineBarsData: List.generate(
                    mockData.length,
                    (i) => LineChartBarData(
                      spots: List.generate(
                        mockData[i].length,
                        (j) => FlSpot(j.toDouble(), mockData[i][j]),
                      ),
                      isCurved: true,
                      color: colors[i],
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colors[i].withOpacity(0.05),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 3,
                        color: colors[i],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        i < subjects.length
                            ? (subjects[i].name as String)
                                .split(' ')
                                .first
                            : 'Предмет ${i + 1}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
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
    // Mock weekly completed tasks data
    final data = [2.0, 1.0, 3.0, 0.0, 2.0, 4.0, 1.0];
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

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
                  maxY: 5,
                  barTouchData: BarTouchData(enabled: false),
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
                        getTitlesWidget: (v, _) => Text(
                          days[v.toInt()],
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.outline),
                        ),
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    7,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data[i],
                          color: theme.colorScheme.primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    ),
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

class _SubjectPerformanceCard extends StatelessWidget {
  final List subjects;

  const _SubjectPerformanceCard({required this.subjects});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Успеваемость по предметам',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...subjects.map((s) {
              final color = ColorUtils.fromHex(s.color as String);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            s.name as String,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(s.currentGrade as double).toInt()} / ${(s.targetGrade as double).toInt()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (s.targetGrade as double) / 100,
                            backgroundColor: color.withOpacity(0.1),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(color.withOpacity(0.3)),
                            minHeight: 8,
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (s.currentGrade as double) / 100,
                            backgroundColor: Colors.transparent,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(color),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/schedule_lesson.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _groupCtrl = TextEditingController();
  bool _groupSet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<ScheduleProvider>();
      if (prov.group.isNotEmpty) {
        _groupCtrl.text = prov.group;
        _groupSet = true;
      }
    });
  }

  @override
  void dispose() {
    _groupCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ScheduleProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Расписание'),
        actions: [
          if (prov.hasData)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Обновить',
              onPressed: prov.isLoading ? null : prov.refresh,
            ),
        ],
      ),
      body: Column(
        children: [
          // Group input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _groupCtrl,
                    decoration: InputDecoration(
                      hintText: 'Номер группы (напр. ПИ-201)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      prefixIcon: const Icon(Icons.group_outlined),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _loadSchedule(prov),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: prov.isLoading ? null : () => _loadSchedule(prov),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(56, 52),
                    padding: EdgeInsets.zero,
                  ),
                  child: prov.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
          ),

          // Week navigation
          if (prov.hasData || prov.group.isNotEmpty)
            _WeekNavigator(prov: prov),

          // Status bar
          if (prov.lastUpdated != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.update,
                      size: 12, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    'Обновлено: ${DateFormat('dd.MM HH:mm').format(prov.lastUpdated!)}',
                    style: TextStyle(
                        fontSize: 11, color: theme.colorScheme.outline),
                  ),
                  if (prov.loadState == ScheduleLoadState.cached) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Кэш',
                        style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.outline),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          const Divider(height: 1),

          // Content
          Expanded(child: _buildContent(context, prov)),
        ],
      ),
    );
  }

  void _loadSchedule(ScheduleProvider prov) {
    final group = _groupCtrl.text.trim();
    if (group.isEmpty) return;
    setState(() => _groupSet = true);
    prov.loadSchedule(group: group, weekOffset: prov.weekOffset);
  }

  void _loadDemo(ScheduleProvider prov) {
    prov.loadDemoSchedule(_groupCtrl.text.trim().isNotEmpty
        ? _groupCtrl.text.trim()
        : 'Демо-группа');
    setState(() => _groupSet = true);
  }

  Widget _buildContent(BuildContext context, ScheduleProvider prov) {
    final theme = Theme.of(context);

    if (!_groupSet && prov.group.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Введите номер группы\nдля загрузки расписания',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 8),
            Text(
              'Данные загружаются с сайта ОМГУ\neservice.omsu.ru',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: theme.colorScheme.outline),
            ),
          ],
        ),
      );
    }

    if (prov.isLoading && !prov.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (prov.loadState == ScheduleLoadState.error && !prov.hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_outlined,
                  size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'Сайт ОМГУ недоступен',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                prov.errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Сайт eservice.omsu.ru блокирует прямые запросы из мобильных приложений. '
                  'Для получения расписания необходим прокси-сервер или официальный API.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.tonal(
                    onPressed: prov.refresh,
                    child: const Text('Повторить'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => _loadDemo(prov),
                    child: const Text('Демо-данные'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (!prov.hasData) {
      return Center(
        child: Text(
          'Нет данных для группы "${prov.group}"',
          style: TextStyle(color: theme.colorScheme.outline),
        ),
      );
    }

    final byDay = prov.lessonsByDay;
    final days = byDay.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: days.length,
      itemBuilder: (ctx, i) {
        final day = days[i];
        final lessons = byDay[day]!;
        return _DayCard(day: day, lessons: lessons);
      },
    );
  }
}

class _WeekNavigator extends StatelessWidget {
  final ScheduleProvider prov;

  const _WeekNavigator({required this.prov});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final label = prov.weekOffset == 0
        ? 'Текущая неделя'
        : prov.weekOffset == 1
            ? 'Следующая неделя'
            : prov.weekOffset == -1
                ? 'Прошлая неделя'
                : DateFormat('dd.MM').format(
                    now.add(Duration(days: prov.weekOffset * 7 - now.weekday + 1)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton.outlined(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => prov.changeWeek(prov.weekOffset - 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: prov.weekOffset == 0
                    ? theme.colorScheme.primary
                    : null,
              ),
            ),
          ),
          IconButton.outlined(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => prov.changeWeek(prov.weekOffset + 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          if (prov.weekOffset != 0) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => prov.changeWeek(0),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
              child: const Text('Сегодня'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DateTime day;
  final List<ScheduleLesson> lessons;

  const _DayCard({required this.day, required this.lessons});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isToday(day);
    final dayName = DateFormat('EEEE, d MMMM', 'ru').format(day);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isToday
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(
                  dayName[0].toUpperCase() + dayName.substring(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isToday
                        ? theme.colorScheme.onPrimaryContainer
                        : null,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Сегодня',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${lessons.length} занятий',
                  style: TextStyle(
                    fontSize: 12,
                    color: isToday
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),

          // Lessons
          ...lessons.asMap().entries.map((e) {
            final isLast = e.key == lessons.length - 1;
            return Column(
              children: [
                _LessonTile(lesson: e.value),
                if (!isLast)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
  }
}

class _LessonTile extends StatelessWidget {
  final ScheduleLesson lesson;

  const _LessonTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProv = context.read<TaskProvider>();
    final scheduleProv = context.read<ScheduleProvider>();

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            lesson.timeStart,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            lesson.timeEnd,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
      title: Text(
        lesson.subject,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lesson.teacher.isNotEmpty)
            Text(
              lesson.teacher,
              style: TextStyle(
                  fontSize: 12, color: theme.colorScheme.outline),
            ),
          Row(
            children: [
              if (lesson.room.isNotEmpty) ...[
                Icon(Icons.room_outlined,
                    size: 12, color: theme.colorScheme.outline),
                const SizedBox(width: 2),
                Text(
                  lesson.room,
                  style: TextStyle(
                      fontSize: 11, color: theme.colorScheme.outline),
                ),
                const SizedBox(width: 8),
              ],
              if (lesson.type.isNotEmpty)
                _TypeChip(type: lesson.type),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add_task_outlined, size: 20),
        tooltip: 'Создать задачу',
        onPressed: () {
          final suggested = scheduleProv.buildSuggestedTask(
            lesson: lesson,
            taskId: taskProv.newTaskId(),
          );
          if (suggested != null) {
            taskProv.addTask(suggested);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Задача "${suggested.title}" добавлена'),
                action: SnackBarAction(
                  label: 'Отмена',
                  onPressed: () => taskProv.deleteTask(suggested.id),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;

  const _TypeChip({required this.type});

  Color _color(BuildContext context) {
    final t = type.toLowerCase();
    if (t.contains('лек')) return const Color(0xFF2196F3);
    if (t.contains('прак') || t.contains('сем')) return const Color(0xFF4CAF50);
    if (t.contains('лаб')) return const Color(0xFFFF9800);
    return Theme.of(context).colorScheme.outline;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

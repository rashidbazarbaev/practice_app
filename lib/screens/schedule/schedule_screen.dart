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
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<ScheduleProvider>();
      if (prov.group.isNotEmpty) {
        _groupCtrl.text = prov.group;
      } else {
        prov.restoreLastGroup().then((_) {
          if (mounted && prov.group.isNotEmpty) {
            setState(() => _groupCtrl.text = prov.group);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _groupCtrl.dispose();
    super.dispose();
  }

  Future<void> _onGroupChanged(String value) async {
    if (value.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    final suggestions =
        await context.read<ScheduleProvider>().getGroupSuggestions(value);
    if (mounted) {
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });
    }
  }

  void _selectSuggestion(String name) {
    _groupCtrl.text = name;
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
    _loadSchedule();
  }

  void _loadSchedule() {
    final group = _groupCtrl.text.trim();
    if (group.isEmpty) return;
    setState(() => _showSuggestions = false);
    context.read<ScheduleProvider>().loadSchedule(group: group);
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
          // ── Group input ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _groupCtrl,
                        decoration: InputDecoration(
                          hintText: 'Номер группы (напр. МПБ-501-О-03)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          prefixIcon: const Icon(Icons.group_outlined),
                          suffixIcon: _groupCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _groupCtrl.clear();
                                    setState(() {
                                      _suggestions = [];
                                      _showSuggestions = false;
                                    });
                                  },
                                )
                              : null,
                        ),
                        textInputAction: TextInputAction.search,
                        onChanged: _onGroupChanged,
                        onSubmitted: (_) => _loadSchedule(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: prov.isLoading ? null : _loadSchedule,
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
                // Suggestions dropdown
                if (_showSuggestions)
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(top: 4, right: 64),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: theme.colorScheme.outlineVariant),
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _suggestions.length,
                        itemBuilder: (ctx, i) => InkWell(
                          onTap: () => _selectSuggestion(_suggestions[i]),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Text(_suggestions[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Status bar ───────────────────────────────────────────────────
          if (prov.lastUpdated != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

          // ── Content ──────────────────────────────────────────────────────
          Expanded(child: _buildContent(context, prov)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ScheduleProvider prov) {
    final theme = Theme.of(context);

    if (prov.group.isEmpty) {
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
              'Данные загружаются с сайта ОМГУ',
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
                'Не удалось загрузить расписание',
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
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: prov.refresh,
                child: const Text('Повторить'),
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

    return _WeekTabView(lessons: prov.lessons);
  }
}

// ── Week tab view ─────────────────────────────────────────────────────────────

class _WeekTabView extends StatefulWidget {
  final List<ScheduleLesson> lessons;

  const _WeekTabView({required this.lessons});

  @override
  State<_WeekTabView> createState() => _WeekTabViewState();
}

class _WeekTabViewState extends State<_WeekTabView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late List<_WeekData> _weeks;
  late int _initialIndex;

  @override
  void initState() {
    super.initState();
    _buildWeeks();
    _tabController = TabController(
      length: _weeks.length,
      vsync: this,
      initialIndex: _initialIndex,
    );
  }

  @override
  void didUpdateWidget(_WeekTabView old) {
    super.didUpdateWidget(old);
    if (old.lessons != widget.lessons) {
      final prevIndex = _tabController.index;
      _tabController.dispose();
      _buildWeeks();
      // Try to keep the same week if possible, else use initial
      final newIndex =
          prevIndex < _weeks.length ? prevIndex : _initialIndex;
      _tabController = TabController(
        length: _weeks.length,
        vsync: this,
        initialIndex: newIndex,
      );
    }
  }

  void _buildWeeks() {
    // Group lessons by ISO week (Monday-based)
    final byWeek = <DateTime, List<ScheduleLesson>>{};
    for (final l in widget.lessons) {
      final monday = _mondayOf(l.date);
      byWeek.putIfAbsent(monday, () => []).add(l);
    }

    final sortedMondays = byWeek.keys.toList()..sort();
    _weeks = sortedMondays
        .map((m) => _WeekData(monday: m, lessons: byWeek[m]!))
        .toList();

    // Find the week that contains today
    final todayMonday = _mondayOf(DateTime.now());
    _initialIndex = _weeks.indexWhere((w) => w.monday == todayMonday);
    if (_initialIndex < 0) {
      // No exact match — find the nearest future week
      _initialIndex = _weeks.indexWhere((w) => !w.monday.isBefore(todayMonday));
      if (_initialIndex < 0) _initialIndex = _weeks.length - 1;
    }
    _initialIndex = _initialIndex.clamp(0, _weeks.isEmpty ? 0 : _weeks.length - 1);
  }

  DateTime _mondayOf(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_weeks.isEmpty) {
      return Center(
        child: Text(
          'Нет занятий',
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      );
    }

    return Column(
      children: [
        // Week tabs
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _weeks.map((w) => _WeekTab(week: w)).toList(),
          labelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          indicatorSize: TabBarIndicatorSize.tab,
        ),
        const Divider(height: 1),
        // Week content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _weeks
                .map((w) => _WeekPage(week: w))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _WeekTab extends StatelessWidget {
  final _WeekData week;

  const _WeekTab({required this.week});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayMonday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final isCurrentWeek = week.monday == todayMonday;
    final sunday = week.monday.add(const Duration(days: 6));
    final label = isCurrentWeek
        ? 'Эта неделя'
        : '${DateFormat('d MMM', 'ru').format(week.monday)} – '
            '${DateFormat('d MMM', 'ru').format(sunday)}';

    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (isCurrentWeek)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Week page ─────────────────────────────────────────────────────────────────

class _WeekPage extends StatefulWidget {
  final _WeekData week;

  const _WeekPage({required this.week});

  @override
  State<_WeekPage> createState() => _WeekPageState();
}

class _WeekPageState extends State<_WeekPage>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  void _scrollToToday() {
    // Find today's index in the sorted days list
    final now = DateTime.now();
    final today =
        DateTime(now.year, now.month, now.day);
    final byDay = _groupByDay(widget.week.lessons);
    final days = byDay.keys.toList()..sort();
    final todayIdx = days.indexWhere((d) => d == today);
    if (todayIdx <= 0) return;

    // Approximate scroll offset: each day card ~120px + header ~44px
    // We just scroll to a rough position; exact would need GlobalKeys
    const cardHeight = 180.0;
    final offset = todayIdx * cardHeight;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  Map<DateTime, List<ScheduleLesson>> _groupByDay(
      List<ScheduleLesson> lessons) {
    final map = <DateTime, List<ScheduleLesson>>{};
    for (final l in lessons) {
      final day = DateTime(l.date.year, l.date.month, l.date.day);
      map.putIfAbsent(day, () => []).add(l);
    }
    return map;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final byDay = _groupByDay(widget.week.lessons);
    final days = byDay.keys.toList()..sort();

    if (days.isEmpty) {
      return Center(
        child: Text(
          'Нет занятий на этой неделе',
          style: TextStyle(
              color: Theme.of(context).colorScheme.outline),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
      itemCount: days.length,
      itemBuilder: (ctx, i) {
        final day = days[i];
        return _DayCard(day: day, lessons: byDay[day]!);
      },
    );
  }
}

// ── Day card ──────────────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final DateTime day;
  final List<ScheduleLesson> lessons;

  const _DayCard({required this.day, required this.lessons});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = day == today;
    final isPast = day.isBefore(today);
    final dayName = DateFormat('EEEE, d MMMM', 'ru').format(day);

    return Opacity(
      opacity: isPast && !isToday ? 0.55 : 1.0,
      child: Card(
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
                  Expanded(
                    child: Text(
                      dayName[0].toUpperCase() + dayName.substring(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? theme.colorScheme.onPrimaryContainer
                            : null,
                      ),
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
                  const SizedBox(width: 8),
                  Text(
                    '${lessons.length} ${_lessonWord(lessons.length)}',
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
                    const Divider(height: 1, indent: 72, endIndent: 16),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _lessonWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'занятие';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
      return 'занятия';
    }
    return 'занятий';
  }
}

// ── Lesson tile ───────────────────────────────────────────────────────────────

class _LessonTile extends StatelessWidget {
  final ScheduleLesson lesson;

  const _LessonTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProv = context.read<TaskProvider>();
    final scheduleProv = context.read<ScheduleProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column — fixed width, no overflow
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (lesson.lessonNumber > 0)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${lesson.lessonNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                if (lesson.timeStart.isNotEmpty)
                  Text(
                    lesson.timeStart,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                if (lesson.timeEnd.isNotEmpty)
                  Text(
                    lesson.timeEnd,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.subject,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                if (lesson.teacher.isNotEmpty)
                  Text(
                    lesson.teacher,
                    style: TextStyle(
                        fontSize: 12, color: theme.colorScheme.outline),
                  ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (lesson.room.isNotEmpty)
                      _InfoChip(
                        icon: Icons.room_outlined,
                        label: lesson.room,
                        color: theme.colorScheme.outline,
                      ),
                    if (lesson.type.isNotEmpty)
                      _TypeChip(type: lesson.type),
                    if (lesson.subgroup != null &&
                        lesson.subgroup!.isNotEmpty)
                      _TypeChip(
                        type: lesson.subgroup!,
                        baseColor: const Color(0xFF9C27B0),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Add task button
          IconButton(
            icon: Icon(Icons.add_task_outlined,
                size: 20, color: theme.colorScheme.outline),
            tooltip: 'Создать задачу',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Занятие уже прошло — задача не создана')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── Chips ─────────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 2),
        Text(label,
            style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;
  final Color? baseColor;

  const _TypeChip({required this.type, this.baseColor});

  Color _color(BuildContext context) {
    if (baseColor != null) return baseColor!;
    final t = type.toLowerCase();
    if (t.contains('лек')) return const Color(0xFF2196F3);
    if (t.contains('прак') || t.contains('сем')) return const Color(0xFF4CAF50);
    if (t.contains('лаб')) return const Color(0xFFFF9800);
    if (t.contains('зач') || t.contains('экз')) return const Color(0xFFF44336);
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

// ── Data class ────────────────────────────────────────────────────────────────

class _WeekData {
  final DateTime monday;
  final List<ScheduleLesson> lessons;

  _WeekData({required this.monday, required this.lessons});
}

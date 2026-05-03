import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/pomodoro_session.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pomodoro'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Таймер'),
              Tab(text: 'История'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PomodoroTimer(),
            _PomodoroHistory(),
          ],
        ),
      ),
    );
  }
}

class _PomodoroTimer extends StatelessWidget {
  const _PomodoroTimer();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PomodoroProvider>();
    final taskProv = context.watch<TaskProvider>();
    final theme = Theme.of(context);

    final stateColor = _stateColor(prov.state);
    final stateLabel = _stateLabel(prov.state);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // State label
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: stateColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              stateLabel,
              style: TextStyle(
                color: stateColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Timer circle
          _TimerCircle(
            progress: _progress(prov),
            timeText: prov.formattedTime,
            color: stateColor,
          ),
          const SizedBox(height: 32),

          // Session dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              prov.sessionsBeforeLongBreak,
              (i) => Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < (prov.completedSessions %
                          prov.sessionsBeforeLongBreak)
                      ? stateColor
                      : stateColor.withOpacity(0.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Сессий выполнено: ${prov.completedSessions}',
            style: TextStyle(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 32),

          // Task selector
          if (prov.currentTaskTitle != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.task_alt),
                title: Text(
                  prov.currentTaskTitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: const Text('Текущая задача'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => prov.setTask(null, null),
                ),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _selectTask(context, taskProv, prov),
              icon: const Icon(Icons.add_task),
              label: const Text('Привязать задачу'),
            ),
          const SizedBox(height: 24),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reset
              IconButton.outlined(
                onPressed: prov.reset,
                icon: const Icon(Icons.refresh),
                iconSize: 28,
              ),
              const SizedBox(width: 16),

              // Play/Pause
              FilledButton(
                onPressed: () {
                  if (prov.state == PomodoroState.idle) {
                    prov.start();
                  } else if (prov.isRunning) {
                    prov.pause();
                  } else {
                    prov.resume();
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: stateColor,
                  minimumSize: const Size(80, 60),
                  shape: const CircleBorder(),
                ),
                child: Icon(
                  prov.isRunning ? Icons.pause : Icons.play_arrow,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Skip
              IconButton.outlined(
                onPressed: prov.state != PomodoroState.idle
                    ? prov.skipToNext
                    : null,
                icon: const Icon(Icons.skip_next),
                iconSize: 28,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Settings
          _PomodoroSettings(prov: prov),
        ],
      ),
    );
  }

  double _progress(PomodoroProvider prov) {
    int total;
    switch (prov.state) {
      case PomodoroState.working:
        total = prov.workMinutes * 60;
        break;
      case PomodoroState.shortBreak:
        total = prov.shortBreakMinutes * 60;
        break;
      case PomodoroState.longBreak:
        total = prov.longBreakMinutes * 60;
        break;
      case PomodoroState.idle:
        total = prov.workMinutes * 60;
        break;
    }
    if (total == 0) return 0;
    return 1 - (prov.secondsRemaining / total);
  }

  Color _stateColor(PomodoroState state) {
    switch (state) {
      case PomodoroState.working:
        return const Color(0xFFFF5722);
      case PomodoroState.shortBreak:
        return const Color(0xFF4CAF50);
      case PomodoroState.longBreak:
        return const Color(0xFF2196F3);
      case PomodoroState.idle:
        return const Color(0xFFFF5722);
    }
  }

  String _stateLabel(PomodoroState state) {
    switch (state) {
      case PomodoroState.working:
        return '🍅 Рабочая сессия';
      case PomodoroState.shortBreak:
        return '☕ Короткий перерыв';
      case PomodoroState.longBreak:
        return '🌿 Длинный перерыв';
      case PomodoroState.idle:
        return '⏸ Готов к работе';
    }
  }

  void _selectTask(
      BuildContext context, TaskProvider taskProv, PomodoroProvider prov) {
    final pending = taskProv.pendingTasks;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Выберите задачу',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: pending.length,
              itemBuilder: (ctx, i) {
                final task = pending[i];
                return ListTile(
                  title: Text(task.title),
                  subtitle: Text(task.subjectName),
                  onTap: () {
                    prov.setTask(task.id, task.title);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _TimerCircle extends StatelessWidget {
  final double progress;
  final String timeText;
  final Color color;

  const _TimerCircle({
    required this.progress,
    required this.timeText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                timeText,
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PomodoroSettings extends StatelessWidget {
  final PomodoroProvider prov;

  const _PomodoroSettings({required this.prov});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Настройки',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _SettingRow(
              label: 'Рабочая сессия',
              value: prov.workMinutes,
              min: 5,
              max: 60,
              onChanged: (v) => prov.updateSettings(workMinutes: v),
            ),
            _SettingRow(
              label: 'Короткий перерыв',
              value: prov.shortBreakMinutes,
              min: 1,
              max: 15,
              onChanged: (v) => prov.updateSettings(shortBreakMinutes: v),
            ),
            _SettingRow(
              label: 'Длинный перерыв',
              value: prov.longBreakMinutes,
              min: 5,
              max: 30,
              onChanged: (v) => prov.updateSettings(longBreakMinutes: v),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _SettingRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        IconButton(
          icon: const Icon(Icons.remove, size: 18),
          onPressed: value > min ? () => onChanged(value - 1) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value мин',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, size: 18),
          onPressed: value < max ? () => onChanged(value + 1) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }
}

class _PomodoroHistory extends StatelessWidget {
  const _PomodoroHistory();

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<PomodoroProvider>().sessions.reversed.toList();
    final theme = Theme.of(context);

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('Нет завершённых сессий',
                style: TextStyle(color: theme.colorScheme.outline)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sessions.length,
      itemBuilder: (ctx, i) {
        final s = sessions[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.timer,
                  color: Color(0xFFFF5722), size: 20),
            ),
            title: Text(s.taskTitle ?? 'Без задачи'),
            subtitle: Text(
              '${s.durationMinutes} мин • ${_formatDate(s.startTime)}',
              style: TextStyle(
                  fontSize: 12, color: theme.colorScheme.outline),
            ),
            trailing: s.completed
                ? const Icon(Icons.check_circle,
                    color: Color(0xFF4CAF50), size: 20)
                : null,
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

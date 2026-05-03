import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/task.dart';
import '../../utils/color_utils.dart';
import '../../utils/label_utils.dart';
import '../../utils/date_utils.dart';
import 'task_form_screen.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _filterSubjectId;
  TaskPriority? _filterPriority;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Task> _filterTasks(List<Task> tasks) {
    return tasks.where((t) {
      if (_filterSubjectId != null && t.subjectId != _filterSubjectId) {
        return false;
      }
      if (_filterPriority != null && t.priority != _filterPriority) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    final studentProv = context.watch<StudentProvider>();

    final allTasks = _filterTasks(taskProv.tasks);
    final pending = _filterTasks(taskProv.tasks
        .where((t) => t.status == TaskStatus.pending)
        .toList());
    final inProgress = _filterTasks(taskProv.tasks
        .where((t) => t.status == TaskStatus.inProgress)
        .toList());
    final completed = _filterTasks(taskProv.tasks
        .where((t) => t.status == TaskStatus.completed)
        .toList());
    final overdue = _filterTasks(taskProv.overdueTasks);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задачи'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: (_filterSubjectId != null || _filterPriority != null)
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () => _showFilterSheet(context, studentProv),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Все (${allTasks.length})'),
            Tab(text: 'Активные (${pending.length + inProgress.length})'),
            Tab(text: 'Выполнено (${completed.length})'),
            Tab(text: 'Просрочено (${overdue.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TaskList(tasks: allTasks),
          _TaskList(tasks: [...inProgress, ...pending]
            ..sort((a, b) => a.deadline.compareTo(b.deadline))),
          _TaskList(tasks: completed),
          _TaskList(tasks: overdue),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TaskFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, StudentProvider studentProv) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Фильтры',
                      style: Theme.of(context).textTheme.titleMedium),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterSubjectId = null;
                        _filterPriority = null;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Сбросить'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Предмет',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Все'),
                    selected: _filterSubjectId == null,
                    onSelected: (_) {
                      setModalState(() {});
                      setState(() => _filterSubjectId = null);
                    },
                  ),
                  ...studentProv.subjects.map((s) => FilterChip(
                        label: Text(s.name),
                        selected: _filterSubjectId == s.id,
                        onSelected: (_) {
                          setModalState(() {});
                          setState(() => _filterSubjectId = s.id);
                        },
                      )),
                ],
              ),
              const SizedBox(height: 12),
              Text('Приоритет',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Все'),
                    selected: _filterPriority == null,
                    onSelected: (_) {
                      setModalState(() {});
                      setState(() => _filterPriority = null);
                    },
                  ),
                  ...TaskPriority.values.map((p) => FilterChip(
                        label: Text(LabelUtils.taskPriority(p)),
                        selected: _filterPriority == p,
                        onSelected: (_) {
                          setModalState(() {});
                          setState(() => _filterPriority = p);
                        },
                      )),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Применить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<Task> tasks;

  const _TaskList({required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              'Нет задач',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _TaskCard(task: tasks[index]),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final taskProv = context.read<TaskProvider>();
    final theme = Theme.of(context);
    final priorityColor = ColorUtils.taskPriorityColor(task.priority);
    final statusColor = ColorUtils.taskStatusColor(task.status);

    return Dismissible(
      key: Key(task.id),
      direction: task.status != TaskStatus.completed
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFF4CAF50),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        taskProv.completeTask(task.id);
        return false;
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => TaskDetailScreen(task: task)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Priority indicator
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                decoration:
                                    task.status == TaskStatus.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _TypeIcon(type: task.type),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.subjectName,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 13, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            AppDateUtils.relativeDeadline(task.deadline),
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              LabelUtils.taskStatus(task.status),
                              style: TextStyle(
                                fontSize: 11,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final TaskType type;

  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (type) {
      case TaskType.assignment:
        icon = Icons.assignment_outlined;
        break;
      case TaskType.exam:
        icon = Icons.quiz_outlined;
        break;
      case TaskType.reminder:
        icon = Icons.notifications_outlined;
        break;
      case TaskType.other:
        icon = Icons.task_outlined;
        break;
    }
    return Icon(icon,
        size: 16, color: Theme.of(context).colorScheme.outline);
  }
}

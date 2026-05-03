import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/task.dart';
import '../../utils/label_utils.dart';
import '../../utils/date_utils.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task; // null = create, non-null = edit
  final DateTime? initialDeadline;

  const TaskFormScreen({super.key, this.task, this.initialDeadline});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;

  String? _subjectId;
  String _subjectName = '';
  late DateTime _deadline;
  late TaskStatus _status;
  late TaskPriority _priority;
  late TaskType _type;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _subjectId = t?.subjectId;
    _subjectName = t?.subjectName ?? '';
    _deadline = t?.deadline ??
        widget.initialDeadline ??
        DateTime.now().add(const Duration(days: 3));
    _status = t?.status ?? TaskStatus.pending;
    _priority = t?.priority ?? TaskPriority.medium;
    _type = t?.type ?? TaskType.assignment;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentProv = context.watch<StudentProvider>();
    final taskProv = context.read<TaskProvider>();
    final isEdit = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редактировать задачу' : 'Новая задача'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, taskProv),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Название задачи *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Введите название' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Subject
            DropdownButtonFormField<String>(
              value: _subjectId,
              decoration: const InputDecoration(
                labelText: 'Предмет *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: studentProv.subjects
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _subjectId = val;
                  _subjectName = studentProv.subjects
                      .firstWhere((s) => s.id == val,
                          orElse: () => studentProv.subjects.first)
                      .name;
                });
              },
              validator: (v) => v == null ? 'Выберите предмет' : null,
            ),
            const SizedBox(height: 16),

            // Type
            DropdownButtonFormField<TaskType>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Тип',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: TaskType.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(LabelUtils.taskType(t)),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _type = val!),
            ),
            const SizedBox(height: 16),

            // Priority
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Приоритет',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: TaskPriority.values.map((p) {
                    final isSelected = _priority == p;
                    final colors = {
                      TaskPriority.low: const Color(0xFF4CAF50),
                      TaskPriority.medium: const Color(0xFFFF9800),
                      TaskPriority.high: const Color(0xFFFF5722),
                      TaskPriority.critical: const Color(0xFFF44336),
                    };
                    final color = colors[p]!;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GestureDetector(
                          onTap: () => setState(() => _priority = p),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color
                                  : color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: color,
                                width: isSelected ? 0 : 1,
                              ),
                            ),
                            child: Text(
                              LabelUtils.taskPriority(p),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : color,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Deadline
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Дедлайн'),
              subtitle: Text(AppDateUtils.formatDateTime(_deadline)),
              trailing: const Icon(Icons.chevron_right),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                    color: Theme.of(context).colorScheme.outline),
              ),
              onTap: () => _pickDeadline(context),
            ),
            const SizedBox(height: 16),

            // Status (only for edit)
            if (isEdit) ...[
              DropdownButtonFormField<TaskStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Статус',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: TaskStatus.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(LabelUtils.taskStatus(s)),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _status = val!),
              ),
              const SizedBox(height: 16),
            ],

            // AI stub: recommended start date
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                        size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Рекомендуемая дата начала',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                          ),
                          Text(
                            AppDateUtils.formatDate(
                              taskProv.computeRecommendedStart(
                                  _deadline, _priority),
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: () => _save(context, taskProv),
              icon: const Icon(Icons.save),
              label: Text(isEdit ? 'Сохранить' : 'Создать задачу'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDeadline(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
    );
    if (!mounted) return;

    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _deadline.hour,
        time?.minute ?? _deadline.minute,
      );
    });
  }

  void _save(BuildContext context, TaskProvider taskProv) {
    if (!_formKey.currentState!.validate()) return;

    if (widget.task == null) {
      final task = Task(
        id: taskProv.newTaskId(),
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        subjectId: _subjectId!,
        subjectName: _subjectName,
        deadline: _deadline,
        recommendedStartDate:
            taskProv.computeRecommendedStart(_deadline, _priority),
        status: _status,
        priority: _priority,
        type: _type,
        complexityNote: 'Оценка сложности (AI — скоро)',
        createdAt: DateTime.now(),
      );
      taskProv.addTask(task);
    } else {
      final updated = widget.task!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        subjectId: _subjectId!,
        subjectName: _subjectName,
        deadline: _deadline,
        recommendedStartDate:
            taskProv.computeRecommendedStart(_deadline, _priority),
        status: _status,
        priority: _priority,
        type: _type,
      );
      taskProv.updateTask(updated);
    }

    Navigator.pop(context);
  }

  void _confirmDelete(BuildContext context, TaskProvider taskProv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              taskProv.deleteTask(widget.task!.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF44336)),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

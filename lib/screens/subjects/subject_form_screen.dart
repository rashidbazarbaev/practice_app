import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../models/subject.dart';

/// Add or edit a subject.
/// If [subject] is null — create mode, otherwise edit mode.
class SubjectFormScreen extends StatefulWidget {
  final Subject? subject;

  const SubjectFormScreen({super.key, this.subject});

  @override
  State<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends State<SubjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late double _progress; // 0–100, single slider
  late String _color;

  List<String> _nameSuggestions = [];
  bool _showSuggestions = false;
  final _nameFocus = FocusNode();

  static const _colorOptions = [
    '#6C63FF', '#FF6584', '#43C6AC', '#F7971E',
    '#56CCF2', '#4CAF50', '#FF5722', '#9C27B0',
    '#2196F3', '#FF9800',
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.subject;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _progress = s?.currentGrade ?? 0;
    _color = s?.color ?? _colorOptions.first;

    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    if (value.length < 2) {
      setState(() {
        _nameSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    final scheduleProv = context.read<ScheduleProvider>();
    final q = value.toLowerCase();
    final filtered = scheduleProv.uniqueSubjectNames
        .where((s) => s.toLowerCase().contains(q))
        .take(8)
        .toList();

    setState(() {
      _nameSuggestions = filtered;
      _showSuggestions = filtered.isNotEmpty;
    });
  }

  void _selectName(String name) {
    _nameCtrl.text = name;
    setState(() => _showSuggestions = false);
    _nameFocus.unfocus();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<StudentProvider>();

    if (widget.subject == null) {
      prov.addSubject(Subject(
        id: prov.newSubjectId(),
        name: _nameCtrl.text.trim(),
        teacher: '',
        currentGrade: _progress,
        targetGrade: 100,
        totalTasks: 0,
        completedTasks: 0,
        color: _color,
      ));
    } else {
      prov.updateSubject(widget.subject!.copyWith(
        name: _nameCtrl.text.trim(),
        currentGrade: _progress,
        targetGrade: 100,
        color: _color,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.subject != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редактировать предмет' : 'Новый предмет'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name with autocomplete
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  decoration: const InputDecoration(
                    labelText: 'Название предмета *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school_outlined),
                    hintText: 'Начните вводить...',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: _onNameChanged,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Введите название' : null,
                ),
                if (_showSuggestions)
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: theme.colorScheme.outlineVariant),
                      ),
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _nameSuggestions.length,
                        itemBuilder: (ctx, i) => InkWell(
                          onTap: () => _selectName(_nameSuggestions[i]),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule_outlined,
                                    size: 14),
                                const SizedBox(width: 8),
                                Text(_nameSuggestions[i]),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Single progress slider
            _ProgressSlider(
              value: _progress,
              onChanged: (v) => setState(() => _progress = v),
            ),
            const SizedBox(height: 24),

            // Color picker
            Text('Цвет', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colorOptions.map((hex) {
                final color = _hexColor(hex);
                final isSelected = _color == hex;
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.onSurface, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 6,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(isEdit ? 'Сохранить' : 'Добавить предмет'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить предмет?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              context
                  .read<StudentProvider>()
                  .deleteSubject(widget.subject!.id);
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

  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

class _ProgressSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _ProgressSlider({required this.value, required this.onChanged});

  Color get _color {
    if (value >= 100) return const Color(0xFF4CAF50);
    if (value >= 70) return const Color(0xFF2196F3);
    if (value >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String get _label {
    if (value >= 100) return 'Сдан / зачтён ✓';
    if (value >= 70) return 'Почти готово';
    if (value >= 40) return 'В процессе';
    if (value > 0) return 'Только начал';
    return 'Не начат';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Прогресс сдачи',
                style: Theme.of(context).textTheme.labelLarge),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toInt()}%',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500),
            ),
            Text(
              '100% = сдан',
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ],
    );
  }
}

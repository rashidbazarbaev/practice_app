import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/note.dart';

class NoteFormScreen extends StatefulWidget {
  final Note? note;

  const NoteFormScreen({super.key, this.note});

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late TextEditingController _tagsCtrl;
  String? _subjectId;
  String _subjectName = '';

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    _titleCtrl = TextEditingController(text: n?.title ?? '');
    _contentCtrl = TextEditingController(text: n?.content ?? '');
    _tagsCtrl = TextEditingController(
        text: n?.tags.join(', ') ?? '');
    _subjectId = n?.subjectId;
    _subjectName = n?.subjectName ?? '';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noteProv = context.read<NoteProvider>();
    final studentProv = context.watch<StudentProvider>();
    final isEdit = widget.note != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редактировать заметку' : 'Новая заметка'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, noteProv),
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _save(context, noteProv),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Заголовок *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Введите заголовок' : null,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

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
            const SizedBox(height: 12),

            TextFormField(
              controller: _contentCtrl,
              decoration: const InputDecoration(
                labelText: 'Содержание',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 15,
              minLines: 8,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Введите содержание' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _tagsCtrl,
              decoration: const InputDecoration(
                labelText: 'Теги (через запятую)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
                hintText: 'формулы, лекция, важное',
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: () => _save(context, noteProv),
              icon: const Icon(Icons.save),
              label: Text(isEdit ? 'Сохранить' : 'Создать заметку'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save(BuildContext context, NoteProvider noteProv) {
    if (!_formKey.currentState!.validate()) return;

    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (widget.note == null) {
      final note = Note(
        id: noteProv.newNoteId(),
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        subjectId: _subjectId!,
        subjectName: _subjectName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: tags,
      );
      noteProv.addNote(note);
    } else {
      final updated = widget.note!.copyWith(
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        subjectId: _subjectId!,
        subjectName: _subjectName,
        tags: tags,
      );
      noteProv.updateNote(updated);
    }

    Navigator.pop(context);
  }

  void _confirmDelete(BuildContext context, NoteProvider noteProv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить заметку?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              noteProv.deleteNote(widget.note!.id);
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

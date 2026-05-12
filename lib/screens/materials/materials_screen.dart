import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import '../../providers/material_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/subject_material.dart';
import '../../models/subject.dart';
import '../../utils/color_utils.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  String? _selectedSubjectId; // null = "Все"

  @override
  Widget build(BuildContext context) {
    final materialProv = context.watch<MaterialProvider>();
    final studentProv = context.watch<StudentProvider>();
    final subjects = studentProv.subjects;

    // Filtered materials
    final materials = _selectedSubjectId == null
        ? materialProv.materials
        : materialProv.forSubject(_selectedSubjectId!);
    materials.sort((a, b) => b.addedAt.compareTo(a.addedAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Материалы'),
      ),
      body: Column(
        children: [
          // Subject filter chips
          if (subjects.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // "Все" chip
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Все'),
                      selected: _selectedSubjectId == null,
                      onSelected: (_) =>
                          setState(() => _selectedSubjectId = null),
                    ),
                  ),
                  ...subjects.map((s) {
                    final color = ColorUtils.fromHex(s.color);
                    final isSelected = _selectedSubjectId == s.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          s.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: color,
                        checkmarkColor: Colors.white,
                        onSelected: (_) =>
                            setState(() => _selectedSubjectId = s.id),
                      ),
                    );
                  }),
                ],
              ),
            ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: subjects.isEmpty
                ? _EmptyState(
                    icon: Icons.school_outlined,
                    message:
                        'Сначала добавьте предметы\nна главном экране',
                  )
                : materials.isEmpty
                    ? _EmptyState(
                        icon: Icons.folder_open_outlined,
                        message: 'Нет материалов\nНажмите + чтобы добавить файл',
                        action: TextButton.icon(
                          onPressed: () =>
                              _pickFile(context, subjects, materialProv),
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить файл'),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                        itemCount: materials.length,
                        itemBuilder: (ctx, i) => _MaterialCard(
                          material: materials[i],
                          subject: studentProv
                              .getSubjectById(materials[i].subjectId),
                          onDelete: () => _confirmDelete(
                              context, materialProv, materials[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: subjects.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _pickFile(context, subjects, materialProv),
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Добавить файл'),
            )
          : null,
    );
  }

  Future<void> _pickFile(
    BuildContext context,
    List<Subject> subjects,
    MaterialProvider prov,
  ) async {
    // Choose subject first if more than one
    Subject? subject;
    if (subjects.length == 1) {
      subject = subjects.first;
    } else {
      subject = await _pickSubject(context, subjects);
      if (subject == null) return;
    }

    // Pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'doc', 'docx', 'ppt', 'pptx',
        'xls', 'xlsx', 'txt', 'png', 'jpg', 'jpeg',
      ],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null) return;

    if (!mounted) return;

    // Show loading
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Добавляем файл...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      await prov.addFile(
        subjectId: subject.id,
        subjectName: subject.name,
        sourceFile: File(picked.path!),
      );
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Файл "${picked.name}" добавлен'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: const Color(0xFFF44336),
        ),
      );
    }
  }

  Future<Subject?> _pickSubject(
      BuildContext context, List<Subject> subjects) async {
    return showModalBottomSheet<Subject>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Выберите предмет',
              style: Theme.of(ctx)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...subjects.map((s) {
              final color = ColorUtils.fromHex(s.color);
              return ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(s.name),
                onTap: () => Navigator.pop(ctx, s),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, MaterialProvider prov, SubjectMaterial m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить файл?'),
        content: Text('"${m.fileName}" будет удалён с устройства.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              prov.deleteMaterial(m.id);
              Navigator.pop(ctx);
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

// ── Material card ─────────────────────────────────────────────────────────────

class _MaterialCard extends StatelessWidget {
  final SubjectMaterial material;
  final Subject? subject;
  final VoidCallback onDelete;

  const _MaterialCard({
    required this.material,
    required this.subject,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        subject != null ? ColorUtils.fromHex(subject!.color) : theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openFile(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // File type icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _extLabel(material.fileExtension),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.fileName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (subject != null) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              material.subjectName,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.outline),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          material.displaySize,
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.outline),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('d MMM', 'ru')
                              .format(material.addedAt),
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: theme.colorScheme.outline),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFile(BuildContext context) async {
    final file = File(material.filePath);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл не найден')),
        );
      }
      return;
    }
    final result = await OpenFilex.open(material.filePath);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть файл: ${result.message}')),
      );
    }
  }

  String _extLabel(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'PDF';
      case 'doc':
      case 'docx':
        return 'DOC';
      case 'ppt':
      case 'pptx':
        return 'PPT';
      case 'xls':
      case 'xlsx':
        return 'XLS';
      case 'txt':
        return 'TXT';
      case 'png':
      case 'jpg':
      case 'jpeg':
        return 'IMG';
      default:
        return ext.toUpperCase().substring(0, ext.length > 3 ? 3 : ext.length);
    }
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _EmptyState({required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 64,
              color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            action!,
          ],
        ],
      ),
    );
  }
}

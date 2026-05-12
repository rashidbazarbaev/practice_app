import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/subject_material.dart';

class MaterialProvider extends ChangeNotifier {
  List<SubjectMaterial> _materials = [];
  final _uuid = const Uuid();

  List<SubjectMaterial> get materials => _materials;

  List<SubjectMaterial> forSubject(String subjectId) =>
      _materials.where((m) => m.subjectId == subjectId).toList()
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  MaterialProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('subject_materials');
    if (json != null) {
      final list = jsonDecode(json) as List;
      _materials = list
          .map((e) => SubjectMaterial.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'subject_materials',
        jsonEncode(_materials.map((m) => m.toJson()).toList()));
  }

  /// Copy [sourceFile] into app documents directory and register it.
  Future<SubjectMaterial> addFile({
    required String subjectId,
    required String subjectName,
    required File sourceFile,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final materialsDir =
        Directory(p.join(appDir.path, 'materials', subjectId));
    await materialsDir.create(recursive: true);

    final fileName = p.basename(sourceFile.path);
    final ext = p.extension(fileName).toLowerCase().replaceAll('.', '');
    final destPath = p.join(materialsDir.path, fileName);

    // Avoid name collision
    final dest = await _uniquePath(destPath);
    await sourceFile.copy(dest);

    final stat = await File(dest).stat();
    final material = SubjectMaterial(
      id: _uuid.v4(),
      subjectId: subjectId,
      subjectName: subjectName,
      fileName: p.basename(dest),
      filePath: dest,
      fileExtension: ext,
      fileSizeBytes: stat.size,
      addedAt: DateTime.now(),
    );

    _materials.add(material);
    await _save();
    notifyListeners();
    return material;
  }

  Future<void> deleteMaterial(String id) async {
    final m = _materials.firstWhere((m) => m.id == id);
    try {
      final f = File(m.filePath);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    _materials.removeWhere((m) => m.id == id);
    await _save();
    notifyListeners();
  }

  Future<String> _uniquePath(String path) async {
    if (!await File(path).exists()) return path;
    final dir = p.dirname(path);
    final ext = p.extension(path);
    final base = p.basenameWithoutExtension(path);
    int i = 1;
    while (true) {
      final candidate = p.join(dir, '${base}_$i$ext');
      if (!await File(candidate).exists()) return candidate;
      i++;
    }
  }
}

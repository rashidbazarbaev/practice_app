import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../models/task.dart';
import '../models/note.dart';

/// All Firestore operations scoped to the current user.
/// Path: users/{uid}/...
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Helpers ───────────────────────────────────────────────────────────────

  DocumentReference _userDoc(String uid) => _db.collection('users').doc(uid);

  CollectionReference _col(String uid, String name) =>
      _userDoc(uid).collection(name);

  // ── Student profile ───────────────────────────────────────────────────────

  Future<void> saveStudent(String uid, Student student) async {
    await _userDoc(uid).set(
      {'profile': student.toJson()},
      SetOptions(merge: true),
    );
  }

  Future<Student?> loadStudent(String uid) async {
    final doc = await _userDoc(uid).get();
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null || data['profile'] == null) return null;
    return Student.fromJson(Map<String, dynamic>.from(data['profile']));
  }

  // ── Subjects ──────────────────────────────────────────────────────────────

  Future<void> saveSubjects(String uid, List<Subject> subjects) async {
    final batch = _db.batch();
    final col = _col(uid, 'subjects');

    // Delete existing then re-write (simple approach for small collections)
    final existing = await col.get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    for (final s in subjects) {
      batch.set(col.doc(s.id), s.toJson());
    }
    await batch.commit();
  }

  Future<List<Subject>> loadSubjects(String uid) async {
    final snap = await _col(uid, 'subjects').get();
    return snap.docs
        .map((d) => Subject.fromJson(Map<String, dynamic>.from(d.data() as Map)))
        .toList();
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  Future<void> saveTask(String uid, Task task) async {
    await _col(uid, 'tasks').doc(task.id).set(task.toJson());
  }

  Future<void> deleteTask(String uid, String taskId) async {
    await _col(uid, 'tasks').doc(taskId).delete();
  }

  Future<List<Task>> loadTasks(String uid) async {
    final snap = await _col(uid, 'tasks').get();
    return snap.docs
        .map((d) => Task.fromJson(Map<String, dynamic>.from(d.data() as Map)))
        .toList();
  }

  // ── Notes ─────────────────────────────────────────────────────────────────

  Future<void> saveNote(String uid, Note note) async {
    await _col(uid, 'notes').doc(note.id).set(note.toJson());
  }

  Future<void> deleteNote(String uid, String noteId) async {
    await _col(uid, 'notes').doc(noteId).delete();
  }

  Future<List<Note>> loadNotes(String uid) async {
    final snap = await _col(uid, 'notes').get();
    return snap.docs
        .map((d) => Note.fromJson(Map<String, dynamic>.from(d.data() as Map)))
        .toList();
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<void> saveSettings(String uid, Map<String, dynamic> settings) async {
    await _userDoc(uid).set(
      {'settings': settings},
      SetOptions(merge: true),
    );
  }

  Future<Map<String, dynamic>?> loadSettings(String uid) async {
    final doc = await _userDoc(uid).get();
    final data = doc.data() as Map<String, dynamic>?;
    return data?['settings'] as Map<String, dynamic>?;
  }
}

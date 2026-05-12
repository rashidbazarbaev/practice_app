import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';

class NoteProvider extends ChangeNotifier {
  List<Note> _notes = [];
  final _uuid = const Uuid();

  List<Note> get notes => _notes;

  List<Note> getNotesForSubject(String subjectId) =>
      _notes.where((n) => n.subjectId == subjectId).toList();

  NoteProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('notes');
    if (json != null) {
      final list = jsonDecode(json) as List;
      _notes = list.map((e) => Note.fromJson(e)).toList();
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'notes', jsonEncode(_notes.map((n) => n.toJson()).toList()));
  }

  Future<void> addNote(Note note) async {
    _notes.add(note);
    await _saveData();
    notifyListeners();
  }

  Future<void> updateNote(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
      await _saveData();
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _saveData();
    notifyListeners();
  }

  String newNoteId() => _uuid.v4();
}

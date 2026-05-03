import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/student.dart';
import '../models/subject.dart';

class StudentProvider extends ChangeNotifier {
  Student? _student;
  List<Subject> _subjects = [];
  final _uuid = const Uuid();

  Student? get student => _student;
  List<Subject> get subjects => _subjects;

  double get averageGrade {
    if (_subjects.isEmpty) return 0;
    return _subjects.map((s) => s.currentGrade).reduce((a, b) => a + b) /
        _subjects.length;
  }

  StudentProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final studentJson = prefs.getString('student');
    if (studentJson != null) {
      _student = Student.fromJson(jsonDecode(studentJson));
    } else {
      // Default mock student
      _student = Student(
        id: _uuid.v4(),
        name: 'Алексей Иванов',
        faculty: 'Факультет информационных технологий',
        course: 2,
        gpa: 4.2,
      );
    }

    final subjectsJson = prefs.getString('subjects');
    if (subjectsJson != null) {
      final list = jsonDecode(subjectsJson) as List;
      _subjects = list.map((e) => Subject.fromJson(e)).toList();
    } else {
      _subjects = _mockSubjects();
    }

    notifyListeners();
  }

  List<Subject> _mockSubjects() => [
        Subject(
          id: _uuid.v4(),
          name: 'Математический анализ',
          teacher: 'Проф. Смирнов А.В.',
          currentGrade: 78,
          targetGrade: 90,
          totalTasks: 12,
          completedTasks: 8,
          color: '#6C63FF',
        ),
        Subject(
          id: _uuid.v4(),
          name: 'Программирование',
          teacher: 'Доц. Петрова Е.С.',
          currentGrade: 92,
          targetGrade: 95,
          totalTasks: 10,
          completedTasks: 9,
          color: '#FF6584',
        ),
        Subject(
          id: _uuid.v4(),
          name: 'Физика',
          teacher: 'Проф. Козлов Д.М.',
          currentGrade: 65,
          targetGrade: 80,
          totalTasks: 8,
          completedTasks: 4,
          color: '#43C6AC',
        ),
        Subject(
          id: _uuid.v4(),
          name: 'История',
          teacher: 'Доц. Новикова Л.П.',
          currentGrade: 88,
          targetGrade: 90,
          totalTasks: 6,
          completedTasks: 5,
          color: '#F7971E',
        ),
        Subject(
          id: _uuid.v4(),
          name: 'Английский язык',
          teacher: 'Ст. пр. Белова О.А.',
          currentGrade: 95,
          targetGrade: 95,
          totalTasks: 15,
          completedTasks: 14,
          color: '#56CCF2',
        ),
      ];

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_student != null) {
      await prefs.setString('student', jsonEncode(_student!.toJson()));
    }
    await prefs.setString(
        'subjects', jsonEncode(_subjects.map((s) => s.toJson()).toList()));
  }

  Future<void> updateStudent(Student student) async {
    _student = student;
    await _saveData();
    notifyListeners();
  }

  Future<void> addSubject(Subject subject) async {
    _subjects.add(subject);
    await _saveData();
    notifyListeners();
  }

  Future<void> updateSubject(Subject subject) async {
    final index = _subjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      _subjects[index] = subject;
      await _saveData();
      notifyListeners();
    }
  }

  Future<void> deleteSubject(String id) async {
    _subjects.removeWhere((s) => s.id == id);
    await _saveData();
    notifyListeners();
  }

  Subject? getSubjectById(String id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  String newSubjectId() => _uuid.v4();

  Color subjectColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

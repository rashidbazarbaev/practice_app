import 'package:flutter/material.dart';
import '../models/task.dart';

class ColorUtils {
  static Color fromHex(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  static Color taskStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return const Color(0xFF4CAF50);
      case TaskStatus.inProgress:
        return const Color(0xFF2196F3);
      case TaskStatus.overdue:
        return const Color(0xFFF44336);
      case TaskStatus.pending:
        return const Color(0xFFFF9800);
    }
  }

  static Color taskPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return const Color(0xFF4CAF50);
      case TaskPriority.medium:
        return const Color(0xFFFF9800);
      case TaskPriority.high:
        return const Color(0xFFFF5722);
      case TaskPriority.critical:
        return const Color(0xFFF44336);
    }
  }

  static Color deadlineColor(DateTime deadline, TaskStatus status) {
    if (status == TaskStatus.completed) return const Color(0xFF4CAF50);
    final diff = deadline.difference(DateTime.now()).inDays;
    if (diff < 0) return const Color(0xFFF44336); // overdue
    if (diff <= 1) return const Color(0xFFF44336); // urgent
    if (diff <= 3) return const Color(0xFFFF9800); // soon
    return const Color(0xFF4CAF50); // ok
  }
}

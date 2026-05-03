import '../models/task.dart';

class LabelUtils {
  static String taskStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Ожидает';
      case TaskStatus.inProgress:
        return 'В процессе';
      case TaskStatus.completed:
        return 'Выполнено';
      case TaskStatus.overdue:
        return 'Просрочено';
    }
  }

  static String taskPriority(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Низкий';
      case TaskPriority.medium:
        return 'Средний';
      case TaskPriority.high:
        return 'Высокий';
      case TaskPriority.critical:
        return 'Критический';
    }
  }

  static String taskType(TaskType type) {
    switch (type) {
      case TaskType.assignment:
        return 'Задание';
      case TaskType.exam:
        return 'Экзамен';
      case TaskType.reminder:
        return 'Напоминание';
      case TaskType.other:
        return 'Другое';
    }
  }
}

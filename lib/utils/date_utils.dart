import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(DateTime date) =>
      DateFormat('dd MMM yyyy', 'ru').format(date);

  static String formatDateTime(DateTime date) =>
      DateFormat('dd MMM yyyy, HH:mm', 'ru').format(date);

  static String formatShort(DateTime date) =>
      DateFormat('dd.MM', 'ru').format(date);

  static String formatMonth(DateTime date) =>
      DateFormat('MMMM yyyy', 'ru').format(date);

  static String relativeDeadline(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative) {
      final days = diff.inDays.abs();
      if (days == 0) return 'Просрочено сегодня';
      return 'Просрочено на ${days}д';
    }
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return 'Через ${diff.inMinutes}мин';
      return 'Через ${diff.inHours}ч';
    }
    if (diff.inDays == 1) return 'Завтра';
    if (diff.inDays <= 7) return 'Через ${diff.inDays}д';
    return formatDate(deadline);
  }
}

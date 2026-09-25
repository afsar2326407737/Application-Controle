import 'package:intl/intl.dart';

abstract final class DateTimeUtils {
  static final DateFormat _dayKey = DateFormat('yyyy-MM-dd');
  static final DateFormat _weekday = DateFormat('EEE');
  static final DateFormat _friendlyDate = DateFormat('MMM d');

  static String dayKey(DateTime value) => _dayKey.format(value);

  static String shortWeekday(DateTime value) => _weekday.format(value);

  static String friendlyDate(DateTime value) => _friendlyDate.format(value);

  static DateTime startOfDay(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime endOfDay(DateTime value) {
    final start = startOfDay(value);
    return start.add(const Duration(days: 1));
  }

  static List<DateTime> lastDays(int count, {DateTime? ending}) {
    final end = startOfDay(ending ?? DateTime.now());
    return List<DateTime>.generate(
      count,
      (index) => end.subtract(Duration(days: count - index - 1)),
    );
  }

  static bool isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  static bool isWithinQuietHours(
    DateTime value, {
    required int startHour,
    required int endHour,
  }) {
    if (startHour == endHour) return false;
    final minuteOfDay = value.hour * 60 + value.minute;
    final start = startHour * 60;
    final end = endHour * 60;
    if (start < end) {
      return minuteOfDay >= start && minuteOfDay < end;
    }
    return minuteOfDay >= start || minuteOfDay < end;
  }
}

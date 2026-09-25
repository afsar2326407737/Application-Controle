class DailyInsight {
  const DailyInsight({
    required this.date,
    required this.distractingMinutes,
    required this.focusMinutes,
  });

  final DateTime date;
  final int distractingMinutes;
  final int focusMinutes;
}

class InsightSummary {
  const InsightSummary({
    required this.days,
    required this.totalDistractingMinutes,
    required this.totalFocusMinutes,
    required this.currentStreak,
    required this.completedSessions,
    required this.urgeOpenEvents,
    required this.topAppName,
    required this.topAppMinutes,
    required this.bestDay,
    required this.bestFocusDay,
    required this.bestFocusTimeLabel,
  });

  final List<DailyInsight> days;
  final int totalDistractingMinutes;
  final int totalFocusMinutes;
  final int currentStreak;
  final int completedSessions;
  final int urgeOpenEvents;
  final String topAppName;
  final int topAppMinutes;
  final DateTime? bestDay;
  final DateTime? bestFocusDay;
  final String bestFocusTimeLabel;
}

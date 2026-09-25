class DailyGoal {
  const DailyGoal({
    required this.date,
    required this.screenTimeLimitMinutes,
    required this.focusTimeTargetMinutes,
  });

  final String date;
  final int screenTimeLimitMinutes;
  final int focusTimeTargetMinutes;

  factory DailyGoal.fromMap(Map<String, Object?> map) {
    return DailyGoal(
      date: map['date'] as String? ?? '',
      screenTimeLimitMinutes: map['screen_time_limit'] as int? ?? 0,
      focusTimeTargetMinutes: map['focus_time_target'] as int? ?? 0,
    );
  }

  Map<String, Object?> toMap() => {
    'date': date,
    'screen_time_limit': screenTimeLimitMinutes,
    'focus_time_target': focusTimeTargetMinutes,
  };
}

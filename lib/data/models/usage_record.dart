class UsageRecord {
  const UsageRecord({
    required this.packageName,
    required this.applicationName,
    required this.date,
    required this.startTime,
    required this.duration,
    this.isForeground = true,
  });

  final String packageName;
  final String applicationName;
  final String date;
  final DateTime startTime;
  final Duration duration;
  final bool isForeground;

  factory UsageRecord.fromMap(Map<String, Object?> map) {
    return UsageRecord(
      packageName: map['package_name'] as String? ?? '',
      applicationName: map['application_name'] as String? ?? 'Unknown app',
      date: map['date'] as String? ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(
        map['start_time'] as int? ?? 0,
      ),
      duration: Duration(milliseconds: map['duration_ms'] as int? ?? 0),
      isForeground: (map['is_foreground'] as int? ?? 1) == 1,
    );
  }

  factory UsageRecord.fromPlatform(Map<Object?, Object?> map) {
    final epoch = map['startTime'] as int? ?? 0;
    final date = map['date'] as String?;
    return UsageRecord(
      packageName: map['packageName'] as String? ?? '',
      applicationName: map['applicationName'] as String? ?? 'Unknown app',
      date: date ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(epoch),
      duration: Duration(milliseconds: map['duration'] as int? ?? 0),
      isForeground: map['isForeground'] as bool? ?? true,
    );
  }

  Map<String, Object?> toMap() => {
    'package_name': packageName,
    'application_name': applicationName,
    'date': date,
    'start_time': startTime.millisecondsSinceEpoch,
    'duration_ms': duration.inMilliseconds,
    'is_foreground': isForeground ? 1 : 0,
  };
}

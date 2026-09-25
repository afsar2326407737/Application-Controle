import 'dart:convert';

enum FocusSessionStatus { active, paused, completed, ended }

extension FocusSessionStatusLabel on FocusSessionStatus {
  String get label => switch (this) {
    FocusSessionStatus.active => 'In progress',
    FocusSessionStatus.paused => 'Paused',
    FocusSessionStatus.completed => 'Completed',
    FocusSessionStatus.ended => 'Ended early',
  };
}

class FocusSession {
  const FocusSession({
    required this.id,
    required this.startTime,
    required this.plannedDuration,
    required this.completedDuration,
    required this.intention,
    required this.status,
    this.endTime,
    this.avoidedPackages = const <String>[],
    this.isStrict = false,
    this.interruptionCount = 0,
    this.accumulatedFocusSeconds = 0,
    this.lastResumedAt,
  });

  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration plannedDuration;
  final Duration completedDuration;
  final String intention;
  final FocusSessionStatus status;
  final List<String> avoidedPackages;
  final bool isStrict;
  final int interruptionCount;

  /// Elapsed time already banked before the latest resume. Together with
  /// [lastResumedAt], this makes the timer recover exactly after backgrounding
  /// or a process restart.
  final int accumulatedFocusSeconds;
  final DateTime? lastResumedAt;

  bool get isRunning =>
      status == FocusSessionStatus.active && lastResumedAt != null;

  Duration elapsedAt(DateTime now) {
    if (status != FocusSessionStatus.active || lastResumedAt == null) {
      return completedDuration;
    }
    final live = now.difference(lastResumedAt!);
    if (live.isNegative) return Duration(seconds: accumulatedFocusSeconds);
    return Duration(seconds: accumulatedFocusSeconds) + live;
  }

  Duration remainingAt(DateTime now) {
    final remaining = plannedDuration - elapsedAt(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  double progressAt(DateTime now) {
    if (plannedDuration.inSeconds == 0) return 0;
    return (elapsedAt(now).inSeconds / plannedDuration.inSeconds).clamp(0, 1);
  }

  FocusSession copyWith({
    DateTime? endTime,
    bool clearEndTime = false,
    Duration? completedDuration,
    FocusSessionStatus? status,
    List<String>? avoidedPackages,
    bool? isStrict,
    int? interruptionCount,
    int? accumulatedFocusSeconds,
    DateTime? lastResumedAt,
    bool clearLastResumedAt = false,
  }) {
    return FocusSession(
      id: id,
      startTime: startTime,
      endTime: clearEndTime ? null : endTime ?? this.endTime,
      plannedDuration: plannedDuration,
      completedDuration: completedDuration ?? this.completedDuration,
      intention: intention,
      status: status ?? this.status,
      avoidedPackages: avoidedPackages ?? this.avoidedPackages,
      isStrict: isStrict ?? this.isStrict,
      interruptionCount: interruptionCount ?? this.interruptionCount,
      accumulatedFocusSeconds:
          accumulatedFocusSeconds ?? this.accumulatedFocusSeconds,
      lastResumedAt: clearLastResumedAt
          ? null
          : lastResumedAt ?? this.lastResumedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'start_time': startTime.millisecondsSinceEpoch,
    'end_time': endTime?.millisecondsSinceEpoch,
    'planned_duration': plannedDuration.inSeconds,
    'completed_duration': completedDuration.inSeconds,
    'intention': intention,
    'status': status.name,
    'avoided_packages': jsonEncode(avoidedPackages),
    'is_strict': isStrict ? 1 : 0,
    'interruption_count': interruptionCount,
    'accumulated_focus_seconds': accumulatedFocusSeconds,
    'last_resumed_at': lastResumedAt?.millisecondsSinceEpoch,
  };

  factory FocusSession.fromMap(Map<String, Object?> map) {
    final rawPackages = map['avoided_packages'];
    final packages = rawPackages is String
        ? (jsonDecode(rawPackages) as List<dynamic>)
        : <String>[];
    return FocusSession(
      id: map['id'] as String? ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(
        map['start_time'] as int? ?? 0,
      ),
      endTime: map['end_time'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int),
      plannedDuration: Duration(seconds: map['planned_duration'] as int? ?? 0),
      completedDuration: Duration(
        seconds: map['completed_duration'] as int? ?? 0,
      ),
      intention: map['intention'] as String? ?? 'Focus',
      status: FocusSessionStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => FocusSessionStatus.ended,
      ),
      avoidedPackages: packages.whereType<String>().toList(),
      isStrict: (map['is_strict'] as int? ?? 0) == 1,
      interruptionCount: map['interruption_count'] as int? ?? 0,
      accumulatedFocusSeconds: map['accumulated_focus_seconds'] as int? ?? 0,
      lastResumedAt: map['last_resumed_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['last_resumed_at'] as int),
    );
  }
}

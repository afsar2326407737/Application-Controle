enum UrgeDecision { continued, openedApp, abandoned }

extension UrgeDecisionLabel on UrgeDecision {
  String get value => switch (this) {
    UrgeDecision.continued => 'continued',
    UrgeDecision.openedApp => 'opened_app',
    UrgeDecision.abandoned => 'not_sure',
  };
}

class UrgeLog {
  const UrgeLog({
    required this.id,
    required this.timestamp,
    required this.feeling,
    required this.waitMinutes,
    required this.alternative,
    this.decision,
  });

  final String id;
  final DateTime timestamp;
  final String feeling;
  final int waitMinutes;
  final String alternative;
  final UrgeDecision? decision;

  UrgeLog copyWith({UrgeDecision? decision}) {
    return UrgeLog(
      id: id,
      timestamp: timestamp,
      feeling: feeling,
      waitMinutes: waitMinutes,
      alternative: alternative,
      decision: decision ?? this.decision,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'feeling': feeling,
    'wait_minutes': waitMinutes,
    'alternative': alternative,
    'decision': decision?.value,
  };

  factory UrgeLog.fromMap(Map<String, Object?> map) {
    final rawDecision = map['decision'] as String?;
    return UrgeLog(
      id: map['id'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] as int? ?? 0,
      ),
      feeling: map['feeling'] as String? ?? 'Unclear',
      waitMinutes: map['wait_minutes'] as int? ?? 0,
      alternative: map['alternative'] as String? ?? 'Paused before deciding',
      decision: UrgeDecision.values
          .where((value) => value.value == rawDecision)
          .firstOrNull,
    );
  }
}

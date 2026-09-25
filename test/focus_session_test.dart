import 'package:flutter_test/flutter_test.dart';
import 'package:unloop/data/models/focus_session.dart';

void main() {
  group('FocusSession', () {
    final start = DateTime(2026, 9, 24, 10);

    test('recovers elapsed time from a persisted resume timestamp', () {
      final session = FocusSession(
        id: 'focus-1',
        startTime: start,
        plannedDuration: const Duration(minutes: 25),
        completedDuration: Duration.zero,
        intention: 'Study',
        status: FocusSessionStatus.active,
        accumulatedFocusSeconds: 5 * 60,
        lastResumedAt: start.add(const Duration(minutes: 5)),
      );

      final now = start.add(const Duration(minutes: 12));
      expect(session.elapsedAt(now), const Duration(minutes: 12));
      expect(session.remainingAt(now), const Duration(minutes: 13));
      expect(session.progressAt(now), closeTo(0.48, 0.001));
    });

    test('round-trips active timer state through local storage', () {
      final session = FocusSession(
        id: 'focus-2',
        startTime: start,
        plannedDuration: const Duration(minutes: 15),
        completedDuration: Duration.zero,
        intention: 'Read',
        status: FocusSessionStatus.active,
        avoidedPackages: const ['com.example.reader'],
        accumulatedFocusSeconds: 120,
        lastResumedAt: start.add(const Duration(minutes: 2)),
      );

      final restored = FocusSession.fromMap(session.toMap());
      expect(restored.id, session.id);
      expect(restored.avoidedPackages, ['com.example.reader']);
      expect(restored.accumulatedFocusSeconds, 120);
      expect(restored.lastResumedAt, start.add(const Duration(minutes: 2)));
    });
  });
}

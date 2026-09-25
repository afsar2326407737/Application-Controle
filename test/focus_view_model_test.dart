import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unloop/core/services/notification_service.dart';
import 'package:unloop/data/models/focus_session.dart';
import 'package:unloop/data/repositories/focus_repository.dart';
import 'package:unloop/presentation/viewmodels/focus_view_model.dart';

class _MockFocusRepository extends Mock implements FocusRepository {}

class _MockNotificationService extends Mock implements NotificationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      FocusSession(
        id: 'fallback',
        startTime: DateTime(2026),
        plannedDuration: Duration.zero,
        completedDuration: Duration.zero,
        intention: '',
        status: FocusSessionStatus.active,
      ),
    );
  });

  test(
    'restores a running session and pauses without losing elapsed time',
    () async {
      final repository = _MockFocusRepository();
      final notifications = _MockNotificationService();
      final now = DateTime(2026, 9, 24, 10, 12);
      final restored = FocusSession(
        id: 'restored',
        startTime: now.subtract(const Duration(minutes: 12)),
        plannedDuration: const Duration(minutes: 25),
        completedDuration: Duration.zero,
        intention: 'Work',
        status: FocusSessionStatus.active,
        accumulatedFocusSeconds: 5 * 60,
        lastResumedAt: now.subtract(const Duration(minutes: 2)),
      );
      when(repository.loadActive).thenReturn(restored);
      when(() => repository.save(any())).thenAnswer((_) async {});

      final viewModel = FocusViewModel(
        focusRepository: repository,
        notificationService: notifications,
        now: () => now,
      );
      await viewModel.initialize();

      expect(viewModel.remaining, const Duration(minutes: 18));
      await viewModel.pause();

      final captured =
          verify(() => repository.save(captureAny())).captured.single
              as FocusSession;
      expect(captured.status, FocusSessionStatus.paused);
      expect(captured.completedDuration, const Duration(minutes: 7));
      expect(captured.lastResumedAt, isNull);
      viewModel.dispose();
    },
  );
}

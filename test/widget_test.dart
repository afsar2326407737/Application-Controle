import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:unloop/core/services/notification_service.dart';
import 'package:unloop/core/theme/app_theme.dart';
import 'package:unloop/data/models/focus_session.dart';
import 'package:unloop/data/repositories/focus_repository.dart';
import 'package:unloop/presentation/viewmodels/focus_view_model.dart';
import 'package:unloop/presentation/views/focus/active_focus_view.dart';
import 'package:unloop/presentation/widgets/progress_ring.dart';

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

  testWidgets('active focus screen renders a recoverable calm timer', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _MockFocusRepository();
    final notifications = _MockNotificationService();
    final now = DateTime(2026, 9, 24, 9);
    when(repository.loadActive).thenReturn(null);
    when(() => repository.save(any())).thenAnswer((_) async {});
    when(
      () => notifications.showFocusStarted(
        intention: any(named: 'intention'),
        minutes: any(named: 'minutes'),
      ),
    ).thenAnswer((_) async {});
    final viewModel = FocusViewModel(
      focusRepository: repository,
      notificationService: notifications,
      now: () => now,
    );
    await viewModel.initialize();
    await viewModel.start(
      minutes: 15,
      intention: 'Outline chapter',
      avoidedPackages: const [],
      isStrict: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ChangeNotifierProvider.value(
          value: viewModel,
          child: const ActiveFocusView(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Outline chapter'), findsOneWidget);
    expect(find.text('15:00'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.textContaining('recovers after restarts'), findsOneWidget);
    viewModel.dispose();
  });

  testWidgets('progress ring exposes an accessible percentage', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProgressRing(
            progress: 0.4,
            semanticLabel: 'Daily intention progress',
            child: const Text('40%'),
          ),
        ),
      ),
    );

    expect(find.text('40%'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Daily intention progress')),
      findsOneWidget,
    );
    semantics.dispose();
  });
}

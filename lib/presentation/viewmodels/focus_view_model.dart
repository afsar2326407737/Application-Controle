import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/notification_service.dart';
import '../../data/models/focus_session.dart';
import '../../data/repositories/focus_repository.dart';

class FocusViewModel extends ChangeNotifier {
  FocusViewModel({
    required FocusRepository focusRepository,
    required NotificationService notificationService,
    DateTime Function()? now,
  }) : _focusRepository = focusRepository,
       _notificationService = notificationService,
       _now = now ?? DateTime.now;

  final FocusRepository _focusRepository;
  final NotificationService _notificationService;
  final DateTime Function() _now;

  FocusSession? _activeSession;
  FocusSession? _completedSession;
  Timer? _ticker;
  bool _isLoading = true;
  bool _isTransitioning = false;
  int _completionVersion = 0;

  FocusSession? get activeSession => _activeSession;
  FocusSession? get completedSession => _completedSession;
  bool get isLoading => _isLoading;
  bool get isTransitioning => _isTransitioning;
  int get completionVersion => _completionVersion;

  Duration get remaining {
    final session = _activeSession;
    return session?.remainingAt(_now()) ?? Duration.zero;
  }

  Duration get elapsed {
    return _activeSession?.elapsedAt(_now()) ?? Duration.zero;
  }

  double get progress => _activeSession?.progressAt(_now()) ?? 0;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    final restored = _focusRepository.loadActive();
    _activeSession = restored;
    if (restored != null && restored.remainingAt(_now()) == Duration.zero) {
      await _complete(restored, notify: false);
    } else if (restored?.isRunning ?? false) {
      _startTicker();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> start({
    required int minutes,
    required String intention,
    required List<String> avoidedPackages,
    required bool isStrict,
  }) async {
    if (_activeSession != null) return false;
    _isTransitioning = true;
    notifyListeners();
    final now = _now();
    final session = FocusSession(
      id: '${now.microsecondsSinceEpoch}',
      startTime: now,
      plannedDuration: Duration(minutes: minutes),
      completedDuration: Duration.zero,
      intention: intention.trim().isEmpty ? 'Focus' : intention.trim(),
      status: FocusSessionStatus.active,
      avoidedPackages: avoidedPackages,
      isStrict: isStrict,
      lastResumedAt: now,
    );
    try {
      await _focusRepository.save(session);
      _activeSession = session;
      _startTicker();
      await _notificationService.showFocusStarted(
        intention: session.intention,
        minutes: minutes,
      );
      return true;
    } on Object {
      return false;
    } finally {
      _isTransitioning = false;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    final session = _activeSession;
    if (session == null || session.status != FocusSessionStatus.active) return;
    final now = _now();
    final paused = session.copyWith(
      status: FocusSessionStatus.paused,
      completedDuration: session.elapsedAt(now),
      accumulatedFocusSeconds: session.elapsedAt(now).inSeconds,
      clearLastResumedAt: true,
    );
    await _saveActive(paused);
    _ticker?.cancel();
  }

  Future<void> resume() async {
    final session = _activeSession;
    if (session == null || session.status != FocusSessionStatus.paused) return;
    final running = session.copyWith(
      status: FocusSessionStatus.active,
      lastResumedAt: _now(),
    );
    await _saveActive(running);
    _startTicker();
  }

  Future<void> endEarly() async {
    final session = _activeSession;
    if (session == null || _isTransitioning) return;
    _isTransitioning = true;
    _ticker?.cancel();
    notifyListeners();
    final now = _now();
    final elapsed = session.elapsedAt(now);
    final ended = session.copyWith(
      status: FocusSessionStatus.ended,
      endTime: now,
      completedDuration: elapsed,
      accumulatedFocusSeconds: elapsed.inSeconds,
      interruptionCount: session.interruptionCount + 1,
      clearLastResumedAt: true,
    );
    try {
      await _focusRepository.save(ended);
      _activeSession = null;
    } finally {
      _isTransitioning = false;
      notifyListeners();
    }
  }

  void acknowledgeCompletion() {
    _completedSession = null;
    notifyListeners();
  }

  Future<void> _saveActive(FocusSession session) async {
    _activeSession = session;
    notifyListeners();
    try {
      await _focusRepository.save(session);
    } on Object {
      // The in-memory timer remains accurate even if a transient disk write
      // fails; the next transition persists the complete state again.
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = _activeSession;
      if (session == null) {
        _ticker?.cancel();
        return;
      }
      if (session.remainingAt(_now()) == Duration.zero) {
        unawaited(_complete(session));
      } else {
        notifyListeners();
      }
    });
  }

  Future<void> _complete(FocusSession session, {bool notify = true}) async {
    if (_isTransitioning) return;
    _isTransitioning = true;
    _ticker?.cancel();
    final now = _now();
    final completed = session.copyWith(
      status: FocusSessionStatus.completed,
      endTime: now,
      completedDuration: session.plannedDuration,
      accumulatedFocusSeconds: session.plannedDuration.inSeconds,
      clearLastResumedAt: true,
    );
    try {
      await _focusRepository.save(completed);
      _activeSession = null;
      _completedSession = completed;
      _completionVersion++;
      if (notify) {
        await _notificationService.showFocusCompleted(
          focused: completed.plannedDuration,
          intention: completed.intention,
        );
      }
    } on Object {
      _activeSession = session;
      _startTicker();
    } finally {
      _isTransitioning = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

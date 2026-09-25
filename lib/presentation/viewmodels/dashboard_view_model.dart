import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/focus_session.dart';
import '../../data/models/usage_record.dart';
import '../../data/repositories/focus_repository.dart';
import '../../data/repositories/usage_repository.dart';
import '../../core/utils/date_time_utils.dart';
import 'app_view_model.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    required UsageRepository usageRepository,
    required FocusRepository focusRepository,
    required AppViewModel appViewModel,
  }) : _usageRepository = usageRepository,
       _focusRepository = focusRepository,
       _appViewModel = appViewModel;

  final UsageRepository _usageRepository;
  final FocusRepository _focusRepository;
  final AppViewModel _appViewModel;

  List<UsageRecord> _todayApps = const [];
  List<FocusSession> _todaySessions = const [];
  bool _isLoading = false;
  bool _hasUsageAccess = false;
  int _currentStreak = 0;
  DateTime? _lastSyncedAt;
  String? _errorMessage;

  List<UsageRecord> get todayApps => _todayApps;
  bool get isLoading => _isLoading;
  bool get hasUsageAccess => _hasUsageAccess;
  int get currentStreak => _currentStreak;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get errorMessage => _errorMessage;
  int get dailyTargetMinutes => _appViewModel.settings.dailyLimitMinutes;
  int get focusTargetMinutes => _appViewModel.settings.focusTargetMinutes;

  int get distractingMinutes =>
      _todayApps.fold<int>(
        0,
        (sum, record) => sum + record.duration.inMilliseconds,
      ) ~/
      Duration.millisecondsPerMinute;

  int get completedFocusMinutes => _todaySessions
      .where((session) => session.status == FocusSessionStatus.completed)
      .fold<int>(
        0,
        (sum, session) => sum + session.completedDuration.inMinutes,
      );

  int get focusSessionCount => _todaySessions
      .where((session) => session.status == FocusSessionStatus.completed)
      .length;

  double get targetProgress {
    if (dailyTargetMinutes <= 0) return 0;
    return (distractingMinutes / dailyTargetMinutes).clamp(0, 1);
  }

  double get focusProgress {
    if (focusTargetMinutes <= 0) return 0;
    return (completedFocusMinutes / focusTargetMinutes).clamp(0, 1);
  }

  String get riskMessage {
    final ratio = dailyTargetMinutes == 0
        ? 0.0
        : distractingMinutes / dailyTargetMinutes;
    if (_todayApps.isEmpty) {
      return 'A blank slate. Notice what matters without judging it.';
    }
    if (ratio >= 1) {
      return 'You are at today’s intention. A pause can still change the next moment.';
    }
    if (ratio >= 0.75) {
      return 'Usage is moving quickly. One intentional break may be enough.';
    }
    return 'You are moving at a steady pace. Keep choosing the next small thing.';
  }

  Future<void> load({bool forceSync = true}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _hasUsageAccess = await _usageRepository.hasUsageAccess();
      if (_hasUsageAccess && forceSync) {
        final syncedRecords = await _usageRepository.syncRecentUsage(days: 7);
        if (syncedRecords != null) _lastSyncedAt = DateTime.now();
      }
      final selected = _appViewModel.settings.selectedPackages.toSet();
      _todayApps = selected.isEmpty
          ? const []
          : (await _usageRepository.getForDate(DateTime.now()))
                .where((record) => selected.contains(record.packageName))
                .toList();
      _todaySessions = await _focusRepository.getForDate(DateTime.now());
      _currentStreak = _calculateStreak(await _focusRepository.getAll());
    } on Object {
      _errorMessage =
          'Some local data could not be refreshed. Your saved history is safe.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int _calculateStreak(List<FocusSession> sessions) {
    final completedDays = sessions
        .where((session) => session.status == FocusSessionStatus.completed)
        .map((session) => DateTimeUtils.dayKey(session.startTime))
        .toSet();
    if (completedDays.isEmpty) return 0;

    var cursor = DateTimeUtils.startOfDay(DateTime.now());
    if (!completedDays.contains(DateTimeUtils.dayKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (completedDays.contains(DateTimeUtils.dayKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> openUsageAccess() => _usageRepository.openUsageAccessSettings();

  Future<void> openDigitalWellbeing() =>
      _usageRepository.openDigitalWellbeingSettings();
}

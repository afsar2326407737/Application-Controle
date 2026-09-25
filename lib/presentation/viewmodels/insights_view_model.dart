import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../core/utils/date_time_utils.dart';
import '../../data/models/focus_session.dart';
import '../../data/models/insight_summary.dart';
import '../../data/models/urge_log.dart';
import '../../data/models/usage_record.dart';
import '../../data/repositories/focus_repository.dart';
import '../../data/repositories/urge_repository.dart';
import '../../data/repositories/usage_repository.dart';
import 'app_view_model.dart';

class InsightsViewModel extends ChangeNotifier {
  InsightsViewModel({
    required UsageRepository usageRepository,
    required FocusRepository focusRepository,
    required UrgeRepository urgeRepository,
    required AppViewModel appViewModel,
  }) : _usageRepository = usageRepository,
       _focusRepository = focusRepository,
       _urgeRepository = urgeRepository,
       _appViewModel = appViewModel;

  final UsageRepository _usageRepository;
  final FocusRepository _focusRepository;
  final UrgeRepository _urgeRepository;
  final AppViewModel _appViewModel;

  InsightSummary _summary = const InsightSummary(
    days: [],
    totalDistractingMinutes: 0,
    totalFocusMinutes: 0,
    currentStreak: 0,
    completedSessions: 0,
    urgeOpenEvents: 0,
    topAppName: '',
    topAppMinutes: 0,
    bestDay: null,
    bestFocusDay: null,
    bestFocusTimeLabel: 'No pattern yet',
  );
  List<FocusSession> _recentSessions = const [];
  bool _isLoading = false;
  String? _errorMessage;

  InsightSummary get summary => _summary;
  List<FocusSession> get recentSessions => _recentSessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get suggestion {
    if (_summary.days.isEmpty) {
      return 'Your patterns will appear after a little local history builds.';
    }
    if (_summary.totalFocusMinutes == 0) {
      return 'Try one short focus session today. Fifteen quiet minutes still count.';
    }
    if (_summary.totalDistractingMinutes > _summary.totalFocusMinutes * 2) {
      return 'Your focus is finding its rhythm. A smaller, repeatable session may help more than a longer one.';
    }
    return 'Your recent balance is moving in a sustainable direction. Keep sessions small enough to repeat.';
  }

  Future<void> load({bool syncUsage = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final end = DateTime.now();
      final start = DateTimeUtils.startOfDay(
        end.subtract(const Duration(days: 6)),
      );
      if (syncUsage) {
        try {
          await _usageRepository.syncRecentUsage(days: 7);
        } on Object {
          // Cached data remains useful when permission is unavailable.
        }
      }
      final records = await _usageRepository.getForRange(start, end);
      final sessions = await _focusRepository.getForRange(start, end);
      final urges = await _urgeRepository.getForRange(start, end);
      final selected = _appViewModel.settings.selectedPackages.toSet();
      final filtered = selected.isEmpty
          ? <UsageRecord>[]
          : records
                .where((record) => selected.contains(record.packageName))
                .toList();
      final days = DateTimeUtils.lastDays(7, ending: end);
      final daily = <DateTime, DailyInsight>{};
      for (final day in days) {
        daily[day] = DailyInsight(
          date: day,
          distractingMinutes: 0,
          focusMinutes: 0,
        );
      }
      for (final record in filtered) {
        final parsedDate = DateTime.tryParse(record.date);
        final day = DateTimeUtils.startOfDay(parsedDate ?? record.startTime);
        final item = daily[day];
        if (item != null) {
          daily[day] = DailyInsight(
            date: day,
            distractingMinutes:
                item.distractingMinutes + record.duration.inMinutes,
            focusMinutes: item.focusMinutes,
          );
        }
      }
      for (final session in sessions) {
        final day = DateTimeUtils.startOfDay(session.startTime);
        final item = daily[day];
        if (item != null) {
          daily[day] = DailyInsight(
            date: day,
            distractingMinutes: item.distractingMinutes,
            focusMinutes:
                item.focusMinutes + session.completedDuration.inMinutes,
          );
        }
      }

      final appTotals = <String, int>{};
      for (final record in filtered) {
        appTotals.update(
          record.applicationName,
          (value) => value + record.duration.inMinutes,
          ifAbsent: () => record.duration.inMinutes,
        );
      }
      final topEntry = appTotals.entries.isEmpty
          ? null
          : appTotals.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final completed = sessions
          .where((session) => session.status == FocusSessionStatus.completed)
          .toList();
      DailyInsight? bestDay;
      for (final item in daily.values) {
        if (bestDay == null || item.focusMinutes > bestDay.focusMinutes) {
          bestDay = item;
        }
      }
      final bestSession = completed.isEmpty
          ? null
          : completed.reduce(
              (a, b) => a.completedDuration >= b.completedDuration ? a : b,
            );
      _summary = InsightSummary(
        days: days.map((day) => daily[day]!).toList(),
        totalDistractingMinutes: daily.values.fold<int>(
          0,
          (sum, day) => sum + day.distractingMinutes,
        ),
        totalFocusMinutes: daily.values.fold<int>(
          0,
          (sum, day) => sum + day.focusMinutes,
        ),
        currentStreak: _calculateStreak(completed),
        completedSessions: completed.length,
        urgeOpenEvents: urges
            .where((log) => log.decision == UrgeDecision.openedApp)
            .length,
        topAppName: topEntry?.key ?? '',
        topAppMinutes: topEntry?.value ?? 0,
        bestDay: bestDay?.focusMinutes == 0 ? null : bestDay?.date,
        bestFocusDay: bestSession?.startTime,
        bestFocusTimeLabel: bestSession == null
            ? 'No pattern yet'
            : DateFormat.jm().format(bestSession.startTime),
      );
      _recentSessions = sessions.take(8).toList();
    } on Object {
      _errorMessage =
          'Insights could not be refreshed. Saved history is still here.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int _calculateStreak(List<FocusSession> completed) {
    final days = completed
        .map((session) => DateTimeUtils.dayKey(session.startTime))
        .toSet();
    var cursor = DateTimeUtils.startOfDay(DateTime.now());
    if (!days.contains(DateTimeUtils.dayKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (days.contains(DateTimeUtils.dayKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

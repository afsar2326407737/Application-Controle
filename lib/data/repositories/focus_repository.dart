import '../../core/utils/date_time_utils.dart';
import '../datasources/focus_local_data_source.dart';
import '../datasources/settings_local_data_source.dart';
import '../models/focus_session.dart';

class FocusRepository {
  FocusRepository(this._localDataSource, this._settingsLocalDataSource);

  final FocusLocalDataSource _localDataSource;
  final SettingsLocalDataSource _settingsLocalDataSource;

  Future<void> save(FocusSession session) async {
    if (session.status == FocusSessionStatus.active ||
        session.status == FocusSessionStatus.paused) {
      await _settingsLocalDataSource.saveActiveSession(session.toMap());
    } else {
      await _settingsLocalDataSource.clearActiveSession();
    }
    await _localDataSource.upsert(session);
  }

  FocusSession? loadActive() {
    final map = _settingsLocalDataSource.getActiveSession();
    if (map == null) return null;
    try {
      final session = FocusSession.fromMap(map);
      if (session.status == FocusSessionStatus.active ||
          session.status == FocusSessionStatus.paused) {
        return session;
      }
    } on Object {
      return null;
    }
    return null;
  }

  Future<List<FocusSession>> getAll() => _localDataSource.getAll();

  Future<List<FocusSession>> getForDate(DateTime date) =>
      _localDataSource.getForDate(DateTimeUtils.dayKey(date));

  Future<List<FocusSession>> getForRange(DateTime start, DateTime end) async {
    final sessions = await _localDataSource.getAll();
    return sessions.where((session) {
      return !session.startTime.isBefore(start) &&
          session.startTime.isBefore(end);
    }).toList();
  }
}

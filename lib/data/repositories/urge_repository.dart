import '../datasources/settings_local_data_source.dart';
import '../datasources/urge_local_data_source.dart';
import '../models/urge_log.dart';

class UrgeRepository {
  UrgeRepository(this._localDataSource, this._settingsLocalDataSource);

  final UrgeLocalDataSource _localDataSource;
  final SettingsLocalDataSource _settingsLocalDataSource;

  Future<void> save(UrgeLog log) => _localDataSource.upsert(log);

  Future<List<UrgeLog>> getForRange(DateTime start, DateTime end) =>
      _localDataSource.getForRange(start, end);

  Map<String, Object?>? loadDraft() => _settingsLocalDataSource.getUrgeDraft();

  Future<void> saveDraft(Map<String, Object?> draft) =>
      _settingsLocalDataSource.saveUrgeDraft(draft);

  Future<void> clearDraft() => _settingsLocalDataSource.clearUrgeDraft();
}

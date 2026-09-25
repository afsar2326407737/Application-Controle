import '../datasources/settings_local_data_source.dart';
import '../models/user_settings.dart';

class SettingsRepository {
  SettingsRepository(this._localDataSource);

  final SettingsLocalDataSource _localDataSource;

  UserSettings load() => _localDataSource.load();

  Future<UserSettings> save(UserSettings settings) async {
    await _localDataSource.save(settings);
    return settings;
  }

  Future<void> clear() => _localDataSource.clear();
}

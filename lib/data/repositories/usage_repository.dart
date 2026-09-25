import '../../core/utils/date_time_utils.dart';
import '../datasources/android_usage_data_source.dart';
import '../datasources/usage_local_data_source.dart';
import '../models/app_info.dart';
import '../models/usage_record.dart';

class UsageRepository {
  UsageRepository(this._localDataSource, this._platformDataSource);

  final UsageLocalDataSource _localDataSource;
  final AndroidUsageDataSource _platformDataSource;

  Future<bool> hasUsageAccess() => _platformDataSource.hasUsageAccess();

  Future<void> openUsageAccessSettings() =>
      _platformDataSource.openUsageAccessSettings();

  Future<void> openDigitalWellbeingSettings() =>
      _platformDataSource.openDigitalWellbeingSettings();

  Future<List<AppInfo>> getInstalledApps() =>
      _platformDataSource.getInstalledApps();

  Future<List<UsageRecord>?> syncRecentUsage({int days = 7}) async {
    final safeDays = days.clamp(1, 31);
    if (!await hasUsageAccess()) return null;
    final records = await _platformDataSource.getUsageForRange(safeDays);
    if (records == null) return null;

    final end = DateTimeUtils.startOfDay(DateTime.now());
    final start = end.subtract(Duration(days: safeDays - 1));
    await _localDataSource.replaceRange(
      records: records,
      startDate: DateTimeUtils.dayKey(start),
      endDate: DateTimeUtils.dayKey(end),
    );
    return records;
  }

  Future<List<UsageRecord>> getForDate(DateTime date) {
    return _localDataSource.getForDate(DateTimeUtils.dayKey(date));
  }

  Future<List<UsageRecord>> getForRange(DateTime start, DateTime end) {
    return _localDataSource.getForRange(
      DateTimeUtils.dayKey(start),
      DateTimeUtils.dayKey(end),
    );
  }

  Future<bool> openApplication(String packageName) =>
      _platformDataSource.openApplication(packageName);

  Future<Map<String, Object?>?> consumePendingBlockerEvent() =>
      _platformDataSource.consumePendingBlockerEvent();
}

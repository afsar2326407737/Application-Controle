import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unloop/core/utils/date_time_utils.dart';
import 'package:unloop/data/datasources/android_usage_data_source.dart';
import 'package:unloop/data/datasources/usage_local_data_source.dart';
import 'package:unloop/data/models/usage_record.dart';
import 'package:unloop/data/repositories/usage_repository.dart';

class _MockUsageLocalDataSource extends Mock implements UsageLocalDataSource {}

class _MockAndroidUsageDataSource extends Mock
    implements AndroidUsageDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(<UsageRecord>[]);
  });

  test(
    'atomically replaces the requested cache window after a valid sync',
    () async {
      final local = _MockUsageLocalDataSource();
      final platform = _MockAndroidUsageDataSource();
      final repository = UsageRepository(local, platform);
      final now = DateTime.now();
      final records = [
        UsageRecord(
          packageName: 'com.google.android.youtube',
          applicationName: 'YouTube',
          date: '2026-09-25',
          startTime: now,
          duration: const Duration(minutes: 7),
        ),
      ];
      when(platform.hasUsageAccess).thenAnswer((_) async => true);
      when(() => platform.getUsageForRange(7)).thenAnswer((_) async => records);
      when(
        () => local.replaceRange(
          records: any(named: 'records'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.syncRecentUsage();

      expect(result, records);
      final today = DateTimeUtils.startOfDay(DateTime.now());
      final expectedStart = today.subtract(const Duration(days: 6));
      verify(
        () => local.replaceRange(
          records: records,
          startDate: DateTimeUtils.dayKey(expectedStart),
          endDate: DateTimeUtils.dayKey(today),
        ),
      ).called(1);
    },
  );

  test('does not clear cached history when Android cannot answer', () async {
    final local = _MockUsageLocalDataSource();
    final platform = _MockAndroidUsageDataSource();
    final repository = UsageRepository(local, platform);
    when(platform.hasUsageAccess).thenAnswer((_) async => true);
    when(() => platform.getUsageForRange(7)).thenAnswer((_) async => null);

    final result = await repository.syncRecentUsage();

    expect(result, isNull);
    verifyNever(
      () => local.replaceRange(
        records: any(named: 'records'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    );
  });

  test(
    'a successful empty result clears stale rows in the cache window',
    () async {
      final local = _MockUsageLocalDataSource();
      final platform = _MockAndroidUsageDataSource();
      final repository = UsageRepository(local, platform);
      when(platform.hasUsageAccess).thenAnswer((_) async => true);
      when(() => platform.getUsageForRange(7)).thenAnswer((_) async => []);
      when(
        () => local.replaceRange(
          records: any(named: 'records'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.syncRecentUsage();

      expect(result, isEmpty);
      verify(
        () => local.replaceRange(
          records: [],
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).called(1);
    },
  );
}

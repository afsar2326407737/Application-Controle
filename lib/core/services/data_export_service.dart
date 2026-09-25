import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/datasources/usage_local_data_source.dart';
import '../../data/models/user_settings.dart';
import '../../data/repositories/focus_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/urge_repository.dart';
import '../utils/date_time_utils.dart';

class DataExportService {
  const DataExportService();

  Future<File> createExport({
    required SettingsRepository settingsRepository,
    required UsageLocalDataSource usageDataSource,
    required FocusRepository focusRepository,
    required UrgeRepository urgeRepository,
  }) async {
    final start = DateTimeUtils.startOfDay(
      DateTime.now().subtract(const Duration(days: 90)),
    );
    final end = DateTimeUtils.endOfDay(DateTime.now());
    final usage = await usageDataSource.getForRange(
      DateTimeUtils.dayKey(start),
      DateTimeUtils.dayKey(end),
    );
    final sessions = await focusRepository.getForRange(start, end);
    final urges = await urgeRepository.getForRange(start, end);
    final settings = settingsRepository.load();
    final payload = <String, Object?>{
      'format': 'unloop-local-export',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'privacy': 'This export contains only local Unloop history.',
      'settings': _settingsToJson(settings),
      'usage': usage.map((item) => item.toMap()).toList(),
      'focusSessions': sessions.map((item) => item.toMap()).toList(),
      'urgeLogs': urges.map((item) => item.toMap()).toList(),
    };

    final directory = await getTemporaryDirectory();
    final date = DateTimeUtils.dayKey(DateTime.now());
    final file = File('${directory.path}/unloop-export-$date.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    return file;
  }

  Future<void> shareFile(File file, {Rect? origin}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        title: 'Unloop local data export',
        text: 'A private, local-only Unloop data export.',
        sharePositionOrigin: origin,
      ),
    );
  }

  Map<String, Object?> _settingsToJson(UserSettings settings) {
    final map = settings.toJson();
    map.remove('selectedPackages');
    map.remove('selectedAppNames');
    return map;
  }
}

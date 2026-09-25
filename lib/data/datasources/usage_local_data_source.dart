import 'package:sqflite/sqflite.dart';

import '../../core/services/app_database.dart';
import '../models/usage_record.dart';

class UsageLocalDataSource {
  UsageLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  /// Replaces a date window atomically. This is intentionally not an upsert:
  /// if Android reports no usage for an app, its old cached value must not
  /// survive a successful refresh.
  Future<void> replaceRange({
    required List<UsageRecord> records,
    required String startDate,
    required String endDate,
  }) async {
    final db = await _appDatabase.database;
    await db.transaction((transaction) async {
      await transaction.delete(
        'usage_records',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [startDate, endDate],
      );
      for (final record in records) {
        if (record.date.compareTo(startDate) < 0 ||
            record.date.compareTo(endDate) > 0) {
          continue;
        }
        await transaction.insert(
          'usage_records',
          record.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<UsageRecord>> getForDate(String date) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'usage_records',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'duration_ms DESC',
    );
    return rows.map(UsageRecord.fromMap).toList();
  }

  Future<List<UsageRecord>> getForRange(
    String startDate,
    String endDate,
  ) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'usage_records',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC, duration_ms DESC',
    );
    return rows.map(UsageRecord.fromMap).toList();
  }
}

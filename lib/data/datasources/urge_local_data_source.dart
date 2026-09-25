import 'package:sqflite/sqflite.dart';

import '../../core/services/app_database.dart';
import '../models/urge_log.dart';

class UrgeLocalDataSource {
  UrgeLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<void> upsert(UrgeLog log) async {
    final db = await _appDatabase.database;
    await db.insert(
      'urge_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<UrgeLog>> getForRange(DateTime start, DateTime end) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'urge_logs',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'timestamp DESC',
    );
    return rows.map(UrgeLog.fromMap).toList();
  }
}

import 'package:sqflite/sqflite.dart';

import '../../core/services/app_database.dart';
import '../models/focus_session.dart';

class FocusLocalDataSource {
  FocusLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<void> upsert(FocusSession session) async {
    final db = await _appDatabase.database;
    await db.insert(
      'focus_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FocusSession>> getAll() async {
    final db = await _appDatabase.database;
    final rows = await db.query('focus_sessions', orderBy: 'start_time DESC');
    return rows.map(FocusSession.fromMap).toList();
  }

  Future<List<FocusSession>> getForDate(String date) async {
    final db = await _appDatabase.database;
    final start = DateTime.parse('${date}T00:00:00');
    final end = start.add(const Duration(days: 1));
    final rows = await db.query(
      'focus_sessions',
      where: 'start_time >= ? AND start_time < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'start_time DESC',
    );
    return rows.map(FocusSession.fromMap).toList();
  }
}

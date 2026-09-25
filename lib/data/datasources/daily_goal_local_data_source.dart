import 'package:sqflite/sqflite.dart';

import '../../core/services/app_database.dart';
import '../models/daily_goal.dart';

class DailyGoalLocalDataSource {
  DailyGoalLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<void> upsert(DailyGoal goal) async {
    final db = await _appDatabase.database;
    await db.insert(
      'daily_goals',
      goal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

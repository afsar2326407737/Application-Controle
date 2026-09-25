import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';

class AppDatabase {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasePath = await getDatabasesPath();
    _database = await openDatabase(
      path.join(databasePath, AppConstants.databaseName),
      version: AppConstants.databaseVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createSchema,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Version 1 usage rows used a timestamp span and may contain inflated
        // background time. They are derived data, so purge only this cache and
        // let the next successful Usage Access sync rebuild it.
        if (oldVersion < 2) {
          await db.delete('usage_records');
        }
      },
    );
    return _database!;
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usage_records (
        package_name TEXT NOT NULL,
        application_name TEXT NOT NULL,
        date TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        duration_ms INTEGER NOT NULL,
        is_foreground INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (date, package_name)
      )
    ''');
    await db.execute('''
      CREATE TABLE focus_sessions (
        id TEXT PRIMARY KEY,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        planned_duration INTEGER NOT NULL,
        completed_duration INTEGER NOT NULL,
        intention TEXT NOT NULL,
        status TEXT NOT NULL,
        avoided_packages TEXT NOT NULL DEFAULT '[]',
        is_strict INTEGER NOT NULL DEFAULT 0,
        interruption_count INTEGER NOT NULL DEFAULT 0,
        accumulated_focus_seconds INTEGER NOT NULL DEFAULT 0,
        last_resumed_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE urge_logs (
        id TEXT PRIMARY KEY,
        timestamp INTEGER NOT NULL,
        feeling TEXT NOT NULL,
        wait_minutes INTEGER NOT NULL,
        alternative TEXT NOT NULL,
        decision TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE daily_goals (
        date TEXT PRIMARY KEY,
        screen_time_limit INTEGER NOT NULL,
        focus_time_target INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX usage_records_date_idx ON usage_records(date)',
    );
    await db.execute(
      'CREATE INDEX focus_sessions_start_idx ON focus_sessions(start_time)',
    );
    await db.execute(
      'CREATE INDEX urge_logs_timestamp_idx ON urge_logs(timestamp)',
    );
  }

  Future<void> clearUserData() async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.delete('usage_records');
      await transaction.delete('focus_sessions');
      await transaction.delete('urge_logs');
      await transaction.delete('daily_goals');
    });
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

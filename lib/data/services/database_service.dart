import 'package:sqflite/sqflite.dart';

class DatabaseService {
  final Database _db;

  DatabaseService(this._db);

  static Future<DatabaseService> open(String path, {required Future<void> Function(Database, int) onCreate}) async {
    final db = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.rawQuery('PRAGMA journal_mode = WAL');
        await db.rawQuery('PRAGMA busy_timeout = 3000');
      },
      onCreate: (db, version) => onCreate(db, version),
    );
    return DatabaseService(db);
  }

  Future<int> insert(String table, Map<String, Object?> values) => _db.insert(table, values);

  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs}) =>
      _db.update(table, values, where: where, whereArgs: whereArgs);

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) =>
      _db.delete(table, where: where, whereArgs: whereArgs);

  Future<List<Map<String, Object?>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy}) =>
      _db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
}

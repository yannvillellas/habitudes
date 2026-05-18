import 'package:sqflite/sqflite.dart';

import '../../domain/models/habit.dart';
import '../../domain/models/habit_completion.dart';
import '../../domain/models/result.dart';
import '../repositories/habit_repository.dart';
import '../services/database_service.dart';

class HabitRepositorySqflite implements HabitRepository {
  static const _habitsTable = 'habits';
  static const _completionsTable = 'habit_completions';
  static const _idColumn = 'id';
  static const _nameColumn = 'name';
  static const _createdAtColumn = 'created_at';
  static const _sortOrderColumn = 'sort_order';
  static const _habitIdColumn = 'habit_id';
  static const _dateColumn = 'date';

  final DatabaseService _service;

  HabitRepositorySqflite({required DatabaseService service}) : _service = service;

  static Future<void> createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_habitsTable(
        $_idColumn TEXT PRIMARY KEY,
        $_nameColumn TEXT NOT NULL,
        $_createdAtColumn INTEGER NOT NULL,
        $_sortOrderColumn INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_completionsTable(
        $_habitIdColumn TEXT NOT NULL,
        $_dateColumn TEXT NOT NULL,
        PRIMARY KEY ($_habitIdColumn, $_dateColumn)
      )
    ''');
  }

  @override
  Future<Result<void>> saveHabit(Habit habit) async {
    try {
      final existing = await _service.query(_habitsTable, where: '$_idColumn = ?', whereArgs: [habit.id]);

      if (existing.isEmpty) {
        final maxOrder = await _service.query(_habitsTable, orderBy: '$_sortOrderColumn DESC');
        final nextOrder = maxOrder.isEmpty ? 0 : (maxOrder.first[_sortOrderColumn] as int) + 1;

        await _service.insert(_habitsTable, {
          _idColumn: habit.id,
          _nameColumn: habit.name,
          _createdAtColumn: habit.createdAt.millisecondsSinceEpoch,
          _sortOrderColumn: nextOrder,
        });
      } else {
        await _service.update(
          _habitsTable,
          {_nameColumn: habit.name, _createdAtColumn: habit.createdAt.millisecondsSinceEpoch},
          where: '$_idColumn = ?',
          whereArgs: [habit.id],
        );
      }
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<List<Habit>>> listHabits() async {
    try {
      final rows = await _service.query(_habitsTable, orderBy: '$_sortOrderColumn ASC');
      return Result.ok(rows.map(_rowToHabit).toList(growable: false));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> deleteHabit(String habitId) async {
    try {
      await _service.delete(_completionsTable, where: '$_habitIdColumn = ?', whereArgs: [habitId]);
      await _service.delete(_habitsTable, where: '$_idColumn = ?', whereArgs: [habitId]);
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> recordCompletion(HabitCompletion completion) async {
    final date = _dateToText(completion.date);
    try {
      await _service.insert(_completionsTable, {_habitIdColumn: completion.habitId, _dateColumn: date});
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> deleteCompletion(String habitId, DateTime date) async {
    try {
      await _service.delete(
        _completionsTable,
        where: '$_habitIdColumn = ? AND $_dateColumn = ?',
        whereArgs: [habitId, _dateToText(date)],
      );
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<List<HabitCompletion>>> listCompletions(String habitId) async {
    try {
      final rows = await _service.query(
        _completionsTable,
        where: '$_habitIdColumn = ?',
        whereArgs: [habitId],
        orderBy: '$_dateColumn ASC',
      );
      return Result.ok(rows.map(_rowToCompletion).toList(growable: false));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Habit _rowToHabit(Map<String, Object?> row) {
    return Habit(
      id: row[_idColumn]! as String,
      name: row[_nameColumn]! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row[_createdAtColumn]! as int, isUtc: true),
    );
  }

  HabitCompletion _rowToCompletion(Map<String, Object?> row) {
    return HabitCompletion(habitId: row[_habitIdColumn]! as String, date: _dateFromText(row[_dateColumn]! as String));
  }

  static String _dateToText(DateTime date) {
    final utc = DateTime.utc(date.year, date.month, date.day);
    return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}';
  }

  static DateTime _dateFromText(String text) {
    final parts = text.split('-');
    return DateTime.utc(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
}

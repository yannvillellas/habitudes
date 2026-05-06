import 'package:sqflite/sqflite.dart';

import '../../domain/models/habit.dart';
import '../../domain/models/habit_completion.dart';
import '../repositories/habit_repository.dart';
import '../services/database_service.dart';

class HabitRepositorySqflite implements HabitRepository {
  final DatabaseService _service;

  HabitRepositorySqflite({required DatabaseService service}) : _service = service;

  static Future<void> createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_completions(
        habit_id TEXT NOT NULL,
        date TEXT NOT NULL,
        PRIMARY KEY (habit_id, date)
      )
    ''');
  }

  @override
  Future<void> saveHabit(Habit habit) async {
    final existing = await _service.query('habits', where: 'id = ?', whereArgs: [habit.id]);

    if (existing.isEmpty) {
      final maxOrder = await _service.query('habits', orderBy: 'sort_order DESC');
      final nextOrder = maxOrder.isEmpty ? 0 : (maxOrder.first['sort_order'] as int) + 1;

      await _service.insert('habits', {
        'id': habit.id,
        'name': habit.name,
        'color_value': habit.colorValue,
        'created_at': habit.createdAt.millisecondsSinceEpoch,
        'is_archived': habit.isArchived ? 1 : 0,
        'sort_order': nextOrder,
      });
    } else {
      await _service.update(
        'habits',
        {
          'name': habit.name,
          'color_value': habit.colorValue,
          'created_at': habit.createdAt.millisecondsSinceEpoch,
          'is_archived': habit.isArchived ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [habit.id],
      );
    }
  }

  @override
  Future<List<Habit>> listHabits({bool includeArchived = false}) async {
    String? where;
    if (!includeArchived) {
      where = 'is_archived = 0';
    }

    final rows = await _service.query('habits', where: where, orderBy: 'sort_order ASC');

    return rows.map(_rowToHabit).toList(growable: false);
  }

  @override
  Future<void> archiveHabit(String habitId) async {
    await _service.update('habits', {'is_archived': 1}, where: 'id = ?', whereArgs: [habitId]);
  }

  @override
  Future<void> recordCompletion(HabitCompletion completion) async {
    final date = _dateToText(completion.date);
    try {
      await _service.insert('habit_completions', {'habit_id': completion.habitId, 'date': date});
    } catch (_) {
      // Ignore duplicate (habit_id, date) constraint violations
    }
  }

  @override
  Future<void> deleteCompletion(String habitId, DateTime date) async {
    await _service.delete(
      'habit_completions',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, _dateToText(date)],
    );
  }

  @override
  Future<List<HabitCompletion>> listCompletions(String habitId) async {
    final rows = await _service.query(
      'habit_completions',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'date ASC',
    );

    return rows.map(_rowToCompletion).toList(growable: false);
  }

  Habit _rowToHabit(Map<String, Object?> row) {
    return Habit(
      id: row['id']! as String,
      name: row['name']! as String,
      colorValue: row['color_value']! as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int, isUtc: true),
      isArchived: (row['is_archived'] as int) == 1,
    );
  }

  HabitCompletion _rowToCompletion(Map<String, Object?> row) {
    return HabitCompletion(habitId: row['habit_id']! as String, date: _dateFromText(row['date']! as String));
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

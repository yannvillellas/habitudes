import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/data/repositories/habit_repository.dart';
import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/domain/models/habit_completion.dart';
import 'package:habitudes/domain/models/result.dart';

void runHabitRepositoryContract(Future<HabitRepository> Function() createRepository) {
  late HabitRepository repository;

  setUp(() async {
    repository = await createRepository();
  });

  test('saves and updates a habit by id', () async {
    final initialHabit = Habit(id: 'habit-1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6));
    final updatedHabit = Habit(id: 'habit-1', name: 'Read 20 pages', createdAt: DateTime.utc(2026, 5, 7));

    await repository.saveHabit(initialHabit);
    await repository.saveHabit(updatedHabit);

    final habits = (await repository.listHabits() as Ok<List<Habit>>).value;

    expect(habits, hasLength(1));
    expect(habits.single.id, updatedHabit.id);
    expect(habits.single.name, updatedHabit.name);
    expect(habits.single.createdAt, updatedHabit.createdAt);
  });

  test('preserves insertion order', () async {
    await repository.saveHabit(Habit(id: 'habit-1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
    await repository.saveHabit(Habit(id: 'habit-2', name: 'Walk', createdAt: DateTime.utc(2026, 5, 6)));
    await repository.saveHabit(Habit(id: 'habit-3', name: 'Meditate', createdAt: DateTime.utc(2026, 5, 6)));

    final habits = (await repository.listHabits() as Ok<List<Habit>>).value;

    expect(habits.map((habit) => habit.id), <String>['habit-1', 'habit-2', 'habit-3']);
  });

  test('records date-only completions and deduplicates same day entries', () async {
    await repository.recordCompletion(HabitCompletion(habitId: 'habit-1', date: DateTime(2026, 5, 6, 10, 30)));
    await repository.recordCompletion(HabitCompletion(habitId: 'habit-1', date: DateTime(2026, 5, 6, 23, 59)));
    await repository.recordCompletion(HabitCompletion(habitId: 'habit-1', date: DateTime(2026, 5, 7, 8, 0)));

    final completions = (await repository.listCompletions('habit-1') as Ok<List<HabitCompletion>>).value;

    expect(completions, hasLength(2));
    expect(completions.first.date, DateTime.utc(2026, 5, 6));
    expect(completions.last.date, DateTime.utc(2026, 5, 7));
  });

  test('keeps completions isolated per habit', () async {
    await repository.recordCompletion(HabitCompletion(habitId: 'habit-1', date: DateTime(2026, 5, 6)));
    await repository.recordCompletion(HabitCompletion(habitId: 'habit-2', date: DateTime(2026, 5, 7)));

    final habit1Completions = (await repository.listCompletions('habit-1') as Ok<List<HabitCompletion>>).value;
    final habit2Completions = (await repository.listCompletions('habit-2') as Ok<List<HabitCompletion>>).value;

    expect(habit1Completions, hasLength(1));
    expect(habit2Completions, hasLength(1));
    expect(habit1Completions.single.habitId, 'habit-1');
    expect(habit2Completions.single.habitId, 'habit-2');
  });

  test('deletes a date-only completion and ignores missing completions', () async {
    await repository.recordCompletion(HabitCompletion(habitId: 'habit-1', date: DateTime(2026, 5, 6, 10, 30)));
    await repository.recordCompletion(HabitCompletion(habitId: 'habit-1', date: DateTime(2026, 5, 7, 10, 30)));

    await repository.deleteCompletion('habit-1', DateTime(2026, 5, 6, 0, 0));
    await repository.deleteCompletion('habit-1', DateTime(2026, 5, 9, 0, 0));

    final completions = (await repository.listCompletions('habit-1') as Ok<List<HabitCompletion>>).value;

    expect(completions, hasLength(1));
    expect(completions.single.date, DateTime.utc(2026, 5, 7));
  });

  test('returns empty completions for unknown habits', () async {
    final completions = (await repository.listCompletions('missing-habit') as Ok<List<HabitCompletion>>).value;

    expect(completions, isEmpty);
  });
}

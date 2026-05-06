import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/data/repositories/habit_repository.dart';
import 'package:habitudes/domain/habit.dart';
import 'package:habitudes/domain/habit_completion.dart';

import '../testing/fakes/fake_habit_repository.dart';

void main() {
  group('HabitRepository', () {
    late HabitRepository repository;

    setUp(() {
      repository = FakeHabitRepository();
    });

    test('saves and updates a habit by id', () async {
      final initialHabit = Habit(
        id: 'habit-1',
        name: 'Read',
        colorValue: 0xFF00FF00,
        createdAt: DateTime.utc(2026, 5, 6),
      );
      final updatedHabit = Habit(
        id: 'habit-1',
        name: 'Read 20 pages',
        colorValue: 0xFF0000FF,
        createdAt: DateTime.utc(2026, 5, 7),
      );

      await repository.saveHabit(initialHabit);
      await repository.saveHabit(updatedHabit);

      final habits = await repository.listHabits();

      expect(habits, hasLength(1));
      expect(habits.single.id, updatedHabit.id);
      expect(habits.single.name, updatedHabit.name);
      expect(habits.single.colorValue, updatedHabit.colorValue);
      expect(habits.single.createdAt, updatedHabit.createdAt);
    });

    test('preserves insertion order for active habits', () async {
      await repository.saveHabit(
        Habit(id: 'habit-1', name: 'Read', colorValue: 0xFF00FF00, createdAt: DateTime.utc(2026, 5, 6)),
      );
      await repository.saveHabit(
        Habit(id: 'habit-2', name: 'Walk', colorValue: 0xFF0000FF, createdAt: DateTime.utc(2026, 5, 6)),
      );
      await repository.saveHabit(
        Habit(id: 'habit-3', name: 'Meditate', colorValue: 0xFFFF0000, createdAt: DateTime.utc(2026, 5, 6)),
      );

      final habits = await repository.listHabits();

      expect(habits.map((habit) => habit.id), <String>['habit-1', 'habit-2', 'habit-3']);
    });

    test('filters archived habits unless requested', () async {
      await repository.saveHabit(
        Habit(id: 'habit-1', name: 'Read', colorValue: 0xFF00FF00, createdAt: DateTime.utc(2026, 5, 6)),
      );
      await repository.saveHabit(
        Habit(id: 'habit-2', name: 'Walk', colorValue: 0xFF0000FF, createdAt: DateTime.utc(2026, 5, 6)),
      );
      await repository.archiveHabit('habit-2');

      final activeHabits = await repository.listHabits();
      final allHabits = await repository.listHabits(includeArchived: true);

      expect(activeHabits, hasLength(1));
      expect(activeHabits.single.id, 'habit-1');
      expect(allHabits, hasLength(2));
      expect(allHabits.last.isArchived, isTrue);
    });

    test('archiveHabit leaves unknown habits untouched', () async {
      await repository.archiveHabit('missing-habit');

      final habits = await repository.listHabits(includeArchived: true);
      expect(habits, isEmpty);
    });

    test('records date-only completions and deduplicates same day entries', () async {
      await repository.recordCompletion(HabitCompletion(habitId: 'habit-1', date: DateTime(2026, 5, 6, 10, 30)));
      await repository.recordCompletion(HabitCompletion(habitId: 'habit-1', date: DateTime(2026, 5, 6, 23, 59)));
      await repository.recordCompletion(HabitCompletion(habitId: 'habit-1', date: DateTime(2026, 5, 7, 8, 0)));

      final completions = await repository.listCompletions('habit-1');

      expect(completions, hasLength(2));
      expect(completions.first.date, DateTime.utc(2026, 5, 6));
      expect(completions.last.date, DateTime.utc(2026, 5, 7));
    });

    test('keeps completions isolated per habit', () async {
      await repository.recordCompletion(HabitCompletion(habitId: 'habit-1', date: DateTime(2026, 5, 6)));
      await repository.recordCompletion(HabitCompletion(habitId: 'habit-2', date: DateTime(2026, 5, 7)));

      final habit1Completions = await repository.listCompletions('habit-1');
      final habit2Completions = await repository.listCompletions('habit-2');

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

      final completions = await repository.listCompletions('habit-1');

      expect(completions, hasLength(1));
      expect(completions.single.date, DateTime.utc(2026, 5, 7));
    });

    test('returns empty completions for unknown habits', () async {
      final completions = await repository.listCompletions('missing-habit');

      expect(completions, isEmpty);
    });
  });
}

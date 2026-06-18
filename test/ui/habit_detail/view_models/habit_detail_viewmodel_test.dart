import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/domain/models/habit_completion.dart';
import 'package:habitudes/domain/models/result.dart';
import 'package:habitudes/ui/habit_detail/view_models/habit_detail_viewmodel.dart';

import '../../../../testing/fakes/fake_habit_repository.dart';

void main() {
  final today = DateTime.utc(2026, 6, 18);
  group('HabitDetailViewModel', () {
    late FakeHabitRepository repository;

    setUp(() {
      repository = FakeHabitRepository();
    });

    test('loads habit by id', () async {
      await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
      await repository.saveHabit(Habit(id: 'h2', name: 'Walk', createdAt: DateTime.utc(2026, 5, 6)));

      final viewModel = HabitDetailViewModel(habitRepository: repository, now: () => today, habitId: 'h2');
      await viewModel.load.execute();

      expect(viewModel.habit?.name, 'Walk');
    });

    test('load sets error when habit not found', () async {
      final viewModel = HabitDetailViewModel(habitRepository: repository, now: () => today, habitId: 'missing');
      await viewModel.load.execute();

      expect(viewModel.load.error, isTrue);
      expect(viewModel.habit, isNull);
    });

    test('delete removes habit and reports success', () async {
      await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
      final viewModel = HabitDetailViewModel(habitRepository: repository, now: () => today, habitId: 'h1');

      await viewModel.delete.execute();

      expect(viewModel.delete.completed, isTrue);
      final habits = (await repository.listHabits() as Ok<List<Habit>>).value;
      expect(habits, isEmpty);
    });

    group('score', () {
      test('score increases after adding a completion', () async {
        final createdAt = DateTime.utc(2026, 6, 1);
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: createdAt));
        for (int i = 0; i < 16; i++) {
          await repository.recordCompletion(HabitCompletion(habitId: 'h1', date: DateTime.utc(2026, 6, 1 + i)));
        }
        final viewModel = HabitDetailViewModel(habitRepository: repository, now: () => today, habitId: 'h1');
        await viewModel.load.execute();
        await viewModel.loadCompletions.execute();

        final scoreBefore = viewModel.score;

        await viewModel.toggleDayCompletion.execute(DateTime.utc(2026, 6, 17));

        expect(viewModel.score, greaterThan(scoreBefore));
      });

      test('score decreases after removing a completion', () async {
        final createdAt = DateTime.utc(2026, 6, 1);
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: createdAt));
        for (int i = 0; i < 16; i++) {
          await repository.recordCompletion(HabitCompletion(habitId: 'h1', date: DateTime.utc(2026, 6, 1 + i)));
        }
        final viewModel = HabitDetailViewModel(habitRepository: repository, now: () => today, habitId: 'h1');
        await viewModel.load.execute();
        await viewModel.loadCompletions.execute();

        final scoreBefore = viewModel.score;

        await viewModel.toggleDayCompletion.execute(DateTime.utc(2026, 6, 10));

        expect(viewModel.score, lessThan(scoreBefore));
      });

      test('score recalculates after reload', () async {
        final createdAt = DateTime.utc(2026, 6, 1);
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: createdAt));
        for (int i = 0; i < 16; i++) {
          await repository.recordCompletion(HabitCompletion(habitId: 'h1', date: DateTime.utc(2026, 6, 1 + i)));
        }
        final viewModel = HabitDetailViewModel(habitRepository: repository, now: () => today, habitId: 'h1');
        await viewModel.load.execute();
        await viewModel.loadCompletions.execute();

        final scoreBefore = viewModel.score;

        await repository.recordCompletion(HabitCompletion(habitId: 'h1', date: DateTime.utc(2026, 6, 17)));
        await viewModel.loadCompletions.execute();

        expect(viewModel.score, greaterThan(scoreBefore));
      });
    });

    group('loadCompletions', () {
      test('returns completions sorted by date', () async {
        await repository.recordCompletion(HabitCompletion(habitId: 'h1', date: DateTime(2026, 6, 9)));
        await repository.recordCompletion(HabitCompletion(habitId: 'h1', date: DateTime(2026, 5, 6)));
        final viewModel = HabitDetailViewModel(habitRepository: repository, now: () => today, habitId: 'h1');

        await viewModel.loadCompletions.execute();

        expect(viewModel.completions, hasLength(2));
        expect(viewModel.completions.first.date, DateTime.utc(2026, 5, 6));
        expect(viewModel.completions.last.date, DateTime.utc(2026, 6, 9));
      });

      test('returns empty list when no completions', () async {
        final viewModel = HabitDetailViewModel(habitRepository: repository, now: () => today, habitId: 'h1');

        await viewModel.loadCompletions.execute();

        expect(viewModel.completions, isEmpty);
      });

      test('preserves previous completions on error', () async {
        await repository.recordCompletion(HabitCompletion(habitId: 'h1', date: DateTime(2026, 6, 9)));
        final viewModel = HabitDetailViewModel(habitRepository: repository, now: () => today, habitId: 'h1');
        await viewModel.loadCompletions.execute();
        expect(viewModel.completions, hasLength(1));
      });
    });
  });
}

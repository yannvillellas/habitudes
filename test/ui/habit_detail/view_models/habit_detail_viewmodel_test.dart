import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/domain/models/result.dart';
import 'package:habitudes/ui/habit_detail/view_models/habit_detail_viewmodel.dart';

import '../../../../testing/fakes/fake_habit_repository.dart';

void main() {
  group('HabitDetailViewModel', () {
    late FakeHabitRepository repository;

    setUp(() {
      repository = FakeHabitRepository();
    });

    test('loads habit by id', () async {
      await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
      await repository.saveHabit(Habit(id: 'h2', name: 'Walk', createdAt: DateTime.utc(2026, 5, 6)));

      final viewModel = HabitDetailViewModel(habitRepository: repository, habitId: 'h2');
      await viewModel.load.execute();

      expect(viewModel.habit?.name, 'Walk');
    });

    test('load sets error when habit not found', () async {
      final viewModel = HabitDetailViewModel(habitRepository: repository, habitId: 'missing');
      await viewModel.load.execute();

      expect(viewModel.load.error, isTrue);
      expect(viewModel.habit, isNull);
    });

    test('delete removes habit and reports success', () async {
      await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
      final viewModel = HabitDetailViewModel(habitRepository: repository, habitId: 'h1');

      await viewModel.delete.execute();

      expect(viewModel.delete.completed, isTrue);
      final habits = (await repository.listHabits() as Ok<List<Habit>>).value;
      expect(habits, isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/domain/models/result.dart';
import 'package:habitudes/ui/habit_list/view_models/habit_list_viewmodel.dart';

import '../../../../testing/fakes/fake_habit_repository.dart';

void main() {
  group('HabitListViewModel', () {
    late FakeHabitRepository repository;
    late HabitListViewModel viewModel;

    setUp(() async {
      repository = FakeHabitRepository();
      viewModel = HabitListViewModel(habitRepository: repository);
      await viewModel.load.execute();
    });

    test('loads empty habits on creation', () {
      expect(viewModel.habits, isEmpty);
    });

    test('exposes habits from repository after load', () async {
      await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
      await repository.saveHabit(Habit(id: 'h2', name: 'Walk', createdAt: DateTime.utc(2026, 5, 6)));

      await viewModel.load.execute();

      expect(viewModel.habits, hasLength(2));
      expect(viewModel.habits.first.id, 'h1');
      expect(viewModel.habits.last.id, 'h2');
    });

    test('load picks up new habits added to repository', () async {
      await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
      await viewModel.load.execute();
      expect(viewModel.habits, hasLength(1));

      await repository.saveHabit(Habit(id: 'h2', name: 'Walk', createdAt: DateTime.utc(2026, 5, 6)));
      await viewModel.load.execute();

      expect(viewModel.habits, hasLength(2));
    });

    test('addHabit saves habit and reloads state', () async {
      await viewModel.addHabit.execute('Read');

      final result = await repository.listHabits();
      final habits = (result as Ok<List<Habit>>).value;
      expect(habits, hasLength(1));
      expect(habits.single.name, 'Read');
      expect(habits.single.createdAt.isUtc, isTrue);
      expect(viewModel.habits, hasLength(1));
    });

    test('addHabit ignores empty input', () async {
      await viewModel.addHabit.execute('   ');

      final result = await repository.listHabits();
      final habits = (result as Ok<List<Habit>>).value;
      expect(habits, isEmpty);
    });

    test('canSaveHabit rejects empty and whitespace', () {
      expect(viewModel.canSaveHabit(''), isFalse);
      expect(viewModel.canSaveHabit('   '), isFalse);
    });

    test('canSaveHabit accepts non-empty text', () {
      expect(viewModel.canSaveHabit('Read'), isTrue);
      expect(viewModel.canSaveHabit('  Read  '), isTrue);
    });
  });
}

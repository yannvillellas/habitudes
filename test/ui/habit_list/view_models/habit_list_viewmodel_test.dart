import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/ui/habit_list/view_models/habit_list_viewmodel.dart';

import '../../../../testing/fakes/fake_habit_repository.dart';

void main() {
  group('HabitListViewModel', () {
    late FakeHabitRepository repository;
    late HabitListViewModel viewModel;

    setUp(() async {
      repository = FakeHabitRepository();
      viewModel = HabitListViewModel(habitRepository: repository);
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

    test('load exposes error when repository fails', () async {
      repository.listHabitsError = Exception('test error');

      await viewModel.load.execute();

      expect(viewModel.load.error, isTrue);
    });

    test('preserves existing habits on reload failure', () async {
      await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
      await viewModel.load.execute();
      expect(viewModel.habits, hasLength(1));

      repository.listHabitsError = Exception('test error');
      await viewModel.load.execute();

      expect(viewModel.habits, hasLength(1));
      expect(viewModel.load.error, isTrue);
    });
  });
}

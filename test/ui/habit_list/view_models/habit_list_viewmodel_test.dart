import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/ui/habit_list/view_models/habit_list_viewmodel.dart';

import '../../../../testing/fakes/fake_habit_repository.dart';

void main() {
  group('HabitListViewModel', () {
    late FakeHabitRepository repository;
    late HabitListViewModel viewModel;

    setUp(() {
      repository = FakeHabitRepository();
      viewModel = HabitListViewModel(habitRepository: repository);
    });

    test('loads active habits from repository on creation', () {
      expect(viewModel.habits, isEmpty);
    });

    test('exposes habits from repository', () async {
      await repository.saveHabit(
        Habit(id: 'h1', name: 'Read', colorValue: 0xFF00FF00, createdAt: DateTime.utc(2026, 5, 6)),
      );
      await repository.saveHabit(
        Habit(id: 'h2', name: 'Walk', colorValue: 0xFF0000FF, createdAt: DateTime.utc(2026, 5, 6)),
      );

      viewModel.load();

      expect(viewModel.habits, hasLength(2));
      expect(viewModel.habits.first.id, 'h1');
      expect(viewModel.habits.last.id, 'h2');
    });

    test('filters archived habits by default', () async {
      await repository.saveHabit(
        Habit(id: 'h1', name: 'Read', colorValue: 0xFF00FF00, createdAt: DateTime.utc(2026, 5, 6)),
      );
      await repository.saveHabit(
        Habit(id: 'h2', name: 'Walk', colorValue: 0xFF0000FF, createdAt: DateTime.utc(2026, 5, 6)),
      );
      await repository.archiveHabit('h2');

      viewModel.load();

      expect(viewModel.habits, hasLength(1));
      expect(viewModel.habits.single.id, 'h1');
    });

    test('can show archived habits when toggled', () async {
      await repository.saveHabit(
        Habit(id: 'h1', name: 'Read', colorValue: 0xFF00FF00, createdAt: DateTime.utc(2026, 5, 6)),
      );
      await repository.saveHabit(
        Habit(id: 'h2', name: 'Walk', colorValue: 0xFF0000FF, createdAt: DateTime.utc(2026, 5, 6)),
      );
      await repository.archiveHabit('h2');

      viewModel.toggleShowArchived();
      viewModel.load();

      expect(viewModel.habits, hasLength(2));
      expect(viewModel.showArchived, isTrue);
    });

    test('toggleShowArchived notifies listeners', () {
      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.toggleShowArchived();

      expect(notified, isTrue);
    });
  });
}

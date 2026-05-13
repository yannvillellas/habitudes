import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/domain/models/result.dart';
import 'package:habitudes/ui/create_habit/view_models/create_habit_viewmodel.dart';

import '../../../../testing/fakes/fake_habit_repository.dart';

CreateHabitViewModel createViewModel(FakeHabitRepository repository, {VoidCallback? onSaved}) {
  return CreateHabitViewModel(habitRepository: repository, onSaved: onSaved);
}

void main() {
  group('CreateHabitViewModel', () {
    late FakeHabitRepository repository;

    setUp(() {
      repository = FakeHabitRepository();
    });

    test('save habit persists and calls onSaved', () async {
      var saved = false;
      final viewModel = createViewModel(repository, onSaved: () => saved = true);
      await viewModel.save.execute('Read');

      final result = await repository.listHabits();
      final habits = (result as Ok<List<Habit>>).value;
      expect(habits, hasLength(1));
      expect(habits.single.name, 'Read');
      expect(habits.single.createdAt.isUtc, isTrue);
      expect(saved, isTrue);
    });

    test('save ignores empty input', () async {
      final viewModel = createViewModel(repository);
      await viewModel.save.execute('   ');

      final result = await repository.listHabits();
      final habits = (result as Ok<List<Habit>>).value;
      expect(habits, isEmpty);
    });

    test('canSaveHabit rejects empty and whitespace', () {
      expect(createViewModel(repository).canSaveHabit(''), isFalse);
      expect(createViewModel(repository).canSaveHabit('   '), isFalse);
    });

    test('canSaveHabit accepts non-empty text', () {
      expect(createViewModel(repository).canSaveHabit('Read'), isTrue);
      expect(createViewModel(repository).canSaveHabit('  Read  '), isTrue);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/domain/models/habit_completion.dart';
import 'package:habitudes/domain/models/result.dart';
import 'package:habitudes/ui/habit_detail/view_models/habit_detail_viewmodel.dart';
import 'package:habitudes/ui/habit_detail/widgets/habit_detail_screen.dart';

import '../../../../testing/fakes/fake_habit_repository.dart';

Widget buildTestWidget(HabitDetailViewModel viewModel) {
  return MaterialApp(home: HabitDetailScreen(viewModel: viewModel));
}

void main() {
  group('HabitDetailScreen', () {
    late FakeHabitRepository repository;

    setUp(() {
      repository = FakeHabitRepository();
    });

    testWidgets('renders habit name in app bar', (tester) async {
      await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
      final viewModel = HabitDetailViewModel(habitRepository: repository, habitId: 'h1');
      await tester.pumpWidget(buildTestWidget(viewModel));

      expect(find.text('Read'), findsOneWidget);
    });

    testWidgets('shows error when habit not found', (tester) async {
      final viewModel = HabitDetailViewModel(habitRepository: repository, habitId: 'missing');
      await tester.pumpWidget(buildTestWidget(viewModel));

      expect(find.text('Habit not found'), findsOneWidget);
    });

    testWidgets('delete action removes habit and pops screen', (tester) async {
      await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
      final viewModel = HabitDetailViewModel(habitRepository: repository, habitId: 'h1');
      await tester.pumpWidget(buildTestWidget(viewModel));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      final habits = (await repository.listHabits());
      if (habits case Ok<List<Habit>>(:final value)) {
        expect(value, isEmpty);
      } else {
        fail('Expected Ok result');
      }

      expect(viewModel.delete.completed, isTrue);
    });

  });
}

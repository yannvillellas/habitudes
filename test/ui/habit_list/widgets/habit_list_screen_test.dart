import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/ui/habit_list/view_models/habit_list_viewmodel.dart';
import 'package:habitudes/ui/habit_list/widgets/habit_list_screen.dart';

import '../../../../testing/fakes/fake_habit_repository.dart';

void main() {
  group('HabitListScreen', () {
    late FakeHabitRepository repository;
    late HabitListViewModel viewModel;

    Widget buildTestWidget() {
      return MaterialApp(home: HabitListScreen(viewModel: viewModel));
    }

    setUp(() async {
      repository = FakeHabitRepository();
      viewModel = HabitListViewModel(habitRepository: repository);
      await viewModel.load();
    });

    testWidgets('shows empty state when no habits', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('No habits yet'), findsOneWidget);
    });

    testWidgets('renders habit names from ViewModel', (tester) async {
      await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
      await repository.saveHabit(Habit(id: 'h2', name: 'Walk', createdAt: DateTime.utc(2026, 5, 6)));
      await viewModel.load();
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Walk'), findsOneWidget);
    });
  });
}

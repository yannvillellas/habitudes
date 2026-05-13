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
      await viewModel.load.execute();
    });

    testWidgets('shows empty state when no habits', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('No habits yet'), findsOneWidget);
    });

    testWidgets('renders habit names from ViewModel', (tester) async {
      await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
      await repository.saveHabit(Habit(id: 'h2', name: 'Walk', createdAt: DateTime.utc(2026, 5, 6)));
      await viewModel.load.execute();
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Walk'), findsOneWidget);
    });

    group('create habit sheet', () {
      testWidgets('FAB opens bottom sheet', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      });

      testWidgets('Save button is disabled when text is empty', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        final saveButton = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Save'));
        expect(saveButton.onPressed, isNull);
      });

      testWidgets('Save button is enabled when text is non-empty', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Read');
        await tester.pump();

        final saveButton = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Save'));
        expect(saveButton.onPressed, isNotNull);
      });

      testWidgets('tapping Save dismisses sheet and saves habit', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Read');
        await tester.pump();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Sheet is dismissed
        expect(find.byType(TextField), findsNothing);
        // Habit was saved — appears in the list
        expect(find.text('Read'), findsOneWidget);
      });
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/l10n/app_localizations.dart';
import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/domain/models/habit_completion.dart';
import 'package:habitudes/ui/create_habit/view_models/create_habit_viewmodel.dart';
import 'package:habitudes/ui/create_habit/widgets/create_habit_screen.dart';
import 'package:habitudes/ui/habit_list/view_models/habit_list_viewmodel.dart';
import 'package:habitudes/ui/habit_list/widgets/habit_list_screen.dart';

import '../../../../testing/fakes/fake_habit_repository.dart';

Widget buildTestWidget(HabitListViewModel viewModel, FakeHabitRepository repository) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: HabitListScreen(
      viewModel: viewModel,
      onTapHabit: (_, _) {},
      onAddHabit: (context) {
        final createViewModel = CreateHabitViewModel(
          habitRepository: repository,
          onSaved: () => viewModel.load.execute(),
        );
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => CreateHabitScreen(viewModel: createViewModel),
        );
      },
    ),
  );
}

void main() {
  final today = DateTime(2026, 6, 9);

  HabitListViewModel createViewModel(FakeHabitRepository repository) {
    return HabitListViewModel(habitRepository: repository, now: () => today);
  }

  group('HabitListScreen', () {
    late FakeHabitRepository repository;
    late HabitListViewModel viewModel;

    setUp(() async {
      repository = FakeHabitRepository();
      viewModel = createViewModel(repository);
      await Future<void>.delayed(Duration.zero);
    });

    testWidgets('shows empty state when no habits', (tester) async {
      await tester.pumpWidget(buildTestWidget(viewModel, repository));

      expect(find.text('No habits yet'), findsOneWidget);
    });

    testWidgets('shows error with retry button on load failure', (tester) async {
      repository.listHabitsError = Exception('test error');
      viewModel = createViewModel(repository);
      await tester.pumpWidget(buildTestWidget(viewModel, repository));

      expect(find.text('Failed to load habits'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('renders habit names from ViewModel', (tester) async {
      await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
      await repository.saveHabit(Habit(id: 'h2', name: 'Walk', createdAt: DateTime.utc(2026, 5, 6)));
      await viewModel.load.execute();
      await tester.pumpWidget(buildTestWidget(viewModel, repository));

      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Walk'), findsOneWidget);
    });

    group('checkbox', () {
      testWidgets('is unchecked when habit not completed today', (tester) async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await viewModel.load.execute();
        await tester.pumpWidget(buildTestWidget(viewModel, repository));

        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, isFalse);
      });

      testWidgets('is checked when habit completed today', (tester) async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await repository.recordCompletion(HabitCompletion(habitId: 'h1', date: today));
        await viewModel.load.execute();
        await tester.pumpWidget(buildTestWidget(viewModel, repository));

        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, isTrue);
      });

      testWidgets('tapping checkbox toggles completion', (tester) async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await viewModel.load.execute();
        await tester.pumpWidget(buildTestWidget(viewModel, repository));

        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, isTrue);
      });

      testWidgets('tapping checked checkbox removes completion', (tester) async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await repository.recordCompletion(HabitCompletion(habitId: 'h1', date: today));
        await viewModel.load.execute();
        await tester.pumpWidget(buildTestWidget(viewModel, repository));

        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, isFalse);
      });
    });

    group('create habit sheet', () {
      testWidgets('FAB opens bottom sheet', (tester) async {
        await tester.pumpWidget(buildTestWidget(viewModel, repository));

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      });

      testWidgets('Save button is disabled when text is empty', (tester) async {
        await tester.pumpWidget(buildTestWidget(viewModel, repository));
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        final saveButton = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Save'));
        expect(saveButton.onPressed, isNull);
      });

      testWidgets('Save button is enabled when text is non-empty', (tester) async {
        await tester.pumpWidget(buildTestWidget(viewModel, repository));
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Read');
        await tester.pump();

        final saveButton = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Save'));
        expect(saveButton.onPressed, isNotNull);
      });

      testWidgets('tapping Save dismisses sheet and saves habit', (tester) async {
        await tester.pumpWidget(buildTestWidget(viewModel, repository));
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

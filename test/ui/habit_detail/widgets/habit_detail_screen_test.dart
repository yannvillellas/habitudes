import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/l10n/app_localizations.dart';
import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/domain/models/result.dart';
import 'package:habitudes/ui/core/sync_notifier.dart';
import 'package:habitudes/ui/habit_detail/view_models/habit_detail_viewmodel.dart';
import 'package:habitudes/ui/habit_detail/widgets/habit_detail_screen.dart';

import '../../../../testing/fakes/fake_habit_repository.dart';
import '../../../../testing/fakes/fake_widget_sync_repository.dart';

Widget buildTestWidget(HabitDetailViewModel viewModel) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: HabitDetailScreen(viewModel: viewModel),
  );
}

void main() {
  final today = DateTime.utc(2026, 6, 18);
  group('HabitDetailScreen', () {
    late FakeHabitRepository repository;

    setUp(() {
      repository = FakeHabitRepository();
    });

    testWidgets('renders habit name in app bar', (tester) async {
      await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
      final viewModel = HabitDetailViewModel(
        habitRepository: repository,
        widgetSyncRepository: FakeWidgetSyncRepository(),
        syncNotifier: SyncNotifier(),
        now: () => today,
        habitId: 'h1',
      );
      await tester.pumpWidget(buildTestWidget(viewModel));

      expect(find.text('Read'), findsOneWidget);
    });

    testWidgets('shows error when habit not found', (tester) async {
      final viewModel = HabitDetailViewModel(
        habitRepository: repository,
        widgetSyncRepository: FakeWidgetSyncRepository(),
        syncNotifier: SyncNotifier(),
        now: () => today,
        habitId: 'missing',
      );
      await tester.pumpWidget(buildTestWidget(viewModel));

      expect(find.text('Habit not found'), findsOneWidget);
    });

    testWidgets('displays score and band label', (tester) async {
      await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
      final viewModel = HabitDetailViewModel(
        habitRepository: repository,
        widgetSyncRepository: FakeWidgetSyncRepository(),
        syncNotifier: SyncNotifier(),
        now: () => today,
        habitId: 'h1',
      );
      await tester.pumpWidget(buildTestWidget(viewModel));

      expect(find.text('0'), findsWidgets);
      expect(find.text('Starting out'), findsOneWidget);
    });

    testWidgets('delete action removes habit and pops screen', (tester) async {
      await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
      final viewModel = HabitDetailViewModel(
        habitRepository: repository,
        widgetSyncRepository: FakeWidgetSyncRepository(),
        syncNotifier: SyncNotifier(),
        now: () => today,
        habitId: 'h1',
      );
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

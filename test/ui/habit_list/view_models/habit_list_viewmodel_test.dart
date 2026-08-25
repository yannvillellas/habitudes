import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/domain/models/habit_completion.dart';
import 'package:habitudes/domain/models/result.dart';
import 'package:habitudes/ui/core/sync_notifier.dart';
import 'package:habitudes/ui/habit_list/view_models/habit_list_viewmodel.dart';

import '../../../../testing/fakes/fake_habit_repository.dart';
import '../../../../testing/fakes/fake_widget_sync_repository.dart';

void main() {
  final today = DateTime(2026, 6, 9);

  HabitListViewModel createViewModel(
    FakeHabitRepository repository,
    SyncNotifier syncNotifier,
    FakeWidgetSyncRepository widgetSyncRepository,
  ) {
    return HabitListViewModel(
      habitRepository: repository,
      widgetSyncRepository: widgetSyncRepository,
      syncNotifier: syncNotifier,
      now: () => today,
    );
  }

  group('HabitListViewModel', () {
    late FakeHabitRepository repository;
    late SyncNotifier syncNotifier;
    late FakeWidgetSyncRepository widgetSyncRepository;
    late HabitListViewModel viewModel;

    setUp(() async {
      repository = FakeHabitRepository();
      syncNotifier = SyncNotifier();
      widgetSyncRepository = FakeWidgetSyncRepository();
      viewModel = createViewModel(repository, syncNotifier, widgetSyncRepository);
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      viewModel.dispose();
      syncNotifier.dispose();
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

    group('toggleCompletion', () {
      test('load detects today completions', () async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await repository.recordCompletion(HabitCompletion(habitId: 'h1', date: today));

        await viewModel.load.execute();

        expect(viewModel.isCompletedToday('h1'), isTrue);
      });

      test('load sets false for habits without today completion', () async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await repository.recordCompletion(HabitCompletion(habitId: 'h1', date: DateTime(2026, 6, 8)));

        await viewModel.load.execute();

        expect(viewModel.isCompletedToday('h1'), isFalse);
      });

      test('records completion when not completed today', () async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await viewModel.load.execute();

        await viewModel.toggleCompletion.execute('h1');

        expect(viewModel.isCompletedToday('h1'), isTrue);
        final completions = (await repository.listCompletions('h1') as Ok<List<HabitCompletion>>).value;
        expect(completions, hasLength(1));
        expect(completions.single.date, DateTime.utc(2026, 6, 9));
      });

      test('deletes completion when already completed today', () async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await repository.recordCompletion(HabitCompletion(habitId: 'h1', date: today));
        await viewModel.load.execute();

        await viewModel.toggleCompletion.execute('h1');

        expect(viewModel.isCompletedToday('h1'), isFalse);
        final completions = (await repository.listCompletions('h1') as Ok<List<HabitCompletion>>).value;
        expect(completions, isEmpty);
      });

      test('does not affect other habits completions', () async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await repository.saveHabit(Habit(id: 'h2', name: 'Walk', createdAt: DateTime.utc(2026, 5, 6)));
        await viewModel.load.execute();

        await viewModel.toggleCompletion.execute('h1');

        expect(viewModel.isCompletedToday('h1'), isTrue);
        expect(viewModel.isCompletedToday('h2'), isFalse);
      });

      test('requests widget sync after recording completion', () async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await viewModel.load.execute();

        await viewModel.toggleCompletion.execute('h1');

        expect(widgetSyncRepository.syncAllCalls, 1);
      });

      test('requests widget sync after deleting completion', () async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await repository.recordCompletion(HabitCompletion(habitId: 'h1', date: today));
        await viewModel.load.execute();

        await viewModel.toggleCompletion.execute('h1');

        expect(widgetSyncRepository.syncAllCalls, 1);
      });

      test('does not request widget sync when repository fails', () async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await viewModel.load.execute();
        repository.recordCompletionError = Exception('test error');

        await viewModel.toggleCompletion.execute('h1');

        expect(widgetSyncRepository.syncAllCalls, 0);
      });
    });

    group('sync refresh', () {
      test('reloads habits silently when the sync notifier fires', () async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await viewModel.load.execute();
        expect(viewModel.habits, hasLength(1));

        await repository.saveHabit(Habit(id: 'h2', name: 'Walk', createdAt: DateTime.utc(2026, 5, 6)));
        syncNotifier.notifyRefresh();
        await pumpEventQueue();

        expect(viewModel.habits, hasLength(2));
        expect(viewModel.load.running, isFalse);
      });

      test('picks up today completions on refresh', () async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await viewModel.load.execute();
        expect(viewModel.isCompletedToday('h1'), isFalse);

        await repository.recordCompletion(HabitCompletion(habitId: 'h1', date: today));
        syncNotifier.notifyRefresh();
        await pumpEventQueue();

        expect(viewModel.isCompletedToday('h1'), isTrue);
      });

      test('skips refresh while a toggle is running', () async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await viewModel.load.execute();
        final callsBefore = repository.listHabitsCalls;

        repository.recordCompletionGate = Completer<void>();
        final toggleFuture = viewModel.toggleCompletion.execute('h1');
        syncNotifier.notifyRefresh();
        await pumpEventQueue();

        expect(repository.listHabitsCalls, callsBefore);

        repository.recordCompletionGate!.complete();
        await toggleFuture;
        expect(viewModel.isCompletedToday('h1'), isTrue);
      });

      test('unsubscribes from the notifier on dispose', () async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        final dedicatedNotifier = SyncNotifier();
        final dedicatedViewModel = HabitListViewModel(
          habitRepository: repository,
          widgetSyncRepository: FakeWidgetSyncRepository(),
          syncNotifier: dedicatedNotifier,
          now: () => today,
        );
        await pumpEventQueue();
        final callsBefore = repository.listHabitsCalls;

        dedicatedViewModel.dispose();
        dedicatedNotifier.notifyRefresh();
        await pumpEventQueue();

        expect(repository.listHabitsCalls, callsBefore);
        dedicatedNotifier.dispose();
      });

      test('skips refresh while a load is running', () async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await viewModel.load.execute();
        final callsBefore = repository.listHabitsCalls;

        repository.listHabitsGate = Completer<void>();
        final loadFuture = viewModel.load.execute();
        syncNotifier.notifyRefresh();
        await pumpEventQueue();

        expect(repository.listHabitsCalls, callsBefore + 1);

        repository.listHabitsGate!.complete();
        await loadFuture;
      });

      test('preserves today completions when the completions query fails', () async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await repository.recordCompletion(HabitCompletion(habitId: 'h1', date: today));
        await viewModel.load.execute();
        expect(viewModel.isCompletedToday('h1'), isTrue);

        repository.todayCompletedError = Exception('test error');
        await viewModel.load.execute();

        expect(viewModel.isCompletedToday('h1'), isTrue);
      });

      test('preserves state when refresh fails', () async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await repository.recordCompletion(HabitCompletion(habitId: 'h1', date: today));
        await viewModel.load.execute();
        expect(viewModel.isCompletedToday('h1'), isTrue);

        repository.listHabitsError = Exception('test error');
        syncNotifier.notifyRefresh();
        await pumpEventQueue();

        expect(viewModel.isCompletedToday('h1'), isTrue);
        expect(viewModel.habits, hasLength(1));
      });
    });

    group('score', () {
      test('returns 0 for habit with no completions', () async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));
        await viewModel.load.execute();

        expect(viewModel.score('h1'), 0);
      });

      test('returns positive score for habit with completions', () async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 6, 1)));
        for (int i = 1; i <= 8; i++) {
          await repository.recordCompletion(HabitCompletion(habitId: 'h1', date: DateTime.utc(2026, 6, i)));
        }
        await viewModel.load.execute();

        expect(viewModel.score('h1'), greaterThan(0));
      });

      test('returns 0 for unknown habit', () async {
        expect(viewModel.score('nonexistent'), 0);
      });

      test('score updates after toggling completion', () async {
        await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 6, 1)));
        await viewModel.load.execute();

        final scoreBefore = viewModel.score('h1');

        await viewModel.toggleCompletion.execute('h1');

        expect(viewModel.score('h1'), greaterThan(scoreBefore));
      });
    });
  });
}

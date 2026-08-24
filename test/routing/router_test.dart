import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:habitudes/data/repositories/habit_repository.dart';
import 'package:habitudes/data/repositories/widget_sync_repository.dart';
import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/l10n/app_localizations.dart';
import 'package:habitudes/routing/router.dart';
import 'package:habitudes/ui/core/sync_notifier.dart';

import '../../testing/fakes/fake_habit_repository.dart';
import '../../testing/fakes/fake_widget_sync_repository.dart';

Widget buildApp(FakeHabitRepository repository, {String? initialLocation}) {
  return MultiProvider(
    providers: [
      Provider<HabitRepository>.value(value: repository),
      Provider<WidgetSyncRepository>.value(value: FakeWidgetSyncRepository()),
      ChangeNotifierProvider<SyncNotifier>.value(value: SyncNotifier()),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter(initialLocation: initialLocation),
    ),
  );
}

void main() {
  testWidgets('opens the habit detail screen from a deep link', (tester) async {
    final repository = FakeHabitRepository();
    await repository.saveHabit(Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));

    await tester.pumpWidget(buildApp(repository, initialLocation: '/habit/h1'));
    await tester.pumpAndSettle();

    expect(find.text('Read'), findsWidgets);
  });

  testWidgets('opens the list screen by default', (tester) async {
    final repository = FakeHabitRepository();

    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('No habits yet'), findsOneWidget);
  });

  testWidgets('opens the habit detail screen from the platform default route', (tester) async {
    final habitId = '970cc0f3-1b20-4372-82e9-a0fe1b026e85';
    final repository = FakeHabitRepository();
    await repository.saveHabit(Habit(id: habitId, name: 'Read', createdAt: DateTime.utc(2026, 5, 6)));

    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/habit/$habitId';
    addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);

    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Read'), findsWidgets);
  });
}

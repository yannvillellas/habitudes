import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:habitudes/data/repositories/habit_repository.dart';
import 'package:habitudes/data/repositories/widget_sync_repository.dart';
import 'package:habitudes/main.dart';
import '../testing/fakes/fake_habit_repository.dart';
import '../testing/fakes/fake_widget_sync_repository.dart';

void main() {
  testWidgets('App renders with provider', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<HabitRepository>.value(value: FakeHabitRepository()),
          Provider<WidgetSyncRepository>.value(value: FakeWidgetSyncRepository()),
        ],
        child: const HabitudesApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('No habits yet'), findsOneWidget);
  });
}

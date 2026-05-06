import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:habitudes/data/repositories/habit_repository.dart';
import 'package:habitudes/main.dart';
import 'testing/fakes/fake_habit_repository.dart';

void main() {
  testWidgets('App renders with provider', (WidgetTester tester) async {
    await tester.pumpWidget(Provider<HabitRepository>.value(value: FakeHabitRepository(), child: const HabitudesApp()));

    expect(find.byType(Placeholder), findsOneWidget);
  });
}

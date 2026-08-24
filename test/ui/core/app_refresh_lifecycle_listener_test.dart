import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:habitudes/ui/core/sync_notifier.dart';
import 'package:habitudes/ui/core/app_refresh_lifecycle_listener.dart';

Widget buildTestWidget(SyncNotifier syncNotifier) {
  return ChangeNotifierProvider<SyncNotifier>.value(
    value: syncNotifier,
    child: const AppRefreshLifecycleListener(child: SizedBox()),
  );
}

void main() {
  testWidgets('notifies the sync notifier when the app becomes visible again', (tester) async {
    final syncNotifier = SyncNotifier();
    var notifications = 0;
    syncNotifier.addListener(() => notifications++);
    addTearDown(syncNotifier.dispose);

    await tester.pumpWidget(buildTestWidget(syncNotifier));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(notifications, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(notifications, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('does not notify when resuming from a transient inactive state', (tester) async {
    final syncNotifier = SyncNotifier();
    var notifications = 0;
    syncNotifier.addListener(() => notifications++);
    addTearDown(syncNotifier.dispose);

    await tester.pumpWidget(buildTestWidget(syncNotifier));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(notifications, 0);
  });

  testWidgets('stops notifying after disposal', (tester) async {
    final syncNotifier = SyncNotifier();
    var notifications = 0;
    syncNotifier.addListener(() => notifications++);
    addTearDown(syncNotifier.dispose);

    await tester.pumpWidget(buildTestWidget(syncNotifier));

    await tester.pumpWidget(ChangeNotifierProvider<SyncNotifier>.value(value: syncNotifier, child: const SizedBox()));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(notifications, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
}

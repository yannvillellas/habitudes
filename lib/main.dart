import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import 'config/theme.dart';
import 'data/repositories/habit_repository.dart';
import 'data/repositories/habit_repository_sqflite.dart';
import 'data/repositories/widget_sync_repository.dart';
import 'data/services/database_service.dart';
import 'data/services/habit_open_channel_listener.dart';
import 'data/services/widget_sync_service.dart';
import 'l10n/app_localizations.dart';
import 'routing/router.dart';
import 'ui/core/app_refresh_lifecycle_listener.dart';
import 'ui/core/sync_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbPath = p.join(await getDatabasesPath(), 'habitudes.db');
  final service = await DatabaseService.open(dbPath, onCreate: HabitRepositorySqflite.createTables);
  final repository = HabitRepositorySqflite(service: service);
  final widgetSyncRepository = WidgetSyncRepositoryMethodChannel(service: MethodChannelWidgetSyncService());
  final syncNotifier = SyncNotifier();
  final router = appRouter();
  HabitOpenChannelListener(onOpenHabit: (habitId) => router.push('/habit/$habitId'));

  runApp(
    MultiProvider(
      providers: [
        Provider<HabitRepository>.value(value: repository),
        Provider<WidgetSyncRepository>.value(value: widgetSyncRepository),
        ChangeNotifierProvider<SyncNotifier>.value(value: syncNotifier),
      ],
      child: HabitudesApp(router: router),
    ),
  );
}

class HabitudesApp extends StatelessWidget {
  const HabitudesApp({super.key, this.router});

  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    return AppRefreshLifecycleListener(
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          return MaterialApp.router(
            title: 'Habitudes',
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(colorScheme: lightDynamic),
            darkTheme: AppTheme.dark(colorScheme: darkDynamic),
            themeMode: ThemeMode.system,
            routerConfig: router ?? appRouter(),
          );
        },
      ),
    );
  }
}

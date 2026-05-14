import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import 'config/theme.dart';
import 'data/repositories/habit_repository.dart';
import 'data/repositories/habit_repository_sqflite.dart';
import 'data/services/database_service.dart';
import 'routing/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbPath = join(await getDatabasesPath(), 'habitudes.db');
  final service = await DatabaseService.open(dbPath, onCreate: HabitRepositorySqflite.createTables);
  final repository = HabitRepositorySqflite(service: service);

  runApp(Provider<HabitRepository>.value(value: repository, child: const HabitudesApp()));
}

class HabitudesApp extends StatelessWidget {
  const HabitudesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp.router(
          title: 'Habitudes',
          theme: AppTheme.light(colorScheme: lightDynamic),
          darkTheme: AppTheme.dark(colorScheme: darkDynamic),
          themeMode: ThemeMode.system,
          routerConfig: appRouter(),
        );
      },
    );
  }
}

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import 'config/theme.dart';
import 'data/repositories/habit_repository.dart';
import 'data/repositories/habit_repository_sqflite.dart';
import 'data/services/database_service.dart';
import 'domain/models/habit.dart';
import 'ui/habit_list/view_models/habit_list_viewmodel.dart';
import 'ui/habit_list/widgets/habit_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbPath = join(await getDatabasesPath(), 'habitudes.db');
  final service = await DatabaseService.open(dbPath, onCreate: HabitRepositorySqflite.createTables);
  final repository = HabitRepositorySqflite(service: service);

  await _seedIfEmpty(repository);

  runApp(Provider<HabitRepository>.value(value: repository, child: const HabitudesApp()));
}

Future<void> _seedIfEmpty(HabitRepository repository) async {
  final habits = await repository.listHabits();
  if (habits.isNotEmpty) return;

  await repository.saveHabit(Habit(id: 'seed-1', name: 'Read 20 pages', createdAt: DateTime.utc(2026, 5, 1)));
  await repository.saveHabit(Habit(id: 'seed-2', name: 'Morning walk', createdAt: DateTime.utc(2026, 5, 2)));
}

class HabitudesApp extends StatelessWidget {
  const HabitudesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title: 'Habitudes',
          theme: AppTheme.light(colorScheme: lightDynamic),
          darkTheme: AppTheme.dark(colorScheme: darkDynamic),
          themeMode: ThemeMode.system,
          home: const _HabitListShell(),
        );
      },
    );
  }
}

class _HabitListShell extends StatefulWidget {
  const _HabitListShell();

  @override
  State<_HabitListShell> createState() => _HabitListShellState();
}

class _HabitListShellState extends State<_HabitListShell> {
  late final _viewModel = HabitListViewModel(habitRepository: context.read<HabitRepository>());

  @override
  void initState() {
    super.initState();
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HabitListScreen(viewModel: _viewModel);
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/repositories/habit_repository.dart';
import '../data/repositories/widget_sync_repository.dart';
import '../ui/core/sync_notifier.dart';
import '../ui/create_habit/view_models/create_habit_viewmodel.dart';
import '../ui/create_habit/widgets/create_habit_screen.dart';
import '../ui/habit_detail/view_models/habit_detail_viewmodel.dart';
import '../ui/habit_detail/widgets/habit_detail_screen.dart';
import '../ui/habit_list/view_models/habit_list_viewmodel.dart';
import '../ui/habit_list/widgets/habit_list_screen.dart';

GoRouter appRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final repository = context.read<HabitRepository>();
          final widgetSyncRepository = context.read<WidgetSyncRepository>();
          final syncNotifier = context.read<SyncNotifier>();
          final viewModel = HabitListViewModel(
            habitRepository: repository,
            widgetSyncRepository: widgetSyncRepository,
            syncNotifier: syncNotifier,
          );
          return HabitListScreen(
            viewModel: viewModel,
            onTapHabit: (_, habitId) => context.push('/habit/$habitId'),
            onAddHabit: (sheetContext) {
              final createViewModel = CreateHabitViewModel(
                habitRepository: repository,
                onSaved: () => viewModel.load.execute(),
              );
              showModalBottomSheet(
                context: sheetContext,
                isScrollControlled: true,
                builder: (_) => CreateHabitScreen(viewModel: createViewModel),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/habit/:id',
        builder: (context, state) {
          final repository = context.read<HabitRepository>();
          final widgetSyncRepository = context.read<WidgetSyncRepository>();
          final syncNotifier = context.read<SyncNotifier>();
          final habitId = state.pathParameters['id']!;
          final viewModel = HabitDetailViewModel(
            habitRepository: repository,
            widgetSyncRepository: widgetSyncRepository,
            syncNotifier: syncNotifier,
            habitId: habitId,
          );
          return HabitDetailScreen(viewModel: viewModel, onDeleted: () => context.pop());
        },
      ),
    ],
  );
}

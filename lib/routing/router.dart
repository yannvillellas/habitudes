import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/repositories/habit_repository.dart';
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
          final viewModel = HabitListViewModel(habitRepository: repository)..load();
          return HabitListScreen(viewModel: viewModel);
        },
      ),
    ],
  );
}

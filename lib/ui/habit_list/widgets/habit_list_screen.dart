import 'package:flutter/material.dart';

import '../../core/ui/error_indicator.dart';
import '../../../l10n/app_localizations.dart';
import '../view_models/habit_list_viewmodel.dart';

class HabitListScreen extends StatelessWidget {
  final HabitListViewModel viewModel;
  final void Function(BuildContext context, String habitId) onTapHabit;
  final void Function(BuildContext context) onAddHabit;

  const HabitListScreen({super.key, required this.viewModel, required this.onTapHabit, required this.onAddHabit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      floatingActionButton: FloatingActionButton(onPressed: () => onAddHabit(context), child: const Icon(Icons.add)),
      body: ListenableBuilder(
        listenable: Listenable.merge([viewModel, viewModel.load, viewModel.toggleCompletion]),
        builder: (context, _) {
          if (viewModel.load.running && viewModel.habits.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.load.error && viewModel.habits.isEmpty) {
            return ErrorIndicator(
              title: l10n.failedToLoadHabits,
              label: l10n.tryAgain,
              onPressed: () => viewModel.load.execute(),
            );
          }
          if (viewModel.habits.isEmpty) {
            return Center(child: Text(l10n.noHabitsYet));
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.load.execute(),
            child: ListView.builder(
              itemCount: viewModel.habits.length,
              itemBuilder: (context, index) {
                final habit = viewModel.habits[index];
                return ListTile(
                  leading: Checkbox(
                    value: viewModel.isCompletedToday(habit.id),
                    onChanged: (_) async {
                      await viewModel.toggleCompletion.execute(habit.id);
                      if (viewModel.toggleCompletion.error && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.failedToUpdate),
                            action: SnackBarAction(
                              label: l10n.retry,
                              onPressed: () => viewModel.toggleCompletion.execute(habit.id),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  title: Text(habit.name),
                  onTap: () => onTapHabit(context, habit.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

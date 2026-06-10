import 'package:flutter/material.dart';

import '../../../utils/date_formatting.dart';
import '../view_models/habit_detail_viewmodel.dart';

class HabitDetailScreen extends StatelessWidget {
  final HabitDetailViewModel viewModel;
  final VoidCallback? onDeleted;

  const HabitDetailScreen({super.key, required this.viewModel, this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: viewModel.load,
          builder: (_, _) {
            final habit = viewModel.habit;
            return Text(habit?.name ?? 'Habit');
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                await viewModel.delete.execute();
                if (!viewModel.delete.error) {
                  onDeleted?.call();
                }
              }
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete'))],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          viewModel,
          viewModel.load,
          viewModel.delete,
          viewModel.loadCompletions,
          viewModel.toggleDayCompletion,
        ]),
        builder: (_, _) {
          if (viewModel.load.running) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.load.error) {
            return const Center(child: Text('Habit not found'));
          }
          if (viewModel.delete.running) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.loadCompletions.running) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: viewModel.last30Days.length,
                  itemBuilder: (context, index) {
                    final date = viewModel.last30Days[index];
                    final dayOfMonth = date.day.toString();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(formatDayOfWeek(date), style: Theme.of(context).textTheme.bodySmall),
                          Text(dayOfMonth, style: Theme.of(context).textTheme.bodySmall),
                          Checkbox(
                            value: viewModel.isDayCompleted(date),
                            onChanged: (_) => viewModel.toggleDayCompletion.execute(date),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

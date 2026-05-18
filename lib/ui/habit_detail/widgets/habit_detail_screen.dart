import 'package:flutter/material.dart';

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
        listenable: Listenable.merge([viewModel.load, viewModel.delete]),
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
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

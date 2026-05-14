import 'package:flutter/material.dart';

import '../../core/ui/error_indicator.dart';
import '../view_models/habit_list_viewmodel.dart';

class HabitListScreen extends StatelessWidget {
  final HabitListViewModel viewModel;
  final void Function(BuildContext context) onAddHabit;

  const HabitListScreen({super.key, required this.viewModel, required this.onAddHabit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habitudes')),
      floatingActionButton: FloatingActionButton(onPressed: () => onAddHabit(context), child: const Icon(Icons.add)),
      body: ListenableBuilder(
        listenable: Listenable.merge([viewModel, viewModel.load]),
        builder: (context, _) {
          if (viewModel.load.running) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.load.error) {
            return ErrorIndicator(
              title: 'Failed to load habits',
              label: 'Try again',
              onPressed: () => viewModel.load.execute(),
            );
          }
          if (viewModel.habits.isEmpty) {
            return const Center(child: Text('No habits yet'));
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.load.execute(),
            child: ListView.builder(
              itemCount: viewModel.habits.length,
              itemBuilder: (context, index) {
                final habit = viewModel.habits[index];
                return ListTile(leading: Checkbox(value: false, onChanged: null), title: Text(habit.name));
              },
            ),
          );
        },
      ),
    );
  }
}

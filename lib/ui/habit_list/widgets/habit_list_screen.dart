import 'package:flutter/material.dart';

import '../view_models/habit_list_viewmodel.dart';

class HabitListScreen extends StatelessWidget {
  final HabitListViewModel viewModel;

  const HabitListScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habitudes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO(Iteration 6): navigate to create habit screen
        },
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.habits.isEmpty) {
            return const Center(child: Text('No habits yet'));
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.load(),
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

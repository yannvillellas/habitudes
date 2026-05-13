import 'dart:async';

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
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => _CreateSheetContent(viewModel: viewModel),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
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

class _CreateSheetContent extends StatefulWidget {
  final HabitListViewModel viewModel;

  const _CreateSheetContent({required this.viewModel});

  @override
  State<_CreateSheetContent> createState() => _CreateSheetContentState();
}

class _CreateSheetContentState extends State<_CreateSheetContent> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveHabit() {
    Navigator.of(context).pop();
    unawaited(widget.viewModel.addHabit(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 8, left: 24, right: 24, top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              controller: _controller,
              decoration: const InputDecoration(hintText: 'New habit', border: InputBorder.none),
            ),
            Row(
              children: [
                const Spacer(),
                ListenableBuilder(
                  listenable: _controller,
                  builder: (_, _) => TextButton(
                    onPressed: widget.viewModel.canSaveHabit(_controller.text) ? _saveHabit : null,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/ui/error_indicator.dart';
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

  Future<void> _saveHabit() async {
    await widget.viewModel.addHabit.execute(_controller.text);
    if (!mounted) return;
    if (!widget.viewModel.addHabit.error) {
      Navigator.of(context).pop();
    }
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
            ListenableBuilder(
              listenable: Listenable.merge([_controller, widget.viewModel.addHabit]),
              builder: (_, _) => Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: widget.viewModel.addHabit.running || !widget.viewModel.canSaveHabit(_controller.text)
                        ? null
                        : () {
                            _saveHabit();
                          },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

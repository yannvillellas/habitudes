import 'package:flutter/material.dart';

import '../view_models/create_habit_viewmodel.dart';

class CreateHabitScreen extends StatefulWidget {
  final CreateHabitViewModel viewModel;

  const CreateHabitScreen({super.key, required this.viewModel});

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    await widget.viewModel.save.execute(_controller.text);
    if (!mounted) return;
    if (!widget.viewModel.save.error) {
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
              listenable: Listenable.merge([_controller, widget.viewModel.save]),
              builder: (_, _) => Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: widget.viewModel.save.running || !widget.viewModel.canSaveHabit(_controller.text)
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

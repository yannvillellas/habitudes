import 'package:flutter/foundation.dart';

import 'package:uuid/uuid.dart';

import 'package:habitudes/data/repositories/habit_repository.dart';
import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/domain/models/result.dart';
import 'package:habitudes/utils/command.dart';

class CreateHabitViewModel extends ChangeNotifier {
  static const _uuid = Uuid();

  final HabitRepository _habitRepository;
  final VoidCallback? _onSaved;

  CreateHabitViewModel({required HabitRepository habitRepository, VoidCallback? onSaved})
    : _habitRepository = habitRepository,
      _onSaved = onSaved {
    save = Command1<void, String>(_save);
  }

  late final Command1<void, String> save;

  bool canSaveHabit(String text) => text.trim().isNotEmpty;

  Future<Result<void>> _save(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return const Result.ok(null);

    final habit = Habit(id: _uuid.v4(), name: trimmedName, createdAt: DateTime.now().toUtc());
    final result = await _habitRepository.saveHabit(habit);
    switch (result) {
      case Ok<void>():
        _onSaved?.call();
        return const Result.ok(null);
      case Error<void>():
        return result;
    }
  }
}

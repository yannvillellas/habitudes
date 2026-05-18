import 'package:flutter/foundation.dart';

import '../../../data/repositories/habit_repository.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/result.dart';
import '../../../utils/command.dart';

class HabitDetailViewModel extends ChangeNotifier {
  final HabitRepository _habitRepository;
  final String _habitId;

  HabitDetailViewModel({required HabitRepository habitRepository, required String habitId})
    : _habitRepository = habitRepository,
      _habitId = habitId {
    load = Command0<Habit>(_load)..execute();
    delete = Command0<void>(_delete);
  }

  late final Command0<Habit> load;
  late final Command0<void> delete;

  Habit? _habit;
  Habit? get habit => _habit;

  Future<Result<Habit>> _load() async {
    final result = await _habitRepository.listHabits();
    switch (result) {
      case Ok<List<Habit>>():
        _habit = result.value.where((h) => h.id == _habitId).firstOrNull;
      case Error<List<Habit>>():
        break;
    }
    notifyListeners();
    if (_habit == null) {
      return Result.error(Exception('Habit not found'));
    }
    return Result.ok(_habit!);
  }

  Future<Result<void>> _delete() async {
    final result = await _habitRepository.deleteHabit(_habitId);
    switch (result) {
      case Ok<void>():
        _habit = null;
      case Error<void>():
        break;
    }
    notifyListeners();
    return result;
  }
}

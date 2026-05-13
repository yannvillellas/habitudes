import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:uuid/uuid.dart';

import 'package:habitudes/data/repositories/habit_repository.dart';
import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/domain/models/result.dart';
import 'package:habitudes/utils/command.dart';

class HabitListViewModel extends ChangeNotifier {
  final HabitRepository _habitRepository;

  HabitListViewModel({required HabitRepository habitRepository}) : _habitRepository = habitRepository {
    load = Command0<List<Habit>>(_load);
    addHabit = Command1<void, String>(_addHabit);
  }

  late final Command0<List<Habit>> load;
  late final Command1<void, String> addHabit;

  List<Habit> _habits = [];
  UnmodifiableListView<Habit> get habits => UnmodifiableListView(_habits);

  bool canSaveHabit(String text) => text.trim().isNotEmpty;

  Future<Result<List<Habit>>> _load() async {
    final result = await _habitRepository.listHabits();
    switch (result) {
      case Ok<List<Habit>>():
        _habits = result.value;
      case Error<List<Habit>>():
        break;
    }
    notifyListeners();
    return result;
  }

  Future<Result<void>> _addHabit(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return const Result.ok(null);

    final habit = Habit(id: const Uuid().v4(), name: trimmedName, createdAt: DateTime.now().toUtc());
    final result = await _habitRepository.saveHabit(habit);
    switch (result) {
      case Ok<void>():
        await _load();
        return const Result.ok(null);
      case Error<void>():
        return result;
    }
  }
}

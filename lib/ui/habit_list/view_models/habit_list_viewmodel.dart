import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:habitudes/data/repositories/habit_repository.dart';
import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/domain/models/result.dart';
import 'package:habitudes/utils/command.dart';

class HabitListViewModel extends ChangeNotifier {
  final HabitRepository _habitRepository;

  HabitListViewModel({required HabitRepository habitRepository}) : _habitRepository = habitRepository {
    load = Command0<List<Habit>>(_load)..execute();
  }

  late final Command0<List<Habit>> load;

  List<Habit> _habits = [];
  UnmodifiableListView<Habit> get habits => UnmodifiableListView(_habits);

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
}

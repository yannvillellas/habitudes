import 'package:flutter/foundation.dart';

import 'package:habitudes/data/repositories/habit_repository.dart';
import 'package:habitudes/domain/models/habit.dart';

class HabitListViewModel extends ChangeNotifier {
  final HabitRepository _habitRepository;

  HabitListViewModel({required HabitRepository habitRepository}) : _habitRepository = habitRepository;

  List<Habit> _habits = [];
  List<Habit> get habits => _habits;

  Future<void> load() async {
    _habits = await _habitRepository.listHabits();
    notifyListeners();
  }
}

import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/habit_repository.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_completion.dart';
import '../../../domain/models/result.dart';
import '../../../utils/command.dart';
import '../../../domain/models/habit_score.dart';

class HabitListViewModel extends ChangeNotifier {
  final HabitRepository _habitRepository;
  final DateTime Function() _now;

  HabitListViewModel({required HabitRepository habitRepository, DateTime Function()? now})
    : _habitRepository = habitRepository,
      _now = now ?? (() => DateTime.now()) {
    load = Command0<List<Habit>>(_load)..execute();
    toggleCompletion = Command1<void, String>(_toggleCompletion);
  }

  late final Command0<List<Habit>> load;
  late final Command1<void, String> toggleCompletion;

  List<Habit> _habits = [];
  UnmodifiableListView<Habit> get habits => UnmodifiableListView(_habits);

  final Set<String> _completedToday = {};
  bool isCompletedToday(String habitId) => _completedToday.contains(habitId);

  final Map<String, int> _scores = {};
  int score(String habitId) => _scores[habitId] ?? 0;

  Future<Result<List<Habit>>> _load() async {
    _completedToday.clear();
    _scores.clear();
    final result = await _habitRepository.listHabits();
    switch (result) {
      case Ok<List<Habit>>():
        _habits = result.value;
        final today = _now();
        final completionsResult = await _habitRepository.getTodayCompletedHabitIds(today);
        switch (completionsResult) {
          case Ok<Set<String>>():
            _completedToday.addAll(completionsResult.value);
          case Error<Set<String>>():
            break;
        }
        for (final habit in _habits) {
          final habitCompletions = await _habitRepository.listCompletions(habit.id);
          switch (habitCompletions) {
            case Ok<List<HabitCompletion>>():
              _scores[habit.id] = HabitScore.calculate(
                completions: habitCompletions.value,
                habitCreatedAt: habit.createdAt,
                today: today,
              );
            case Error<List<HabitCompletion>>():
              _scores[habit.id] = 0;
          }
        }
      case Error<List<Habit>>():
        break;
    }
    notifyListeners();
    return result;
  }

  Future<Result<void>> _toggleCompletion(String habitId) async {
    final today = _now();
    if (_completedToday.contains(habitId)) {
      final result = await _habitRepository.deleteCompletion(habitId, today);
      switch (result) {
        case Ok<void>():
          _completedToday.remove(habitId);
        case Error<void>():
          break;
      }
      notifyListeners();
      return result;
    } else {
      final result = await _habitRepository.recordCompletion(HabitCompletion(habitId: habitId, date: today));
      switch (result) {
        case Ok<void>():
          _completedToday.add(habitId);
        case Error<void>():
          break;
      }
      notifyListeners();
      return result;
    }
  }
}

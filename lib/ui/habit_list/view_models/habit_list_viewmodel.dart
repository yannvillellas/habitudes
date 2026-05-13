import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:uuid/uuid.dart';

import 'package:habitudes/data/repositories/habit_repository.dart';
import 'package:habitudes/domain/models/habit.dart';

class HabitListViewModel extends ChangeNotifier {
  final HabitRepository _habitRepository;

  HabitListViewModel({required HabitRepository habitRepository}) : _habitRepository = habitRepository;

  List<Habit> _habits = [];
  UnmodifiableListView<Habit> get habits => UnmodifiableListView(_habits);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool canSaveHabit(String text) => text.trim().isNotEmpty;

  Future<void> addHabit(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    final habit = Habit(id: const Uuid().v4(), name: trimmedName, createdAt: DateTime.now().toUtc());
    await _habitRepository.saveHabit(habit);
    await load();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _habits = await _habitRepository.listHabits();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

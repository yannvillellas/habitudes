import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:uuid/uuid.dart';

import 'package:habitudes/data/repositories/habit_repository.dart';
import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/domain/models/result.dart';

class HabitListViewModel extends ChangeNotifier {
  final HabitRepository _habitRepository;

  HabitListViewModel({required HabitRepository habitRepository}) : _habitRepository = habitRepository;

  List<Habit> _habits = [];
  UnmodifiableListView<Habit> get habits => UnmodifiableListView(_habits);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Exception? _error;
  Exception? get error => _error;

  bool canSaveHabit(String text) => text.trim().isNotEmpty;

  Future<void> addHabit(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    final habit = Habit(id: const Uuid().v4(), name: trimmedName, createdAt: DateTime.now().toUtc());
    final result = await _habitRepository.saveHabit(habit);
    switch (result) {
      case Ok<void>():
        await load();
      case Error<void>():
        _error = result.error;
        notifyListeners();
    }
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _habitRepository.listHabits();
      switch (result) {
        case Ok<List<Habit>>():
          _habits = result.value;
        case Error<List<Habit>>():
          _error = result.error;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

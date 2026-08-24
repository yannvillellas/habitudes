import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/habit_repository.dart';
import '../../../data/repositories/widget_sync_repository.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_completion.dart';
import '../../../domain/models/result.dart';
import '../../../utils/command.dart';
import '../../../domain/models/habit_score.dart';
import '../../core/sync_notifier.dart';

class HabitListViewModel extends ChangeNotifier {
  final HabitRepository _habitRepository;
  final WidgetSyncRepository _widgetSyncRepository;
  final SyncNotifier _syncNotifier;
  final DateTime Function() _now;
  bool _isRefreshing = false;

  HabitListViewModel({
    required HabitRepository habitRepository,
    required WidgetSyncRepository widgetSyncRepository,
    required SyncNotifier syncNotifier,
    DateTime Function()? now,
  }) : _habitRepository = habitRepository,
       _widgetSyncRepository = widgetSyncRepository,
       _syncNotifier = syncNotifier,
       _now = now ?? (() => DateTime.now()) {
    load = Command0<List<Habit>>(_load)..execute();
    toggleCompletion = Command1<void, String>(_toggleCompletion);
    _syncNotifier.addListener(_onRefreshRequested);
  }

  @override
  void dispose() {
    _syncNotifier.removeListener(_onRefreshRequested);
    super.dispose();
  }

  void _onRefreshRequested() {
    // Best-effort: repository failures keep the previous state; the guard
    // prevents overlapping refreshes.
    unawaited(refresh());
  }

  Future<void> refresh() async {
    if (_isRefreshing || toggleCompletion.running) return;
    _isRefreshing = true;
    try {
      await _load();
    } finally {
      _isRefreshing = false;
    }
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
    final result = await _habitRepository.listHabits();
    switch (result) {
      case Ok<List<Habit>>():
        final habits = result.value;
        final today = _now();
        final completedToday = <String>{};
        final completionsResult = await _habitRepository.getTodayCompletedHabitIds(today);
        switch (completionsResult) {
          case Ok<Set<String>>():
            completedToday.addAll(completionsResult.value);
          case Error<Set<String>>():
            break;
        }
        final scores = <String, int>{};
        for (final habit in habits) {
          final habitCompletions = await _habitRepository.listCompletions(habit.id);
          switch (habitCompletions) {
            case Ok<List<HabitCompletion>>():
              scores[habit.id] = HabitScore.calculate(
                completions: habitCompletions.value,
                habitCreatedAt: habit.createdAt,
                today: today,
              );
            case Error<List<HabitCompletion>>():
              scores[habit.id] = 0;
          }
        }
        _habits = habits;
        _completedToday
          ..clear()
          ..addAll(completedToday);
        _scores
          ..clear()
          ..addAll(scores);
      case Error<List<Habit>>():
        break;
    }
    notifyListeners();
    return result;
  }

  Future<Result<void>> _toggleCompletion(String habitId) async {
    final today = _now();
    final isCompleted = _completedToday.contains(habitId);
    final result = isCompleted
        ? await _habitRepository.deleteCompletion(habitId, today)
        : await _habitRepository.recordCompletion(HabitCompletion(habitId: habitId, date: today));
    switch (result) {
      case Ok<void>():
        if (isCompleted) {
          _completedToday.remove(habitId);
        } else {
          _completedToday.add(habitId);
        }
        await _recalculateScore(habitId);
      case Error<void>():
        break;
    }
    notifyListeners();
    if (result is Ok<void>) {
      await _widgetSyncRepository.syncAll();
    }
    return result;
  }

  Future<void> _recalculateScore(String habitId) async {
    final habit = _habits.where((h) => h.id == habitId).firstOrNull;
    if (habit == null) return;
    final completionsResult = await _habitRepository.listCompletions(habitId);
    switch (completionsResult) {
      case Ok<List<HabitCompletion>>():
        _scores[habitId] = HabitScore.calculate(
          completions: completionsResult.value,
          habitCreatedAt: habit.createdAt,
          today: _now(),
        );
      case Error<List<HabitCompletion>>():
        _scores[habitId] = 0;
    }
  }
}

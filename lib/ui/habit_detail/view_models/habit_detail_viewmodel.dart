import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/habit_repository.dart';
import '../../../data/repositories/widget_sync_repository.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_completion.dart';
import '../../../domain/models/result.dart';
import '../../../domain/models/habit_score.dart';
import '../../../utils/command.dart';
import '../../core/sync_notifier.dart';

class HabitDetailViewModel extends ChangeNotifier {
  final HabitRepository _habitRepository;
  final WidgetSyncRepository _widgetSyncRepository;
  final SyncNotifier _syncNotifier;
  final String _habitId;
  final DateTime Function() _now;
  bool _isRefreshing = false;

  HabitDetailViewModel({
    required HabitRepository habitRepository,
    required WidgetSyncRepository widgetSyncRepository,
    required SyncNotifier syncNotifier,
    required String habitId,
    DateTime Function()? now,
  }) : _habitRepository = habitRepository,
       _widgetSyncRepository = widgetSyncRepository,
       _syncNotifier = syncNotifier,
       _habitId = habitId,
       _now = now ?? (() => DateTime.now()) {
    load = Command0<Habit>(_load)..execute();
    loadCompletions = Command0<List<HabitCompletion>>(_loadCompletions)..execute();
    toggleDayCompletion = Command1<void, DateTime>(_toggleDayCompletion);
    delete = Command0<void>(_delete);
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
    if (_isRefreshing || toggleDayCompletion.running || delete.running) return;
    _isRefreshing = true;
    try {
      await _fetchHabit();
      await _fetchCompletions();
      notifyListeners();
    } finally {
      _isRefreshing = false;
    }
  }

  late final Command0<Habit> load;
  late final Command0<List<HabitCompletion>> loadCompletions;
  late final Command1<void, DateTime> toggleDayCompletion;
  late final Command0<void> delete;

  Habit? _habit;
  Habit? get habit => _habit;

  List<HabitCompletion> _completions = [];
  UnmodifiableListView<HabitCompletion> get completions => UnmodifiableListView(_completions);

  List<DateTime> get last30Days {
    final now = _now();
    return List.generate(30, (i) => DateTime(now.year, now.month, now.day - i));
  }

  int get score {
    if (_habit == null) return 0;
    return HabitScore.calculate(completions: _completions, habitCreatedAt: _habit!.createdAt, today: _now());
  }

  bool isDayCompleted(DateTime date) {
    return _completions.any((c) => _isSameDay(c.date, date));
  }

  Future<Result<Habit>> _load() async {
    final result = await _fetchHabit();
    notifyListeners();
    return result;
  }

  Future<Result<Habit>> _fetchHabit() async {
    final result = await _habitRepository.listHabits();
    switch (result) {
      case Ok<List<Habit>>():
        _habit = result.value.where((h) => h.id == _habitId).firstOrNull;
      case Error<List<Habit>>():
        break;
    }
    if (_habit == null) {
      return Result.error(Exception('Habit not found'));
    }
    return Result.ok(_habit!);
  }

  Future<Result<List<HabitCompletion>>> _loadCompletions() async {
    final result = await _fetchCompletions();
    notifyListeners();
    return result;
  }

  Future<Result<List<HabitCompletion>>> _fetchCompletions() async {
    final result = await _habitRepository.listCompletions(_habitId);
    switch (result) {
      case Ok<List<HabitCompletion>>():
        _completions = result.value.toList();
      case Error<List<HabitCompletion>>():
        break;
    }
    return result;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<Result<void>> _toggleDayCompletion(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final isCompleted = _completions.any((c) => _isSameDay(c.date, normalizedDate));
    final result = isCompleted
        ? await _habitRepository.deleteCompletion(_habitId, normalizedDate)
        : await _habitRepository.recordCompletion(HabitCompletion(habitId: _habitId, date: normalizedDate));
    switch (result) {
      case Ok<void>():
        if (isCompleted) {
          _completions.removeWhere((c) => _isSameDay(c.date, normalizedDate));
        } else {
          _completions.add(HabitCompletion(habitId: _habitId, date: normalizedDate));
        }
      case Error<void>():
        break;
    }
    notifyListeners();
    if (result is Ok<void>) {
      await _widgetSyncRepository.syncAll();
    }
    return result;
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
    if (result is Ok<void>) {
      _syncNotifier.notifyRefresh();
      await _widgetSyncRepository.syncAll();
    }
    return result;
  }
}

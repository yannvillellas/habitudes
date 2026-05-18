import 'package:habitudes/data/repositories/habit_repository.dart';
import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/domain/models/habit_completion.dart';
import 'package:habitudes/domain/models/result.dart';

class FakeHabitRepository implements HabitRepository {
  final Map<String, Habit> _habits = <String, Habit>{};
  final List<String> _habitOrder = <String>[];
  final Map<String, List<HabitCompletion>> _completions = <String, List<HabitCompletion>>{};

  Exception? listHabitsError;

  @override
  Future<Result<void>> saveHabit(Habit habit) async {
    if (!_habits.containsKey(habit.id)) {
      _habitOrder.add(habit.id);
    }

    _habits[habit.id] = habit;
    return const Result.ok(null);
  }

  @override
  Future<Result<List<Habit>>> listHabits() async {
    final error = listHabitsError;
    if (error != null) {
      listHabitsError = null;
      return Result.error(error);
    }

    final habits = [for (final habitId in _habitOrder) _habits[habitId]!];

    return Result.ok(habits.toList(growable: false));
  }

  @override
  Future<Result<void>> deleteHabit(String habitId) async {
    _habits.remove(habitId);
    _habitOrder.remove(habitId);
    _completions.remove(habitId);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> recordCompletion(HabitCompletion completion) async {
    final normalizedCompletion = HabitCompletion(habitId: completion.habitId, date: _normalizeDate(completion.date));
    final completions = _completions.putIfAbsent(completion.habitId, () => <HabitCompletion>[]);

    if (completions.any((existing) => _sameDate(existing.date, normalizedCompletion.date))) {
      return const Result.ok(null);
    }

    completions.add(normalizedCompletion);
    completions.sort((left, right) => left.date.compareTo(right.date));
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> deleteCompletion(String habitId, DateTime date) async {
    final completions = _completions[habitId];
    if (completions == null) {
      return const Result.ok(null);
    }

    completions.removeWhere((completion) => _sameDate(completion.date, date));
    if (completions.isEmpty) {
      _completions.remove(habitId);
    }
    return const Result.ok(null);
  }

  @override
  Future<Result<List<HabitCompletion>>> listCompletions(String habitId) async {
    final completions = _completions[habitId] ?? const <HabitCompletion>[];
    return Result.ok(List<HabitCompletion>.unmodifiable(completions));
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  static bool _sameDate(DateTime left, DateTime right) {
    final normalizedLeft = _normalizeDate(left);
    final normalizedRight = _normalizeDate(right);
    return normalizedLeft == normalizedRight;
  }
}

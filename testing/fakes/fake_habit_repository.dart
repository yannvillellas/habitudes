import 'package:habitudes/data/repositories/habit_repository.dart';
import 'package:habitudes/domain/models/habit.dart';
import 'package:habitudes/domain/models/habit_completion.dart';
import 'package:habitudes/domain/models/result.dart';

class FakeHabitRepository implements HabitRepository {
  final Map<String, Habit> _habits = <String, Habit>{};
  final List<String> _habitOrder = <String>[];
  final Map<String, List<HabitCompletion>> _completions = <String, List<HabitCompletion>>{};

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
    final habits = [for (final habitId in _habitOrder) _habits[habitId]!];

    return Result.ok(habits.toList(growable: false));
  }

  @override
  Future<void> recordCompletion(HabitCompletion completion) async {
    final normalizedCompletion = HabitCompletion(habitId: completion.habitId, date: _normalizeDate(completion.date));
    final completions = _completions.putIfAbsent(completion.habitId, () => <HabitCompletion>[]);

    if (completions.any((existing) => _sameDate(existing.date, normalizedCompletion.date))) {
      return;
    }

    completions.add(normalizedCompletion);
    completions.sort((left, right) => left.date.compareTo(right.date));
  }

  @override
  Future<void> deleteCompletion(String habitId, DateTime date) async {
    final completions = _completions[habitId];
    if (completions == null) {
      return;
    }

    completions.removeWhere((completion) => _sameDate(completion.date, date));
    if (completions.isEmpty) {
      _completions.remove(habitId);
    }
  }

  @override
  Future<List<HabitCompletion>> listCompletions(String habitId) async {
    final completions = _completions[habitId] ?? const <HabitCompletion>[];
    return List<HabitCompletion>.unmodifiable(completions);
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

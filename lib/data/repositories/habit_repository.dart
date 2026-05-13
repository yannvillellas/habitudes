import '../../domain/models/habit.dart';
import '../../domain/models/habit_completion.dart';
import '../../domain/models/result.dart';

abstract class HabitRepository {
  Future<Result<void>> saveHabit(Habit habit);
  Future<Result<List<Habit>>> listHabits();

  Future<void> recordCompletion(HabitCompletion completion);
  Future<void> deleteCompletion(String habitId, DateTime date);
  Future<List<HabitCompletion>> listCompletions(String habitId);
}

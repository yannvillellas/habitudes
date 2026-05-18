import '../../domain/models/habit.dart';
import '../../domain/models/habit_completion.dart';
import '../../domain/models/result.dart';

abstract class HabitRepository {
  Future<Result<void>> saveHabit(Habit habit);
  Future<Result<List<Habit>>> listHabits();
  Future<Result<void>> deleteHabit(String habitId);

  Future<Result<void>> recordCompletion(HabitCompletion completion);
  Future<Result<void>> deleteCompletion(String habitId, DateTime date);
  Future<Result<List<HabitCompletion>>> listCompletions(String habitId);
}

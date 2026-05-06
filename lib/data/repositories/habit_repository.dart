import '../../domain/models/habit.dart';
import '../../domain/models/habit_completion.dart';

abstract class HabitRepository {
  Future<void> saveHabit(Habit habit);
  Future<List<Habit>> listHabits({bool includeArchived = false});
  Future<void> archiveHabit(String habitId);

  Future<void> recordCompletion(HabitCompletion completion);
  Future<void> deleteCompletion(String habitId, DateTime date);
  Future<List<HabitCompletion>> listCompletions(String habitId);
}

import 'package:flutter/foundation.dart';

@immutable
class HabitCompletion {
  const HabitCompletion({required this.habitId, required this.date});

  final String habitId;
  final DateTime date;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitCompletion && other.habitId == habitId && other.date == date;
  }

  @override
  int get hashCode => Object.hash(habitId, date);
}

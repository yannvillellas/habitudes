import 'package:flutter/foundation.dart';

@immutable
class HabitCompletion {
  const HabitCompletion({required this.habitId, required this.date});

  final String habitId;
  final DateTime date;
}

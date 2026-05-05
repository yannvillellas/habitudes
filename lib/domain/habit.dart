import 'package:flutter/foundation.dart';

@immutable
class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final int colorValue;
  final DateTime createdAt;
  final bool isArchived;
}

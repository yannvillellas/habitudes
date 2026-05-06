import 'package:flutter/foundation.dart';

@immutable
class Habit {
  const Habit({required this.id, required this.name, required this.createdAt, this.isArchived = false});

  final String id;
  final String name;
  final DateTime createdAt;
  final bool isArchived;
}

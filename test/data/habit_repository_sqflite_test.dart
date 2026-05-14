import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:habitudes/data/repositories/habit_repository_sqflite.dart';
import 'package:habitudes/data/services/database_service.dart';

import 'habit_repository_contract.dart';

void main() {
  group('HabitRepositorySqflite', () {
    sqfliteFfiInit();

    runHabitRepositoryContract(() async {
      final db = await databaseFactoryFfi.openDatabase(
        'memory:${Random().nextInt(1 << 32)}',
        options: OpenDatabaseOptions(version: 1, onCreate: HabitRepositorySqflite.createTables),
      );
      final service = DatabaseService(db);
      return HabitRepositorySqflite(service: service);
    });
  });
}

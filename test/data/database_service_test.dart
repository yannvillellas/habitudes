import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:habitudes/data/services/database_service.dart';

void main() {
  group('DatabaseService', () {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    test('opens file databases in WAL journal mode', () async {
      final dir = await Directory.systemTemp.createTemp('habitudes_wal_test');
      addTearDown(() => dir.delete(recursive: true));
      final path = '${dir.path}/test.db';

      await DatabaseService.open(path, onCreate: (db, version) async {});

      final probe = await openDatabase(path);
      addTearDown(probe.close);
      final rows = await probe.rawQuery('PRAGMA journal_mode');

      expect(rows.single.values.single, 'wal');
    });

    test('sets a busy timeout on the connection', () async {
      final dir = await Directory.systemTemp.createTemp('habitudes_busy_test');
      addTearDown(() => dir.delete(recursive: true));
      final path = '${dir.path}/test.db';

      await DatabaseService.open(path, onCreate: (db, version) async {});

      final probe = await openDatabase(path);
      addTearDown(probe.close);
      final rows = await probe.rawQuery('PRAGMA busy_timeout');

      expect(rows.single.values.single, 3000);
    });
  });
}

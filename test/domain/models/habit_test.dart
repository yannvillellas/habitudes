import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/domain/models/habit.dart';

void main() {
  group('Habit', () {
    final habit = Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6));

    group('==', () {
      test('is identical for same instance', () {
        expect(habit == habit, isTrue);
      });

      test('is equal when all fields match', () {
        final other = Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6));
        expect(habit, equals(other));
      });

      test('is not equal when id differs', () {
        final other = Habit(id: 'h2', name: 'Read', createdAt: DateTime.utc(2026, 5, 6));
        expect(habit, isNot(equals(other)));
      });

      test('is not equal when name differs', () {
        final other = Habit(id: 'h1', name: 'Walk', createdAt: DateTime.utc(2026, 5, 6));
        expect(habit, isNot(equals(other)));
      });

      test('is not equal when createdAt differs', () {
        final other = Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 7));
        expect(habit, isNot(equals(other)));
      });

      test('is not equal to a different type', () {
        // ignore: unrelated_type_equality_checks
        expect(habit == 'not a habit', isFalse);
      });
    });

    group('hashCode', () {
      test('is equal when all fields match', () {
        final other = Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 6));
        expect(habit.hashCode, equals(other.hashCode));
      });

      test('differs when id differs', () {
        final other = Habit(id: 'h2', name: 'Read', createdAt: DateTime.utc(2026, 5, 6));
        expect(habit.hashCode, isNot(equals(other.hashCode)));
      });

      test('differs when name differs', () {
        final other = Habit(id: 'h1', name: 'Walk', createdAt: DateTime.utc(2026, 5, 6));
        expect(habit.hashCode, isNot(equals(other.hashCode)));
      });

      test('differs when createdAt differs', () {
        final other = Habit(id: 'h1', name: 'Read', createdAt: DateTime.utc(2026, 5, 7));
        expect(habit.hashCode, isNot(equals(other.hashCode)));
      });
    });
  });
}

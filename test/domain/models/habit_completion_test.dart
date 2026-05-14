import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/domain/models/habit_completion.dart';

void main() {
  group('HabitCompletion', () {
    final completion = HabitCompletion(habitId: 'h1', date: DateTime.utc(2026, 5, 6));

    group('==', () {
      test('is identical for same instance', () {
        expect(completion == completion, isTrue);
      });

      test('is equal when all fields match', () {
        final other = HabitCompletion(habitId: 'h1', date: DateTime.utc(2026, 5, 6));
        expect(completion, equals(other));
      });

      test('is not equal when habitId differs', () {
        final other = HabitCompletion(habitId: 'h2', date: DateTime.utc(2026, 5, 6));
        expect(completion, isNot(equals(other)));
      });

      test('is not equal when date differs', () {
        final other = HabitCompletion(habitId: 'h1', date: DateTime.utc(2026, 5, 7));
        expect(completion, isNot(equals(other)));
      });

      test('is not equal to a different type', () {
        // ignore: unrelated_type_equality_checks
        expect(completion == 'not a completion', isFalse);
      });
    });

    group('hashCode', () {
      test('is equal when all fields match', () {
        final other = HabitCompletion(habitId: 'h1', date: DateTime.utc(2026, 5, 6));
        expect(completion.hashCode, equals(other.hashCode));
      });

      test('differs when habitId differs', () {
        final other = HabitCompletion(habitId: 'h2', date: DateTime.utc(2026, 5, 6));
        expect(completion.hashCode, isNot(equals(other.hashCode)));
      });

      test('differs when date differs', () {
        final other = HabitCompletion(habitId: 'h1', date: DateTime.utc(2026, 5, 7));
        expect(completion.hashCode, isNot(equals(other.hashCode)));
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/domain/models/habit_completion.dart';
import 'package:habitudes/domain/models/habit_score.dart';

void main() {
  group('HabitScore', () {
    group('asymptotic rise', () {
      test('new habit with no history returns 0', () {
        final score = HabitScore.calculate(
          completions: [],
          habitCreatedAt: DateTime.now(),
          today: DateTime.now(),
        );

        expect(score, 0);
      });

      test('perfect streak approaches 100 asymptotically', () {
        final now = DateTime(2026, 6, 18);
        final createdAt = DateTime(2026, 4, 1);
        final completions = List.generate(
          79,
          (i) => HabitCompletion(habitId: 'test', date: DateTime(2026, 4, 1).add(Duration(days: i))),
        );

        final score = HabitScore.calculate(
          completions: completions,
          habitCreatedAt: createdAt,
          today: now,
        );

        expect(score, greaterThan(95));
        expect(score, lessThanOrEqualTo(100));
      });

      test('66 perfect days reaches approximately 96 percent', () {
        final createdAt = DateTime(2026, 1, 1);
        final completions = List.generate(
          66,
          (i) => HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 1).add(Duration(days: i))),
        );
        final today = DateTime(2026, 1, 1).add(const Duration(days: 65));

        final score = HabitScore.calculate(
          completions: completions,
          habitCreatedAt: createdAt,
          today: today,
        );

        expect(score, inInclusiveRange(94, 98));
      });

      test('score caps at 100 and never exceeds', () {
        final createdAt = DateTime(2026, 1, 1);
        final completions = List.generate(
          200,
          (i) => HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 1).add(Duration(days: i))),
        );
        final today = DateTime(2026, 1, 1).add(const Duration(days: 199));

        final score = HabitScore.calculate(
          completions: completions,
          habitCreatedAt: createdAt,
          today: today,
        );

        expect(score, equals(100));
      });
    });

    group('single miss', () {
      test('has no penalty', () {
        final createdAt = DateTime(2026, 4, 1);
        final completions = List.generate(
          30,
          (i) => HabitCompletion(habitId: 'test', date: DateTime(2026, 4, 1).add(Duration(days: i))),
        );
        final lastCompleted = DateTime(2026, 4, 1).add(const Duration(days: 29));

        final scoreBeforeMiss = HabitScore.calculate(
          completions: completions,
          habitCreatedAt: createdAt,
          today: lastCompleted,
        );
        final scoreAfterOneMiss = HabitScore.calculate(
          completions: completions,
          habitCreatedAt: createdAt,
          today: lastCompleted.add(const Duration(days: 1)),
        );

        expect(scoreAfterOneMiss, equals(scoreBeforeMiss));
      });

      test('alternating complete-miss has no penalty (each miss starts a new streak)', () {
        final createdAt = DateTime(2026, 1, 1);
        // day 1-5: complete, day 6: miss, day 7: complete, day 8: miss, day 9: complete
        final completions = [
          HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 1)),
          HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 2)),
          HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 3)),
          HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 4)),
          HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 5)),
          // miss Jan 6
          HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 7)),
          // miss Jan 8
          HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 9)),
        ];

        final score = HabitScore.calculate(
          completions: completions,
          habitCreatedAt: createdAt,
          today: DateTime(2026, 1, 9),
        );

        // 5 days → 22.6, + 1 day miss (no penalty) + 1 day complete → 26.5
        // + 1 day miss (no penalty) + 1 day complete → 30.2
        expect(score, inInclusiveRange(29, 32));
      });
    });

    group('consecutive miss penalty', () {
      test('two misses from score 64 applies moderate penalty', () {
        final createdAt = DateTime(2026, 1, 1);
        final completions = List.generate(
          20,
          (i) => HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 1).add(Duration(days: i))),
        );
        final today = DateTime(2026, 1, 1).add(const Duration(days: 21));

        final score = HabitScore.calculate(
          completions: completions,
          habitCreatedAt: createdAt,
          today: today,
        );

        expect(score, inInclusiveRange(59, 62));
      });

      test('three misses from score 64 applies escalating penalty', () {
        final createdAt = DateTime(2026, 1, 1);
        final completions = List.generate(
          20,
          (i) => HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 1).add(Duration(days: i))),
        );
        final today = DateTime(2026, 1, 1).add(const Duration(days: 22));

        final score = HabitScore.calculate(
          completions: completions,
          habitCreatedAt: createdAt,
          today: today,
        );

        expect(score, inInclusiveRange(51, 55));
      });

      test('four misses from score 64 continues escalating', () {
        final createdAt = DateTime(2026, 1, 1);
        final completions = List.generate(
          20,
          (i) => HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 1).add(Duration(days: i))),
        );
        final today = DateTime(2026, 1, 1).add(const Duration(days: 23));

        final score = HabitScore.calculate(
          completions: completions,
          habitCreatedAt: createdAt,
          today: today,
        );

        expect(score, inInclusiveRange(41, 44));
      });
    });

    group('strength-gated decay', () {
      test('strong habit decays slowly over a week', () {
        final createdAt = DateTime(2026, 1, 1);
        final completions = List.generate(
          60,
          (i) => HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 1).add(Duration(days: i))),
        );
        final today = DateTime(2026, 1, 1).add(const Duration(days: 66));

        final score = HabitScore.calculate(
          completions: completions,
          habitCreatedAt: createdAt,
          today: today,
        );

        expect(score, inInclusiveRange(84, 87));
      });

      test('strong habit survives a two-week vacation', () {
        final createdAt = DateTime(2026, 1, 1);
        final completions = List.generate(
          60,
          (i) => HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 1).add(Duration(days: i))),
        );
        final today = DateTime(2026, 1, 1).add(const Duration(days: 73));

        final score = HabitScore.calculate(
          completions: completions,
          habitCreatedAt: createdAt,
          today: today,
        );

        expect(score, inInclusiveRange(61, 65));
      });

      test('weak habit decays quickly', () {
        final createdAt = DateTime(2026, 1, 1);
        final completions = List.generate(
          5,
          (i) => HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 1).add(Duration(days: i))),
        );
        final today = DateTime(2026, 1, 1).add(const Duration(days: 7));

        final score = HabitScore.calculate(
          completions: completions,
          habitCreatedAt: createdAt,
          today: today,
        );

        expect(score, equals(0));
      });
    });

    group('decay rate', () {
      test('initial rate stays fixed throughout miss streak', () {
        final createdAt = DateTime(2026, 1, 1);
        final completions = List.generate(
          20,
          (i) => HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 1).add(Duration(days: i))),
        );
        // miss days 21-28 (8 consecutive misses)
        final today = DateTime(2026, 1, 1).add(const Duration(days: 27));

        final score = HabitScore.calculate(
          completions: completions,
          habitCreatedAt: createdAt,
          today: today,
        );

        // With initial rate 0.36, after 8 misses score should be around
        // 64.15 - penalties(0, 3.6, 7.2, 10.8, 14.4, 18.0, 21.6, 25.2) = negative → 0
        // But with cap at 7, after day 7 penalty maxes at 25.2/day
        // After 8 misses from 64 with decay at 0.36, it dies
        expect(score, inInclusiveRange(0, 5));
      });

      test('new miss streak captures a new initial rate', () {
        final createdAt = DateTime(2026, 1, 1);
        // 20 perfect days
        final completions = List.generate(
          20,
          (i) => HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 1).add(Duration(days: i))),
        );
        // miss day 21, complete day 22, miss day 23-24
        completions.add(HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 22)));
        final today = DateTime(2026, 1, 1).add(const Duration(days: 23));

        final score = HabitScore.calculate(
          completions: completions,
          habitCreatedAt: createdAt,
          today: today,
        );

        // Day 20: 64.15
        // Day 21: miss, no penalty
        // Day 22: complete, 65.94
        // Day 23: miss, new initial rate at 0.34 (not 0.36), no penalty
        // Day 24: miss, 0.34 × 1 × 10 = 3.4 penalty, score = 62.5 → 63
        expect(score, inInclusiveRange(61, 64));
      });
    });

    group('recovery', () {
      test('single miss then complete continues growth from same score', () {
        final createdAt = DateTime(2026, 1, 1);
        final completions = List.generate(
          20,
          (i) => HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 1).add(Duration(days: i))),
        );
        completions.add(HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 22)));
        final today = DateTime(2026, 1, 1).add(const Duration(days: 21));

        final score = HabitScore.calculate(
          completions: completions,
          habitCreatedAt: createdAt,
          today: today,
        );

        expect(score, inInclusiveRange(64, 67));
      });

      test('three misses then three completions recovers gradually', () {
        final createdAt = DateTime(2026, 1, 1);
        // 20 perfect days, miss 21-23, complete 24-26
        final completions = List.generate(
          20,
          (i) => HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 1).add(Duration(days: i))),
        );
        completions.addAll([
          HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 24)),
          HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 25)),
          HabitCompletion(habitId: 'test', date: DateTime(2026, 1, 26)),
        ]);
        final today = DateTime(2026, 1, 1).add(const Duration(days: 25));

        final score = HabitScore.calculate(
          completions: completions,
          habitCreatedAt: createdAt,
          today: today,
        );

        // Day 20: 64.15
        // Days 21-23: 3 misses → ~53.4
        // Days 24-26: 3 completions → recovers to ~60
        expect(score, inInclusiveRange(58, 62));
      });
    });

    group('edge cases', () {
      test('score floors at 0 and never goes negative', () {
        final createdAt = DateTime(2026, 1, 1);
        final completions = <HabitCompletion>[];
        final today = DateTime(2026, 1, 1).add(const Duration(days: 49));

        final score = HabitScore.calculate(
          completions: completions,
          habitCreatedAt: createdAt,
          today: today,
        );

        expect(score, equals(0));
      });
    });
  });
}

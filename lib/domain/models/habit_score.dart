import 'package:flutter/foundation.dart';

import 'habit_completion.dart';

/// Calculates habit strength as a 0–100 score using an asymptotic exponential
/// moving average (EMA) model grounded in habit formation research.
///
/// ## Research Basis
///
/// Based on Lally et al. (2009), _European Journal of Social Psychology_:
/// - **Average time to reach automaticity plateau: 66 days** (range 18–254).
/// - The data fit an **asymptotic curve**: rapid initial rise that plateaus as
///   the behavior becomes automatic.
/// - A single missed day **does not materially affect** habit formation.
/// - Persistent inconsistency **prevents** habit formation.
///
/// The "never miss twice" principle (James Clear, _Atomic Habits_) is a
/// practical interpretation: one miss is harmless, two consecutive misses
/// begin to weaken the habit.
///
/// **Important**: Lally et al. did not publish a single equation with fixed
/// parameters. They fitted individual curves per participant and reported the
/// *time to asymptote* as their main result. The α and penalty values here
/// are **design choices calibrated** to match the observed 66-day average
/// and the qualitative findings.
///
/// ## Algorithm — Asymptotic Rise (completed day)
///
/// ```
/// score = min(100, score + α × (100 − score))
/// ```
///
/// Each completed day closes α% of the remaining gap to 100, a discrete
/// approximation of the asymptotic curve observed in the research.
///
/// **α = 0.05** is chosen so that perfect consistency reaches ~96% at 66 days:
/// `100 × (1 − 0.95⁶⁶) ≈ 96.6`. Scores ≥ 99.5 round to 100.
///
/// ## Algorithm — Strength-Gated Decay (missed day)
///
/// ```
/// // At the start of each miss streak:
/// initialDecayFraction = (100 − score) / 100

/// // On subsequent missed days:
/// penalty = initialDecayFraction × min(consecutiveMisses, cap) × step
/// score = max(0, score − penalty)
/// ```
///
/// - **First miss**: no penalty (consecutiveMisses = 0).
/// - **Subsequent misses**: escalating penalty proportional to how unformed
///   the habit was *when the miss streak started*. The initial decay rate
///   ensures that a strong habit remains stubborn even during a
///   long absence — the score doesn't accelerate toward zero.
/// - **Cap at 7**: prevents runaway decay. After 7 consecutive misses the
///   daily penalty stabilizes rather than growing indefinitely.
///
/// | Score | decayFraction | 2m | 4m | 7m | 14m |
/// |-------|---------------|-----|-----|------|------|
/// | 95    | 0.05          | −0  | −2  | −9   | −24  |
/// | 64    | 0.36          | −4  | −11 | −26  | −53  |
/// | 23    | 0.77          | −8  | −23 | —    | —    |
///
@immutable
class HabitScore {
  /// Learning rate for the asymptotic rise — each completed day closes 5%
  /// of the remaining gap to 100.
  ///
  /// Chosen to produce ~96% automaticity at 66 days (Lally's 2009 average).
  static const double _alphaRise = 0.05;

  /// Base penalty unit for decay on consecutive missed days.
  ///
  /// Actual penalty: `initialDecayFraction × min(consecutiveMisses, _cap) × _penaltyStep`.
  ///
  /// At score=64 (decayFraction=0.36), the 2nd consecutive miss drops ~3.6 pts,
  /// the 4th drops ~10.8 pts. At score=95 (decayFraction=0.05), the same misses
  /// drop only ~0.5 and ~1.5 pts.
  static const double _penaltyStep = 10.0;

  /// Cap on the consecutive-miss multiplier.
  ///
  /// After 7 consecutive misses the daily penalty plateaus at
  /// `initialDecayFraction × 7 × _penaltyStep` rather than growing indefinitely.
  static const int _cap = 7;

  /// Calculates the habit strength score (0–100).
  ///
  /// Iterates over every day from [habitCreatedAt] to [today] inclusive,
  /// applying the asymptotic rise for completed days and the strength-gated
  /// decay for missed days, with the initial rate fixed at the start of
  /// each miss streak.
  static int calculate({
    required List<HabitCompletion> completions,
    required DateTime habitCreatedAt,
    required DateTime today,
  }) {
    final normalizedCompletions = completions.map((c) => _normalize(c.date)).toSet();

    final normalizedToday = _normalize(today);
    final normalizedCreatedAt = _normalize(habitCreatedAt);

    int consecutiveMisses = 0;
    double score = 0.0;
    double initialDecayFraction = 0.0;

    var date = normalizedCreatedAt;
    while (!date.isAfter(normalizedToday)) {
      final isCompleted = normalizedCompletions.contains(date);

      if (isCompleted) {
        score = score + _alphaRise * (100 - score);
        consecutiveMisses = 0;
      } else {
        if (consecutiveMisses == 0) {
          initialDecayFraction = (100.0 - score) / 100.0;
        } else {
          final cappedMisses = consecutiveMisses > _cap ? _cap : consecutiveMisses;
          final penalty = initialDecayFraction * cappedMisses * _penaltyStep;
          score = (score - penalty).clamp(0.0, 100.0);
        }
        consecutiveMisses++;
      }
      date = _normalize(date.add(const Duration(days: 1)));
    }

    return score.round();
  }

  static DateTime _normalize(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }
}

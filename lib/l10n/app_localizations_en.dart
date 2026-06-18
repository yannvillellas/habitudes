// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Habitudes';

  @override
  String get noHabitsYet => 'No habits yet';

  @override
  String get failedToLoadHabits => 'Failed to load habits';

  @override
  String get tryAgain => 'Try again';

  @override
  String get noCompletionsYet => 'No completions yet';

  @override
  String get habitNotFound => 'Habit not found';

  @override
  String get delete => 'Delete';

  @override
  String get failedToUpdate => 'Failed to update';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'Save';

  @override
  String get habitDefaultTitle => 'Habit';

  @override
  String get newHabitHint => 'New habit';

  @override
  String get habitScoreStartingOut => 'Starting out';

  @override
  String get habitScoreBuilding => 'Building';

  @override
  String get habitScoreTakingShape => 'Taking shape';

  @override
  String get habitScoreStrongHabit => 'Strong habit';

  @override
  String get habitScoreAutomatic => 'Automatic';
}

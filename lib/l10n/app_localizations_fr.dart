// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Habitudes';

  @override
  String get noHabitsYet => 'Aucune habitude';

  @override
  String get failedToLoadHabits => 'Échec du chargement';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get noCompletionsYet => 'Aucune réalisation';

  @override
  String get habitNotFound => 'Habitude introuvable';

  @override
  String get delete => 'Supprimer';

  @override
  String get failedToUpdate => 'Échec de la mise à jour';

  @override
  String get retry => 'Réessayer';

  @override
  String get save => 'Enregistrer';

  @override
  String get habitDefaultTitle => 'Habitude';

  @override
  String get newHabitHint => 'Nouvelle habitude';
}

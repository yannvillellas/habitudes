import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Title of the application
  ///
  /// In en, this message translates to:
  /// **'Habitudes'**
  String get appTitle;

  /// Empty state when no habits have been created
  ///
  /// In en, this message translates to:
  /// **'No habits yet'**
  String get noHabitsYet;

  /// Error message when habits fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load habits'**
  String get failedToLoadHabits;

  /// Button label to retry a failed action
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Empty state when no completions exist for a habit
  ///
  /// In en, this message translates to:
  /// **'No completions yet'**
  String get noCompletionsYet;

  /// Error message when a habit does not exist
  ///
  /// In en, this message translates to:
  /// **'Habit not found'**
  String get habitNotFound;

  /// Menu option to delete a habit
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Error snackbar message when toggle fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update'**
  String get failedToUpdate;

  /// Snackbar action to retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Button label to save a new habit
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Default title when habit name is not yet loaded
  ///
  /// In en, this message translates to:
  /// **'Habit'**
  String get habitDefaultTitle;

  /// Placeholder text in the new habit text field
  ///
  /// In en, this message translates to:
  /// **'New habit'**
  String get newHabitHint;

  /// Score band label for habits at 0-20
  ///
  /// In en, this message translates to:
  /// **'Starting out'**
  String get habitScoreStartingOut;

  /// Score band label for habits at 20-50
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get habitScoreBuilding;

  /// Score band label for habits at 50-80
  ///
  /// In en, this message translates to:
  /// **'Taking shape'**
  String get habitScoreTakingShape;

  /// Score band label for habits at 80-95
  ///
  /// In en, this message translates to:
  /// **'Strong habit'**
  String get habitScoreStrongHabit;

  /// Score band label for habits at 95-100
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get habitScoreAutomatic;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

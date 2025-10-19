import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get appTitle;

  /// No description provided for @home_achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get home_achievements;

  /// No description provided for @home_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get home_profile;

  /// No description provided for @home_shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get home_shop;

  /// No description provided for @profile_title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile_title;

  /// No description provided for @profile_progress_by_countries.
  ///
  /// In en, this message translates to:
  /// **'Country progress'**
  String get profile_progress_by_countries;

  /// No description provided for @profile_no_progress.
  ///
  /// In en, this message translates to:
  /// **'No games yet…'**
  String get profile_no_progress;

  /// No description provided for @profile_achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get profile_achievements;

  /// No description provided for @profile_show_all.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get profile_show_all;

  /// No description provided for @profile_rewards.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get profile_rewards;

  /// No description provided for @profile_no_rewards.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get profile_no_rewards;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @fact_prefix.
  ///
  /// In en, this message translates to:
  /// **'Fact: '**
  String get fact_prefix;

  /// No description provided for @error_prefix.
  ///
  /// In en, this message translates to:
  /// **'Error: '**
  String get error_prefix;

  /// No description provided for @levels_word.
  ///
  /// In en, this message translates to:
  /// **'levels'**
  String get levels_word;

  /// No description provided for @level_word.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level_word;

  /// No description provided for @reward_received.
  ///
  /// In en, this message translates to:
  /// **'Added to collection!'**
  String get reward_received;

  /// No description provided for @open_rewards_action.
  ///
  /// In en, this message translates to:
  /// **'Open collection'**
  String get open_rewards_action;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cat_classic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get cat_classic;

  /// No description provided for @cat_hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get cat_hard;

  /// No description provided for @cat_food_drinks.
  ///
  /// In en, this message translates to:
  /// **'Food & Drinks'**
  String get cat_food_drinks;

  /// No description provided for @cat_games_entertainment.
  ///
  /// In en, this message translates to:
  /// **'Games & Entertainment'**
  String get cat_games_entertainment;

  /// No description provided for @cat_cinema_animation.
  ///
  /// In en, this message translates to:
  /// **'Cinema & Animation'**
  String get cat_cinema_animation;

  /// No description provided for @cat_architecture.
  ///
  /// In en, this message translates to:
  /// **'Architecture'**
  String get cat_architecture;

  /// No description provided for @cat_legends_myths.
  ///
  /// In en, this message translates to:
  /// **'Legends & Myths'**
  String get cat_legends_myths;

  /// No description provided for @cat_history_personalities.
  ///
  /// In en, this message translates to:
  /// **'Historical Personalities'**
  String get cat_history_personalities;

  /// No description provided for @cat_transport_tech.
  ///
  /// In en, this message translates to:
  /// **'Transport & Technology'**
  String get cat_transport_tech;

  /// No description provided for @cat_unexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected'**
  String get cat_unexpected;

  /// No description provided for @login_title.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get login_title;

  /// No description provided for @login_hint.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest or sign in with e-mail (local).'**
  String get login_hint;

  /// No description provided for @login_button.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get login_button;

  /// No description provided for @login_guest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get login_guest;

  /// No description provided for @login_new_user.
  ///
  /// In en, this message translates to:
  /// **'New user?'**
  String get login_new_user;

  /// No description provided for @login_enter_email.
  ///
  /// In en, this message translates to:
  /// **'Enter e-mail'**
  String get login_enter_email;

  /// No description provided for @login_local_profile_creates.
  ///
  /// In en, this message translates to:
  /// **'A local profile is created on sign-in'**
  String get login_local_profile_creates;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_section_basic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get settings_section_basic;

  /// No description provided for @settings_volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get settings_volume;

  /// No description provided for @settings_sounds.
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get settings_sounds;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_language_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settings_language_system;

  /// No description provided for @settings_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settings_account;

  /// No description provided for @settings_sign_out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settings_sign_out;

  /// No description provided for @action_hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get action_hide;

  /// No description provided for @action_show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get action_show;

  /// No description provided for @action_show_more.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get action_show_more;

  /// No description provided for @action_show_less.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get action_show_less;

  /// No description provided for @action_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get action_cancel;

  /// No description provided for @action_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get action_yes;

  /// No description provided for @action_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get action_done;

  /// No description provided for @rank_title.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rank_title;

  /// No description provided for @rank_bronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get rank_bronze;

  /// No description provided for @rank_silver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get rank_silver;

  /// No description provided for @rank_gold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get rank_gold;

  /// No description provided for @rank_legend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get rank_legend;

  /// No description provided for @country_japan.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get country_japan;

  /// No description provided for @country_france.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get country_france;

  /// No description provided for @country_brazil.
  ///
  /// In en, this message translates to:
  /// **'Brazil'**
  String get country_brazil;

  /// No description provided for @country_norway.
  ///
  /// In en, this message translates to:
  /// **'Norway'**
  String get country_norway;

  /// No description provided for @country_egypt.
  ///
  /// In en, this message translates to:
  /// **'Egypt'**
  String get country_egypt;

  /// No description provided for @country_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get country_other;

  /// No description provided for @profile_reset_all_cta.
  ///
  /// In en, this message translates to:
  /// **'Reset all'**
  String get profile_reset_all_cta;

  /// No description provided for @profile_reset_all_title.
  ///
  /// In en, this message translates to:
  /// **'Reset progress & collection'**
  String get profile_reset_all_title;

  /// No description provided for @profile_fill_all_cta.
  ///
  /// In en, this message translates to:
  /// **'All 3★ + collection'**
  String get profile_fill_all_cta;

  /// No description provided for @profile_fill_all_title.
  ///
  /// In en, this message translates to:
  /// **'Mark all levels as 3★ and fill collection'**
  String get profile_fill_all_title;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

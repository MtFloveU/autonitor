import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// Label for the language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'Autonitor'**
  String get app_title;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @switchAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch Account'**
  String get switchAccount;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @new_account.
  ///
  /// In en, this message translates to:
  /// **'Add a new account'**
  String get new_account;

  /// No description provided for @view_cookie.
  ///
  /// In en, this message translates to:
  /// **'View Cookie'**
  String get view_cookie;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @view_on_twitter.
  ///
  /// In en, this message translates to:
  /// **'View on Twitter'**
  String get view_on_twitter;

  /// No description provided for @metadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get metadata;

  /// No description provided for @tweets.
  ///
  /// In en, this message translates to:
  /// **'Tweets'**
  String get tweets;

  /// No description provided for @media_count.
  ///
  /// In en, this message translates to:
  /// **'Media Count'**
  String get media_count;

  /// No description provided for @likes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likes;

  /// No description provided for @listed_count.
  ///
  /// In en, this message translates to:
  /// **'Listed Count'**
  String get listed_count;

  /// No description provided for @identity.
  ///
  /// In en, this message translates to:
  /// **'Identity-related'**
  String get identity;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @suspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get suspended;

  /// No description provided for @deactivated.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get deactivated;

  /// No description provided for @normal_unfollowed.
  ///
  /// In en, this message translates to:
  /// **'Normal Unfollowed'**
  String get normal_unfollowed;

  /// No description provided for @be_followed_back.
  ///
  /// In en, this message translates to:
  /// **'Be Followed Back'**
  String get be_followed_back;

  /// No description provided for @mutual_unfollowed.
  ///
  /// In en, this message translates to:
  /// **'Mutual Unfollowed'**
  String get mutual_unfollowed;

  /// No description provided for @oneway_unfollowed.
  ///
  /// In en, this message translates to:
  /// **'One-way Unfollowed'**
  String get oneway_unfollowed;

  /// No description provided for @new_followers_following.
  ///
  /// In en, this message translates to:
  /// **'New Followers & Following'**
  String get new_followers_following;

  /// No description provided for @empty_list_message.
  ///
  /// In en, this message translates to:
  /// **'The list is empty'**
  String get empty_list_message;

  /// No description provided for @switch_account.
  ///
  /// In en, this message translates to:
  /// **'Switch Account'**
  String get switch_account;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get run;

  /// No description provided for @choose_login_method.
  ///
  /// In en, this message translates to:
  /// **'Choose Login Method'**
  String get choose_login_method;

  /// No description provided for @browser_login.
  ///
  /// In en, this message translates to:
  /// **'Login via Browser'**
  String get browser_login;

  /// No description provided for @manual_cookie.
  ///
  /// In en, this message translates to:
  /// **'Manual Cookie Input'**
  String get manual_cookie;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @im_logged_in.
  ///
  /// In en, this message translates to:
  /// **'I\'m logged in'**
  String get im_logged_in;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @account_added_successfully.
  ///
  /// In en, this message translates to:
  /// **'Account added successfully!'**
  String get account_added_successfully;

  /// No description provided for @saving_account.
  ///
  /// In en, this message translates to:
  /// **'Saving account...'**
  String get saving_account;

  /// No description provided for @cookie.
  ///
  /// In en, this message translates to:
  /// **'Cookie'**
  String get cookie;

  /// No description provided for @no_cookie_found.
  ///
  /// In en, this message translates to:
  /// **'No cookie found'**
  String get no_cookie_found;

  /// No description provided for @no_auth_token_found.
  ///
  /// In en, this message translates to:
  /// **'No auth_token found'**
  String get no_auth_token_found;

  /// No description provided for @found_auth_token_last_check.
  ///
  /// In en, this message translates to:
  /// **'Auth Token found in last check'**
  String get found_auth_token_last_check;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @login_first.
  ///
  /// In en, this message translates to:
  /// **'Log in Needed'**
  String get login_first;

  /// No description provided for @login_first_description.
  ///
  /// In en, this message translates to:
  /// **'Add at least one account to continue'**
  String get login_first_description;

  /// No description provided for @log_in.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get log_in;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm_delete_account.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete account {accountId}? This action cannot be undone.'**
  String confirm_delete_account(Object accountId);
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

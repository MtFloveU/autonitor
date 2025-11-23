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
  /// **'Add/Update an account'**
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
  /// **'Statistics'**
  String get metadata;

  /// No description provided for @user_content.
  ///
  /// In en, this message translates to:
  /// **'User Content'**
  String get user_content;

  /// No description provided for @pinned_tweet_id.
  ///
  /// In en, this message translates to:
  /// **'Pinned Tweet ID'**
  String get pinned_tweet_id;

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
  /// **'I\'ve logged in'**
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
  /// **'Are you sure you want to delete account {accountId}? This action cannot be undone. Deleting an account will permanently remove all its associated data (history, follower/following lists etc.). If you only want to update the cookie, simply add the account again.'**
  String confirm_delete_account(Object accountId);

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied_to_clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard!'**
  String get copied_to_clipboard;

  /// No description provided for @no_json_data_available.
  ///
  /// In en, this message translates to:
  /// **'No JSON data available'**
  String get no_json_data_available;

  /// No description provided for @temporarily_restricted.
  ///
  /// In en, this message translates to:
  /// **'Temporarily Restricted'**
  String get temporarily_restricted;

  /// No description provided for @failed_to_load_user_list.
  ///
  /// In en, this message translates to:
  /// **'Failed to load user list'**
  String get failed_to_load_user_list;

  /// No description provided for @no_users_in_this_category.
  ///
  /// In en, this message translates to:
  /// **'Empty list'**
  String get no_users_in_this_category;

  /// No description provided for @analysis_log.
  ///
  /// In en, this message translates to:
  /// **'Analysis Log'**
  String get analysis_log;

  /// No description provided for @no_active_account_error.
  ///
  /// In en, this message translates to:
  /// **'Cannot run analysis: No account is active.'**
  String get no_active_account_error;

  /// No description provided for @analysis_failed_error.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed'**
  String get analysis_failed_error;

  /// No description provided for @no_analysis_data.
  ///
  /// In en, this message translates to:
  /// **'No analysis data found'**
  String get no_analysis_data;

  /// No description provided for @run_analysis_now.
  ///
  /// In en, this message translates to:
  /// **'Run Analysis Now'**
  String get run_analysis_now;

  /// No description provided for @last_updated_at.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String last_updated_at(String date);

  /// No description provided for @user_history_page_title.
  ///
  /// In en, this message translates to:
  /// **'Profile History'**
  String get user_history_page_title;

  /// No description provided for @storage_settings.
  ///
  /// In en, this message translates to:
  /// **'Storage Settings'**
  String get storage_settings;

  /// No description provided for @save_avatar_history.
  ///
  /// In en, this message translates to:
  /// **'Save Avatar'**
  String get save_avatar_history;

  /// No description provided for @save_banner_history.
  ///
  /// In en, this message translates to:
  /// **'Save Banner'**
  String get save_banner_history;

  /// No description provided for @avatar_quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get avatar_quality;

  /// e.g. 48x48, _normal suffix
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get quality_low;

  /// e.g. 400x400, _400x400 suffix
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get quality_high;

  /// No description provided for @history_strategy.
  ///
  /// In en, this message translates to:
  /// **'History Avatar/Banner Storage Strategy'**
  String get history_strategy;

  /// No description provided for @strategy_save_all.
  ///
  /// In en, this message translates to:
  /// **'Never Delete'**
  String get strategy_save_all;

  /// No description provided for @strategy_save_latest.
  ///
  /// In en, this message translates to:
  /// **'Keep Latest Only'**
  String get strategy_save_latest;

  /// No description provided for @strategy_save_last_n.
  ///
  /// In en, this message translates to:
  /// **'Delete avatar/banner older than last'**
  String get strategy_save_last_n;

  /// No description provided for @strategy_save_last_n_suffix.
  ///
  /// In en, this message translates to:
  /// **'changes'**
  String get strategy_save_last_n_suffix;

  /// No description provided for @theme_mode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme_mode;

  /// No description provided for @theme_mode_system.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get theme_mode_system;

  /// No description provided for @theme_mode_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get theme_mode_light;

  /// No description provided for @theme_mode_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get theme_mode_dark;

  /// No description provided for @log.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get log;

  /// No description provided for @view_log.
  ///
  /// In en, this message translates to:
  /// **'View Logs'**
  String get view_log;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @api_request_settings.
  ///
  /// In en, this message translates to:
  /// **'API Request Settings'**
  String get api_request_settings;

  /// Dialog title for XClientTransactionID Generator
  ///
  /// In en, this message translates to:
  /// **'XClientTransactionID Generator'**
  String get xclient_generator_title;

  /// Label for the count input field in ID generator dialog
  ///
  /// In en, this message translates to:
  /// **'Number of IDs to be generated:'**
  String get num_ids_to_generate;

  /// Snackbar message shown when invalid number entered
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number (1-100)'**
  String get please_enter_valid_number;

  /// Snackbar message shown when path not starting with /
  ///
  /// In en, this message translates to:
  /// **'Path must start with /'**
  String get path_must_start_with_slash;

  /// Shown when fetching resources before generating IDs
  ///
  /// In en, this message translates to:
  /// **'Fetching resources'**
  String get fetching_resources;

  /// Message shown during local ID generation
  ///
  /// In en, this message translates to:
  /// **'Generating {count} IDs (local)...'**
  String generating_ids_local(int count);

  /// Error message when generation canceled
  ///
  /// In en, this message translates to:
  /// **'Generation canceled.'**
  String get generation_canceled;

  /// Error message when generation failed
  ///
  /// In en, this message translates to:
  /// **'ID Generation Failed: {error}'**
  String id_generation_failed(String error);

  /// Label for progress state of generation button
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// Label for generate button
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// Shown when failed to load settings
  ///
  /// In en, this message translates to:
  /// **'Failed to load settings: {error}'**
  String load_settings_failed(String error);

  /// Label for the API path source selection
  ///
  /// In en, this message translates to:
  /// **'Source:'**
  String get xclient_generator_source;

  /// Button label to refresh API paths from the document
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Button label to reset custom paths to default values
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Label for the GraphQL operation name dropdown
  ///
  /// In en, this message translates to:
  /// **'Operation:'**
  String get operation_name;

  /// Label for the GQL QueryId configuration
  ///
  /// In en, this message translates to:
  /// **'GQL QueryId Configuration'**
  String get graphql_path_config;

  ///
  ///
  /// In en, this message translates to:
  /// **'Follows you'**
  String get follows_you;

  ///
  ///
  /// In en, this message translates to:
  /// **'Not Follow'**
  String get not_follow;

  ///
  ///
  /// In en, this message translates to:
  /// **'Automated by @{automatedScreenName}'**
  String automated_by(String automatedScreenName);
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

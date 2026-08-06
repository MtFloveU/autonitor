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

  /// Localized text for the app_title message.
  ///
  /// In en, this message translates to:
  /// **'Autonitor'**
  String get app_title;

  /// Description of the app
  ///
  /// In en, this message translates to:
  /// **'A FOSS Twitter follower analysis app that outperforms paid alternatives.'**
  String get app_description;

  /// Localized text for the settings message.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Localized text for the home message.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Localized text for the data message.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// Localized text for the accounts message.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// Localized text for the switchAccount message.
  ///
  /// In en, this message translates to:
  /// **'Switch Account'**
  String get switchAccount;

  /// Localized text for the followers message.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// Localized text for the following message.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// Localized text for the new_account message.
  ///
  /// In en, this message translates to:
  /// **'Add/Update an account'**
  String get new_account;

  /// Localized text for the view_cookie message.
  ///
  /// In en, this message translates to:
  /// **'View Cookie'**
  String get view_cookie;

  /// Localized text for the close message.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Localized text for the view_on_twitter message.
  ///
  /// In en, this message translates to:
  /// **'View on Twitter'**
  String get view_on_twitter;

  /// Localized text for the metadata message.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get metadata;

  /// Localized text for the user_content message.
  ///
  /// In en, this message translates to:
  /// **'User Content'**
  String get user_content;

  /// Localized text for the pinned_tweet_id message.
  ///
  /// In en, this message translates to:
  /// **'Pinned Tweet ID'**
  String get pinned_tweet_id;

  /// Localized text for the tweets message.
  ///
  /// In en, this message translates to:
  /// **'Tweets'**
  String get tweets;

  /// Localized text for the media_count message.
  ///
  /// In en, this message translates to:
  /// **'Media Count'**
  String get media_count;

  /// Localized text for the likes message.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likes;

  /// Localized text for the listed_count message.
  ///
  /// In en, this message translates to:
  /// **'Listed Count'**
  String get listed_count;

  /// Localized text for the identity message.
  ///
  /// In en, this message translates to:
  /// **'Identity-related'**
  String get identity;

  /// Localized text for the back message.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Localized text for the history message.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Localized text for the suspended message.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get suspended;

  /// Localized text for the deactivated message.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get deactivated;

  /// Localized text for the profile_updates message.
  ///
  /// In en, this message translates to:
  /// **'Profile Updates'**
  String get profile_updates;

  /// Localized text for the normal_unfollowed message.
  ///
  /// In en, this message translates to:
  /// **'Normal Unfollowed'**
  String get normal_unfollowed;

  /// Localized text for the be_followed_back message.
  ///
  /// In en, this message translates to:
  /// **'Be Followed Back'**
  String get be_followed_back;

  /// Localized text for the mutual_unfollowed message.
  ///
  /// In en, this message translates to:
  /// **'Mutual Unfollowed'**
  String get mutual_unfollowed;

  /// Localized text for the oneway_unfollowed message.
  ///
  /// In en, this message translates to:
  /// **'One-way Unfollowed'**
  String get oneway_unfollowed;

  /// Localized text for the new_followers_following message.
  ///
  /// In en, this message translates to:
  /// **'New Followers & Following'**
  String get new_followers_following;

  /// Localized text for the empty_list_message message.
  ///
  /// In en, this message translates to:
  /// **'The list is empty'**
  String get empty_list_message;

  /// Localized text for the switch_account message.
  ///
  /// In en, this message translates to:
  /// **'Switch Account'**
  String get switch_account;

  /// Localized text for the run message.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get run;

  /// Localized text for the choose_login_method message.
  ///
  /// In en, this message translates to:
  /// **'Choose Login Method'**
  String get choose_login_method;

  /// Localized text for the browser_login message.
  ///
  /// In en, this message translates to:
  /// **'Login via Browser'**
  String get browser_login;

  /// Localized text for the manual_cookie message.
  ///
  /// In en, this message translates to:
  /// **'Manual Cookie Input'**
  String get manual_cookie;

  /// Localized text for the joined message.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String joined(String date);

  /// Localized text for the im_logged_in message.
  ///
  /// In en, this message translates to:
  /// **'I\'ve logged in'**
  String get im_logged_in;

  /// Localized text for the cancel message.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Localized text for the ok message.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Localized text for the account_added_successfully message.
  ///
  /// In en, this message translates to:
  /// **'Account added successfully!'**
  String get account_added_successfully;

  /// Localized text for the saving_account message.
  ///
  /// In en, this message translates to:
  /// **'Saving account...'**
  String get saving_account;

  /// Localized text for the cookie message.
  ///
  /// In en, this message translates to:
  /// **'Cookie'**
  String get cookie;

  /// Localized text for the no_cookie_found message.
  ///
  /// In en, this message translates to:
  /// **'No cookie found'**
  String get no_cookie_found;

  /// Localized text for the no_auth_token_found message.
  ///
  /// In en, this message translates to:
  /// **'No auth_token found'**
  String get no_auth_token_found;

  /// Localized text for the found_auth_token_last_check message.
  ///
  /// In en, this message translates to:
  /// **'Auth Token found in last check'**
  String get found_auth_token_last_check;

  /// Localized text for the general message.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// Localized text for the login_first message.
  ///
  /// In en, this message translates to:
  /// **'Log in Needed'**
  String get login_first;

  /// Localized text for the no_accounts_added message.
  ///
  /// In en, this message translates to:
  /// **'No accounts added'**
  String get no_accounts_added;

  /// Localized text for the login_first_description message.
  ///
  /// In en, this message translates to:
  /// **'Add at least one account to continue'**
  String get login_first_description;

  /// Localized text for the log_in message.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get log_in;

  /// Localized text for the delete message.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Localized text for the confirm_delete_account message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete account {accountId}? This action cannot be undone. Deleting an account will permanently remove all its associated data (history, follower/following lists etc.). If you only want to update the cookie, simply add the account again.'**
  String confirm_delete_account(Object accountId);

  /// Localized text for the copy message.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Localized text for the copied_to_clipboard message.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard!'**
  String get copied_to_clipboard;

  /// Localized text for the no_json_data_available message.
  ///
  /// In en, this message translates to:
  /// **'No JSON data available'**
  String get no_json_data_available;

  /// Localized text for the temporarily_restricted message.
  ///
  /// In en, this message translates to:
  /// **'Temporarily Restricted'**
  String get temporarily_restricted;

  /// Localized text for the recovered message.
  ///
  /// In en, this message translates to:
  /// **'Recovered'**
  String get recovered;

  /// Localized text for the failed_to_load_user_list message.
  ///
  /// In en, this message translates to:
  /// **'Failed to load user list'**
  String get failed_to_load_user_list;

  /// Localized text for the no_users_in_this_category message.
  ///
  /// In en, this message translates to:
  /// **'Empty list'**
  String get no_users_in_this_category;

  /// Localized text for the user_not_found message.
  ///
  /// In en, this message translates to:
  /// **'User @{screenName} was not found in this account\'s data.'**
  String user_not_found(String screenName);

  /// Localized text for the open_in_autonitor message.
  ///
  /// In en, this message translates to:
  /// **'Open in Autonitor'**
  String get open_in_autonitor;

  /// Localized text for the analysis_log message.
  ///
  /// In en, this message translates to:
  /// **'Analysis Log'**
  String get analysis_log;

  /// Localized text for the no_active_account_error message.
  ///
  /// In en, this message translates to:
  /// **'Cannot run analysis: No account is active.'**
  String get no_active_account_error;

  /// Localized text for the analysis_failed_error message.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed'**
  String get analysis_failed_error;

  /// Localized text for the no_analysis_data message.
  ///
  /// In en, this message translates to:
  /// **'No analysis data found'**
  String get no_analysis_data;

  /// Localized text for the run_analysis_now message.
  ///
  /// In en, this message translates to:
  /// **'Run Analysis Now'**
  String get run_analysis_now;

  /// Localized text for the last_updated_at message.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String last_updated_at(String date);

  /// Localized text for the user_history_page_title message.
  ///
  /// In en, this message translates to:
  /// **'Profile History'**
  String get user_history_page_title;

  /// Localized text for the storage_settings message.
  ///
  /// In en, this message translates to:
  /// **'Storage Settings'**
  String get storage_settings;

  /// Localized text for the save_avatar_history message.
  ///
  /// In en, this message translates to:
  /// **'Save Avatar'**
  String get save_avatar_history;

  /// Localized text for the save_banner_history message.
  ///
  /// In en, this message translates to:
  /// **'Save Banner'**
  String get save_banner_history;

  /// Localized text for the media_save_scope message.
  ///
  /// In en, this message translates to:
  /// **'Media Saving Scope'**
  String get media_save_scope;

  /// Localized text for the media_save_all message.
  ///
  /// In en, this message translates to:
  /// **'All Accounts'**
  String get media_save_all;

  /// Option to save media only for accounts followed by the active account.
  ///
  /// In en, this message translates to:
  /// **'Accounts You Follow'**
  String get media_save_following_only;

  /// Localized text for the media_save_mutual_only message.
  ///
  /// In en, this message translates to:
  /// **'Mutual Follows Only'**
  String get media_save_mutual_only;

  /// Localized text for the avatar_quality message.
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

  /// Localized text for the history_strategy message.
  ///
  /// In en, this message translates to:
  /// **'History Avatar/Banner Storage Strategy'**
  String get history_strategy;

  /// Localized text for the strategy_save_all message.
  ///
  /// In en, this message translates to:
  /// **'Never Delete'**
  String get strategy_save_all;

  /// Localized text for the strategy_save_latest message.
  ///
  /// In en, this message translates to:
  /// **'Keep Latest Only'**
  String get strategy_save_latest;

  /// Localized text for the strategy_save_last_n message.
  ///
  /// In en, this message translates to:
  /// **'Delete avatar/banner older than last'**
  String get strategy_save_last_n;

  /// Localized text for the strategy_save_last_n_suffix message.
  ///
  /// In en, this message translates to:
  /// **'changes'**
  String get strategy_save_last_n_suffix;

  /// Localized text for the theme_mode message.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get theme_mode;

  /// Localized text for the theme message.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Localized text for the follow_system message.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get follow_system;

  /// Localized text for the theme_mode_light message.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get theme_mode_light;

  /// Localized text for the theme_mode_dark message.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get theme_mode_dark;

  /// Localized text for the color_red message.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get color_red;

  /// Localized text for the color_pink message.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get color_pink;

  /// Localized text for the color_purple message.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get color_purple;

  /// Localized text for the color_deepPurple message.
  ///
  /// In en, this message translates to:
  /// **'Deep Purple'**
  String get color_deepPurple;

  /// Localized text for the color_indigo message.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get color_indigo;

  /// Localized text for the color_blue message.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get color_blue;

  /// Localized text for the color_lightBlue message.
  ///
  /// In en, this message translates to:
  /// **'Light Blue'**
  String get color_lightBlue;

  /// Localized text for the color_cyan message.
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get color_cyan;

  /// Localized text for the color_teal message.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get color_teal;

  /// Localized text for the color_green message.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get color_green;

  /// Localized text for the color_lightGreen message.
  ///
  /// In en, this message translates to:
  /// **'Light Green'**
  String get color_lightGreen;

  /// Localized text for the color_lime message.
  ///
  /// In en, this message translates to:
  /// **'Lime'**
  String get color_lime;

  /// Localized text for the color_yellow message.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get color_yellow;

  /// Localized text for the color_amber message.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get color_amber;

  /// Localized text for the color_orange message.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get color_orange;

  /// Localized text for the color_deepOrange message.
  ///
  /// In en, this message translates to:
  /// **'Deep Orange'**
  String get color_deepOrange;

  /// Localized text for the color_brown message.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get color_brown;

  /// Localized text for the color_grey message.
  ///
  /// In en, this message translates to:
  /// **'Grey'**
  String get color_grey;

  /// Localized text for the color_blueGrey message.
  ///
  /// In en, this message translates to:
  /// **'Blue Grey'**
  String get color_blueGrey;

  /// Localized text for the log message.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get log;

  /// Localized text for the view_log message.
  ///
  /// In en, this message translates to:
  /// **'View Logs'**
  String get view_log;

  /// Localized text for the clear message.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Localized text for the api_request_settings message.
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
  /// **'Automated by {automatedScreenName}'**
  String automated_by(String automatedScreenName);

  /// Localized text for the automated message.
  ///
  /// In en, this message translates to:
  /// **'Automated'**
  String get automated;

  /// Localized text for the visit message.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get visit;

  /// Localized text for the save message.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Localized text for the save_error message.
  ///
  /// In en, this message translates to:
  /// **'Error while saving: '**
  String get save_error;

  /// Localized text for the image_saved message.
  ///
  /// In en, this message translates to:
  /// **'Image Saved'**
  String get image_saved;

  /// Localized text for the open_in_browser message.
  ///
  /// In en, this message translates to:
  /// **'Open in Browser'**
  String get open_in_browser;

  /// Localized text for the search message.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Localized text for the clear_search_history message.
  ///
  /// In en, this message translates to:
  /// **'Clear Search History'**
  String get clear_search_history;

  /// Localized text for the filter message.
  ///
  /// In en, this message translates to:
  /// **'Search Settings & Filters'**
  String get filter;

  /// Localized text for the verified_user_only message.
  ///
  /// In en, this message translates to:
  /// **'Verified Users Only'**
  String get verified_user_only;

  /// Localized text for the recent_searches message.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recent_searches;

  /// Localized text for the no_recent_searches message.
  ///
  /// In en, this message translates to:
  /// **'No recent searches'**
  String get no_recent_searches;

  /// Localized text for the enable_restid_searching message.
  ///
  /// In en, this message translates to:
  /// **'Enable Rest Id Searching'**
  String get enable_restid_searching;

  /// Localized text for the enable_restid_searching_subtitle message.
  ///
  /// In en, this message translates to:
  /// **'Search by exact Rest Id match'**
  String get enable_restid_searching_subtitle;

  /// Localized text for the search_fields message.
  ///
  /// In en, this message translates to:
  /// **'Search Fields'**
  String get search_fields;

  /// Localized text for the attributes message.
  ///
  /// In en, this message translates to:
  /// **'Attributes'**
  String get attributes;

  /// Localized text for the apply message.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Localized text for the filters_all message.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filters_all;

  /// Localized text for the filters_no message.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get filters_no;

  /// Localized text for the filters_yes message.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get filters_yes;

  /// Localized text for the account_status message.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get account_status;

  /// Localized text for the protected message.
  ///
  /// In en, this message translates to:
  /// **'Protected'**
  String get protected;

  /// Localized text for the verified message.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// Localized text for the name message.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Localized text for the screen_name message.
  ///
  /// In en, this message translates to:
  /// **'Screen Name'**
  String get screen_name;

  /// Localized text for the bio message.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// Localized text for the link message.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// Localized text for the location message.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Localized text for the avatar message.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatar;

  /// Localized text for the banner message.
  ///
  /// In en, this message translates to:
  /// **'Banner'**
  String get banner;

  /// Localized text for the updated message.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// Localized text for the jump_to_page message.
  ///
  /// In en, this message translates to:
  /// **'Jump to Page'**
  String get jump_to_page;

  /// Localized text for the total message.
  ///
  /// In en, this message translates to:
  /// **'Total: {total}'**
  String total(int total);

  /// Localized text for the changes_since_last_update message.
  ///
  /// In en, this message translates to:
  /// **'Changes since last update'**
  String get changes_since_last_update;

  /// Localized text for the compare message.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compare;

  /// Localized text for the no_visible_changes message.
  ///
  /// In en, this message translates to:
  /// **'No visible changes compared to last record.'**
  String get no_visible_changes;

  /// Localized text for the no_history_found message.
  ///
  /// In en, this message translates to:
  /// **'No History Found'**
  String get no_history_found;

  /// Localized text for the about message.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Localized text for the version message.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Localized text for the author_on_twitter message.
  ///
  /// In en, this message translates to:
  /// **'Author on Twitter'**
  String get author_on_twitter;

  /// Localized text for the source_code message.
  ///
  /// In en, this message translates to:
  /// **'Source Code'**
  String get source_code;

  /// Localized text for the view_on_github message.
  ///
  /// In en, this message translates to:
  /// **'View on GitHub'**
  String get view_on_github;

  /// Localized text for the report_an_issue message.
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get report_an_issue;

  /// Localized text for the feedback_and_suggestions message.
  ///
  /// In en, this message translates to:
  /// **'Feedback and Suggestions'**
  String get feedback_and_suggestions;

  /// Localized text for the license message.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// Localized text for the open_source_licenses message.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get open_source_licenses;

  /// Localized text for the others message.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// Localized text for the no_data message.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get no_data;

  /// Localized text for the no_data_description message.
  ///
  /// In en, this message translates to:
  /// **'No data available for this account. Run your first sync now!'**
  String get no_data_description;

  /// Localized text for the account_suspended message.
  ///
  /// In en, this message translates to:
  /// **'Account Suspended'**
  String get account_suspended;

  /// Localized text for the account_suspended_description message.
  ///
  /// In en, this message translates to:
  /// **'This account has been suspended by Twitter.'**
  String get account_suspended_description;

  /// Localized text for the account_deactivated message.
  ///
  /// In en, this message translates to:
  /// **'Account Deactivated'**
  String get account_deactivated;

  /// Localized text for the account_deactivated_description message.
  ///
  /// In en, this message translates to:
  /// **'This account has been deactivated.'**
  String get account_deactivated_description;

  /// Localized text for the account_temporarily_restricted message.
  ///
  /// In en, this message translates to:
  /// **'Account Temporarily Restricted'**
  String get account_temporarily_restricted;

  /// Localized text for the account_temporarily_restricted_description message.
  ///
  /// In en, this message translates to:
  /// **'This account has been temporarily restricted.'**
  String get account_temporarily_restricted_description;

  /// Localized text for the sync_notification_title message.
  ///
  /// In en, this message translates to:
  /// **'Autonitor Sync'**
  String get sync_notification_title;

  /// Localized text for the sync_notification_text message.
  ///
  /// In en, this message translates to:
  /// **'Syncing data for account @{screenName}'**
  String sync_notification_text(String screenName);

  /// Localized text for the sync_completed_notification_text message.
  ///
  /// In en, this message translates to:
  /// **'Data sync for account @{screenName} completed successfully'**
  String sync_completed_notification_text(String screenName);

  /// Localized text for the sync_failed_notification_text message.
  ///
  /// In en, this message translates to:
  /// **'Data sync for account @{screenName} failed'**
  String sync_failed_notification_text(String screenName);

  /// Localized text for the pause message.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Localized text for the resume message.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// Localized text for the stop message.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// Localized text for the comfirm_stop_sync_title message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to stop the sync?'**
  String get comfirm_stop_sync_title;

  /// Localized text for the comfirm_stop_sync_text message.
  ///
  /// In en, this message translates to:
  /// **'Stopping the sync will cancel all ongoing data fetching operations. No data will be saved for this sync session.'**
  String get comfirm_stop_sync_text;

  /// Localized text for the paused message.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// Localized text for the stopped_by_user message.
  ///
  /// In en, this message translates to:
  /// **'Stopped by User'**
  String get stopped_by_user;

  /// Localized text for the other_reasons message.
  ///
  /// In en, this message translates to:
  /// **'Other Reasons'**
  String get other_reasons;

  /// Localized text for the rollback_to_here message.
  ///
  /// In en, this message translates to:
  /// **'Rollback to here'**
  String get rollback_to_here;

  /// Localized text for the open_in_app message.
  ///
  /// In en, this message translates to:
  /// **'Open in App'**
  String get open_in_app;

  /// Localized text for the browser_via_screen_name message.
  ///
  /// In en, this message translates to:
  /// **'Browser (via Screen Name)'**
  String get browser_via_screen_name;

  /// Localized text for the browser_via_rest_id message.
  ///
  /// In en, this message translates to:
  /// **'Browser (via Rest ID)'**
  String get browser_via_rest_id;

  /// Localized text for the api_request_mode message.
  ///
  /// In en, this message translates to:
  /// **'HTTP Request Implementation'**
  String get api_request_mode;

  /// Localized text for the advanced_mode message.
  ///
  /// In en, this message translates to:
  /// **'Data Fetching Strategy'**
  String get advanced_mode;

  /// Localized text for the advanced_mode_description message.
  ///
  /// In en, this message translates to:
  /// **'Choose how account data is fetched'**
  String get advanced_mode_description;

  /// Localized text for the remote_fastapi_service_url message.
  ///
  /// In en, this message translates to:
  /// **'Remote FastAPI Service URL'**
  String get remote_fastapi_service_url;

  /// Localized text for the fastapi_api_key message.
  ///
  /// In en, this message translates to:
  /// **'FastAPI API Key'**
  String get fastapi_api_key;

  /// Localized text for the fastapi_api_key_optional message.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get fastapi_api_key_optional;

  /// Localized text for the invalid_fastapi_url message.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL starting with http:// or https://'**
  String get invalid_fastapi_url;

  /// Localized text for the enable_new_data_fetching_strategy message.
  ///
  /// In en, this message translates to:
  /// **'Enable new data fetching strategy'**
  String get enable_new_data_fetching_strategy;

  /// Localized text for the backup_and_restore message.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backup_and_restore;

  /// Localized text for the backup message.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// Localized text for the restore message.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// Localized text for the backup_successful message.
  ///
  /// In en, this message translates to:
  /// **'Backup successful'**
  String get backup_successful;

  /// Localized text for the backup_failed message.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backup_failed(String error);

  /// Localized text for the restore_successful message.
  ///
  /// In en, this message translates to:
  /// **'Restore successful'**
  String get restore_successful;

  /// Localized text for the restore_failed message.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restore_failed(String error);

  /// Localized text for the backup_config message.
  ///
  /// In en, this message translates to:
  /// **'Backup Configuration (.json)'**
  String get backup_config;

  /// Localized text for the backup_database message.
  ///
  /// In en, this message translates to:
  /// **'Backup Database (.db)'**
  String get backup_database;

  /// Localized text for the backup_medias message.
  ///
  /// In en, this message translates to:
  /// **'Backup Media Files (.zip)'**
  String get backup_medias;

  /// Localized text for the backup_all message.
  ///
  /// In en, this message translates to:
  /// **'Backup All (.zip)'**
  String get backup_all;

  /// Localized text for the restore_config message.
  ///
  /// In en, this message translates to:
  /// **'Restore Configuration'**
  String get restore_config;

  /// Localized text for the restore_database message.
  ///
  /// In en, this message translates to:
  /// **'Restore Database'**
  String get restore_database;

  /// Localized text for the restore_medias message.
  ///
  /// In en, this message translates to:
  /// **'Restore Media Files'**
  String get restore_medias;

  /// Localized text for the restore_all message.
  ///
  /// In en, this message translates to:
  /// **'Restore All'**
  String get restore_all;

  /// Localized text for the backup_preparing message.
  ///
  /// In en, this message translates to:
  /// **'Preparing backup...'**
  String get backup_preparing;

  /// Localized text for the backup_processing_file message.
  ///
  /// In en, this message translates to:
  /// **'Processing: {fileName}'**
  String backup_processing_file(String fileName);

  /// Localized text for the backup_collecting_files message.
  ///
  /// In en, this message translates to:
  /// **'Collecting files...'**
  String get backup_collecting_files;

  /// Localized text for the backup_progress message.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total}'**
  String backup_progress(int completed, int total);

  /// Localized text for the backup_cancelling message.
  ///
  /// In en, this message translates to:
  /// **'Cancelling backup...'**
  String get backup_cancelling;

  /// Localized text for the backup_cancelled message.
  ///
  /// In en, this message translates to:
  /// **'Backup cancelled'**
  String get backup_cancelled;

  /// Localized text for the restored_account_cookie_required message.
  ///
  /// In en, this message translates to:
  /// **'This restored account needs a Cookie before it can be used.'**
  String get restored_account_cookie_required;

  /// Status shown before restore work starts.
  ///
  /// In en, this message translates to:
  /// **'Preparing restore…'**
  String get restore_preparing;

  /// Status shown while a backup archive entry is extracted.
  ///
  /// In en, this message translates to:
  /// **'Extracting: {fileName}'**
  String restore_extracting_file(String fileName);

  /// Completed and total archive entries during restore.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total}'**
  String restore_progress(int completed, int total);

  /// Status shown while validating the backup database.
  ///
  /// In en, this message translates to:
  /// **'Validating database…'**
  String get restore_validating_database;

  /// Status shown while importing backup database records.
  ///
  /// In en, this message translates to:
  /// **'Importing database…'**
  String get restore_importing_database;

  /// Status shown while replacing stored media files.
  ///
  /// In en, this message translates to:
  /// **'Restoring media files…'**
  String get restore_replacing_media;

  /// Label for the sync progress across all stages.
  ///
  /// In en, this message translates to:
  /// **'Overall progress'**
  String get sync_overall_progress;

  /// Label for progress within the currently active sync stage.
  ///
  /// In en, this message translates to:
  /// **'Current step'**
  String get sync_step_progress;

  /// Title for the expandable diagnostic log panel during sync.
  ///
  /// In en, this message translates to:
  /// **'Show diagnostic logs'**
  String get sync_show_logs;

  /// Shown when the expanded sync log contains no entries.
  ///
  /// In en, this message translates to:
  /// **'No diagnostic logs yet'**
  String get sync_logs_empty;

  /// Name of the sync preparation stage.
  ///
  /// In en, this message translates to:
  /// **'Preparing sync'**
  String get sync_stage_preparing;

  /// Name of the profile refresh sync stage.
  ///
  /// In en, this message translates to:
  /// **'Refreshing profile'**
  String get sync_stage_refreshing_profile;

  /// Name of the service initialization sync stage.
  ///
  /// In en, this message translates to:
  /// **'Initializing services'**
  String get sync_stage_initializing_services;

  /// Name of the existing data loading sync stage.
  ///
  /// In en, this message translates to:
  /// **'Loading existing data'**
  String get sync_stage_loading_existing_data;

  /// Name of the follower network fetch stage.
  ///
  /// In en, this message translates to:
  /// **'Fetching network data'**
  String get sync_stage_fetching_network;

  /// Name of the relationship analysis stage.
  ///
  /// In en, this message translates to:
  /// **'Analyzing changes'**
  String get sync_stage_analyzing_changes;

  /// Name of the media download stage.
  ///
  /// In en, this message translates to:
  /// **'Downloading media'**
  String get sync_stage_downloading_media;

  /// Name of the database save sync stage.
  ///
  /// In en, this message translates to:
  /// **'Saving results'**
  String get sync_stage_saving_results;

  /// Name of the sync finalization stage.
  ///
  /// In en, this message translates to:
  /// **'Finalizing sync'**
  String get sync_stage_finalizing;

  /// Name displayed when sync completed.
  ///
  /// In en, this message translates to:
  /// **'Sync complete'**
  String get sync_stage_completed;

  /// Name displayed when sync failed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get sync_stage_failed;

  /// Name displayed when sync was stopped.
  ///
  /// In en, this message translates to:
  /// **'Sync stopped'**
  String get sync_stage_stopped;

  /// Account count collected so far and the current API page.
  ///
  /// In en, this message translates to:
  /// **'{count} accounts · page {page}'**
  String sync_accounts_processed(int count, int page);

  /// Concrete sync operation.
  ///
  /// In en, this message translates to:
  /// **'Creating sync identifier'**
  String get sync_step_generating_run_id;

  /// Concrete sync operation.
  ///
  /// In en, this message translates to:
  /// **'Updating account profile'**
  String get sync_step_refreshing_owner_profile;

  /// Concrete sync operation.
  ///
  /// In en, this message translates to:
  /// **'Preparing request authentication'**
  String get sync_step_initializing_transaction_id;

  /// Concrete sync operation.
  ///
  /// In en, this message translates to:
  /// **'Loading request definitions'**
  String get sync_step_loading_query_ids;

  /// Concrete sync operation.
  ///
  /// In en, this message translates to:
  /// **'Reading saved relationships'**
  String get sync_step_loading_existing_relations;

  /// Concrete sync operation.
  ///
  /// In en, this message translates to:
  /// **'Fetching followers'**
  String get sync_step_fetching_followers;

  /// Concrete sync operation.
  ///
  /// In en, this message translates to:
  /// **'Fetching following'**
  String get sync_step_fetching_following;

  /// Concrete sync operation.
  ///
  /// In en, this message translates to:
  /// **'Loading profile details'**
  String get sync_step_enriching_profiles;

  /// Concrete sync operation.
  ///
  /// In en, this message translates to:
  /// **'Checking removed relationships'**
  String get sync_step_checking_removed_relations;

  /// Concrete sync operation.
  ///
  /// In en, this message translates to:
  /// **'Comparing saved profiles'**
  String get sync_step_comparing_profiles;

  /// Concrete sync operation.
  ///
  /// In en, this message translates to:
  /// **'Checking saved media'**
  String get sync_step_checking_media;

  /// Concrete sync operation.
  ///
  /// In en, this message translates to:
  /// **'Downloading media files'**
  String get sync_step_downloading_media;

  /// Concrete sync operation.
  ///
  /// In en, this message translates to:
  /// **'Preparing database changes'**
  String get sync_step_preparing_database_changes;

  /// Concrete sync operation.
  ///
  /// In en, this message translates to:
  /// **'Writing database changes'**
  String get sync_step_writing_database_changes;

  /// Concrete sync operation.
  ///
  /// In en, this message translates to:
  /// **'Recording sync result'**
  String get sync_step_recording_sync_log;

  /// Shown while a GraphQL request waits for the API rate-limit reset.
  ///
  /// In en, this message translates to:
  /// **'Rate limited. Retrying at {time} ({remaining} remaining).'**
  String sync_rate_limit_waiting(String time, String remaining);

  /// Shown when the reset time has passed while sync remains paused.
  ///
  /// In en, this message translates to:
  /// **'Rate limit reset. Resume sync when ready.'**
  String get sync_rate_limit_ready;

  /// No description provided for @sync_mode_title.
  ///
  /// In en, this message translates to:
  /// **'Sync mode'**
  String get sync_mode_title;

  /// No description provided for @sync_mode_fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get sync_mode_fast;

  /// No description provided for @sync_mode_fast_description.
  ///
  /// In en, this message translates to:
  /// **'Followers via V1; following via GraphQL.'**
  String get sync_mode_fast_description;

  /// No description provided for @sync_mode_expert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get sync_mode_expert;

  /// No description provided for @sync_mode_expert_description.
  ///
  /// In en, this message translates to:
  /// **'Both lists via V1, then load complete profiles.'**
  String get sync_mode_expert_description;

  /// No description provided for @sync_mode_fastest.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get sync_mode_fastest;

  /// No description provided for @sync_mode_fastest_description.
  ///
  /// In en, this message translates to:
  /// **'Both lists via V1 without profile enrichment.'**
  String get sync_mode_fastest_description;

  /// No description provided for @sync_mode_requires_curl_cffi.
  ///
  /// In en, this message translates to:
  /// **'Requires curl_cffi in API request settings.'**
  String get sync_mode_requires_curl_cffi;

  /// No description provided for @chart_chronological.
  ///
  /// In en, this message translates to:
  /// **'Oldest to latest'**
  String get chart_chronological;

  /// No description provided for @chart_time_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get chart_time_all;

  /// No description provided for @chart_time_7d.
  ///
  /// In en, this message translates to:
  /// **'7D'**
  String get chart_time_7d;

  /// No description provided for @chart_time_30d.
  ///
  /// In en, this message translates to:
  /// **'30D'**
  String get chart_time_30d;

  /// No description provided for @chart_time_90d.
  ///
  /// In en, this message translates to:
  /// **'90D'**
  String get chart_time_90d;

  /// No description provided for @chart_time_1y.
  ///
  /// In en, this message translates to:
  /// **'1Y'**
  String get chart_time_1y;

  /// No description provided for @chart_start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get chart_start;

  /// No description provided for @chart_latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get chart_latest;

  /// No description provided for @chart_change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get chart_change;

  /// No description provided for @chart_data_points.
  ///
  /// In en, this message translates to:
  /// **'{count} observations'**
  String chart_data_points(int count);
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

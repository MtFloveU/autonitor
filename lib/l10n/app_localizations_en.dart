// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get app_title => 'Autonitor';

  @override
  String get settings => 'Settings';

  @override
  String get home => 'Home';

  @override
  String get data => 'Data';

  @override
  String get accounts => 'Accounts';

  @override
  String get switchAccount => 'Switch Account';

  @override
  String get followers => 'Followers';

  @override
  String get following => 'Following';

  @override
  String get new_account => 'Add/Update an account';

  @override
  String get view_cookie => 'View Cookie';

  @override
  String get close => 'Close';

  @override
  String get view_on_twitter => 'View on Twitter';

  @override
  String get metadata => 'Statistics';

  @override
  String get user_content => 'User Content';

  @override
  String get pinned_tweet_id => 'Pinned Tweet ID';

  @override
  String get tweets => 'Tweets';

  @override
  String get media_count => 'Media Count';

  @override
  String get likes => 'Likes';

  @override
  String get listed_count => 'Listed Count';

  @override
  String get identity => 'Identity-related';

  @override
  String get back => 'Back';

  @override
  String get history => 'History';

  @override
  String get suspended => 'Suspended';

  @override
  String get deactivated => 'Deactivated';

  @override
  String get normal_unfollowed => 'Normal Unfollowed';

  @override
  String get be_followed_back => 'Be Followed Back';

  @override
  String get mutual_unfollowed => 'Mutual Unfollowed';

  @override
  String get oneway_unfollowed => 'One-way Unfollowed';

  @override
  String get new_followers_following => 'New Followers & Following';

  @override
  String get empty_list_message => 'The list is empty';

  @override
  String get switch_account => 'Switch Account';

  @override
  String get run => 'Run';

  @override
  String get choose_login_method => 'Choose Login Method';

  @override
  String get browser_login => 'Login via Browser';

  @override
  String get manual_cookie => 'Manual Cookie Input';

  @override
  String joined(String date) {
    return 'Joined $date';
  }

  @override
  String get im_logged_in => 'I\'ve logged in';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get account_added_successfully => 'Account added successfully!';

  @override
  String get saving_account => 'Saving account...';

  @override
  String get cookie => 'Cookie';

  @override
  String get no_cookie_found => 'No cookie found';

  @override
  String get no_auth_token_found => 'No auth_token found';

  @override
  String get found_auth_token_last_check => 'Auth Token found in last check';

  @override
  String get general => 'General';

  @override
  String get login_first => 'Log in Needed';

  @override
  String get login_first_description => 'Add at least one account to continue';

  @override
  String get log_in => 'Log In';

  @override
  String get delete => 'Delete';

  @override
  String confirm_delete_account(Object accountId) {
    return 'Are you sure you want to delete account $accountId? This action cannot be undone. Deleting an account will permanently remove all its associated data (history, follower/following lists etc.). If you only want to update the cookie, simply add the account again.';
  }

  @override
  String get copy => 'Copy';

  @override
  String get copied_to_clipboard => 'Copied to clipboard!';

  @override
  String get no_json_data_available => 'No JSON data available';

  @override
  String get temporarily_restricted => 'Temporarily Restricted';

  @override
  String get recovered => 'Recovered';

  @override
  String get failed_to_load_user_list => 'Failed to load user list';

  @override
  String get no_users_in_this_category => 'Empty list';

  @override
  String get analysis_log => 'Analysis Log';

  @override
  String get no_active_account_error =>
      'Cannot run analysis: No account is active.';

  @override
  String get analysis_failed_error => 'Analysis failed';

  @override
  String get no_analysis_data => 'No analysis data found';

  @override
  String get run_analysis_now => 'Run Analysis Now';

  @override
  String last_updated_at(String date) {
    return 'Last updated: $date';
  }

  @override
  String get user_history_page_title => 'Profile History';

  @override
  String get storage_settings => 'Storage Settings';

  @override
  String get save_avatar_history => 'Save Avatar';

  @override
  String get save_banner_history => 'Save Banner';

  @override
  String get avatar_quality => 'Quality';

  @override
  String get quality_low => 'Low';

  @override
  String get quality_high => 'High';

  @override
  String get history_strategy => 'History Avatar/Banner Storage Strategy';

  @override
  String get strategy_save_all => 'Never Delete';

  @override
  String get strategy_save_latest => 'Keep Latest Only';

  @override
  String get strategy_save_last_n => 'Delete avatar/banner older than last';

  @override
  String get strategy_save_last_n_suffix => 'changes';

  @override
  String get theme_mode => 'Theme';

  @override
  String get theme_mode_system => 'Follow System';

  @override
  String get theme_mode_light => 'Light';

  @override
  String get theme_mode_dark => 'Dark';

  @override
  String get log => 'Log';

  @override
  String get view_log => 'View Logs';

  @override
  String get clear => 'Clear';

  @override
  String get api_request_settings => 'API Request Settings';

  @override
  String get xclient_generator_title => 'XClientTransactionID Generator';

  @override
  String get num_ids_to_generate => 'Number of IDs to be generated:';

  @override
  String get please_enter_valid_number => 'Please enter a valid number (1-100)';

  @override
  String get path_must_start_with_slash => 'Path must start with /';

  @override
  String get fetching_resources => 'Fetching resources';

  @override
  String generating_ids_local(int count) {
    return 'Generating $count IDs (local)...';
  }

  @override
  String get generation_canceled => 'Generation canceled.';

  @override
  String id_generation_failed(String error) {
    return 'ID Generation Failed: $error';
  }

  @override
  String get generating => 'Generating...';

  @override
  String get generate => 'Generate';

  @override
  String load_settings_failed(String error) {
    return 'Failed to load settings: $error';
  }

  @override
  String get xclient_generator_source => 'Source:';

  @override
  String get refresh => 'Refresh';

  @override
  String get reset => 'Reset';

  @override
  String get operation_name => 'Operation:';

  @override
  String get graphql_path_config => 'GQL QueryId Configuration';

  @override
  String get follows_you => 'Follows you';

  @override
  String get not_follow => 'Not Follow';

  @override
  String automated_by(String automatedScreenName) {
    return 'Automated by @$automatedScreenName';
  }

  @override
  String get automated => 'Automated';

  @override
  String get visit => 'Visit';

  @override
  String get save => 'Save';

  @override
  String get save_error => 'Error while saving: ';

  @override
  String get image_saved => 'Image Saved';

  @override
  String get open_in_browser => 'Open in Browser';
}

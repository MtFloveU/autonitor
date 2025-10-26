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
  String get new_account => 'Add a new account';

  @override
  String get view_cookie => 'View Cookie';

  @override
  String get close => 'Close';

  @override
  String get view_on_twitter => 'View on Twitter';

  @override
  String get metadata => 'Metadata';

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
  String get joined => 'Joined';

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
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get language => '语言';

  @override
  String get app_title => 'Autonitor';

  @override
  String get settings => '设置';

  @override
  String get home => '首页';

  @override
  String get data => '数据';

  @override
  String get accounts => '账号';

  @override
  String get switchAccount => '切换账号';

  @override
  String get followers => '关注者';

  @override
  String get following => '正在关注';

  @override
  String get new_account => '添加新账号';

  @override
  String get view_cookie => '查看 Cookie';

  @override
  String get close => '关闭';

  @override
  String get view_on_twitter => '在 Twitter 上查看';

  @override
  String get metadata => '元数据';

  @override
  String get tweets => '推文';

  @override
  String get media_count => '媒体数量';

  @override
  String get likes => '点赞数量';

  @override
  String get listed_count => '被收录列表';

  @override
  String get identity => '身份相关';

  @override
  String get back => '返回';

  @override
  String get history => '历史';

  @override
  String get suspended => '被冻结';

  @override
  String get deactivated => '注销';

  @override
  String get normal_unfollowed => '普通取关';

  @override
  String get be_followed_back => '被回关';

  @override
  String get mutual_unfollowed => '互关双取';

  @override
  String get oneway_unfollowed => '互关单取';

  @override
  String get new_followers_following => '新增关注';

  @override
  String get empty_list_message => '列表为空';

  @override
  String get switch_account => '切换账号';

  @override
  String get run => '运行';

  @override
  String get choose_login_method => '选择登录方式';

  @override
  String get browser_login => '浏览器登录';

  @override
  String get manual_cookie => '输入Cookie';

  @override
  String get joined => '加入于';

  @override
  String get im_logged_in => '我已登录';

  @override
  String get cancel => '取消';

  @override
  String get ok => '确定';

  @override
  String get account_added_successfully => '账号添加成功！';

  @override
  String get saving_account => '正在保存账号...';

  @override
  String get cookie => 'Cookie';

  @override
  String get no_cookie_found => '未能找到 cookie';

  @override
  String get no_auth_token_found => '未能找到 auth_token';

  @override
  String get found_auth_token_last_check => '在上次检查中找到了 Auth Token';

  @override
  String get general => '通用';

  @override
  String get login_first => '需要登录';

  @override
  String get login_first_description => '请至少添加一个账号以继续';

  @override
  String get log_in => '登录';

  @override
  String get delete => '删除';

  @override
  String confirm_delete_account(Object accountId) {
    return '您确定要删除账号 $accountId 吗？此操作无法撤销。删除账号将永久移除其所有关联数据（历史记录、关注者/关注列表等）。如果您只想更新 Cookie，请直接重新添加该账号。';
  }

  @override
  String get copy => '复制';

  @override
  String get copied_to_clipboard => '已复制到剪贴板！';

  @override
  String get no_json_data_available => '无 JSON 数据';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get language => '語言';

  @override
  String get app_title => 'Autonitor';

  @override
  String get settings => '設定';

  @override
  String get home => '首頁';

  @override
  String get data => '數據';

  @override
  String get accounts => '賬戶';

  @override
  String get switchAccount => '切換賬戶';

  @override
  String get followers => '跟隨者';

  @override
  String get following => '跟隨中';

  @override
  String get new_account => '添加新賬戶';

  @override
  String get view_cookie => '查看 Cookie';

  @override
  String get close => '關閉';

  @override
  String get view_on_twitter => '在 Twitter 上查看';

  @override
  String get metadata => '元數據';

  @override
  String get tweets => '推文';

  @override
  String get media_count => '媒體數量';

  @override
  String get likes => '讚數';

  @override
  String get listed_count => '被收錄列表';

  @override
  String get identity => '身份相關';

  @override
  String get back => '返回';

  @override
  String get history => '歷史';

  @override
  String get suspended => '遭停權';

  @override
  String get deactivated => '註銷';

  @override
  String get normal_unfollowed => '普通取跟';

  @override
  String get be_followed_back => '被回跟';

  @override
  String get mutual_unfollowed => '互跟雙取';

  @override
  String get oneway_unfollowed => '互跟單取';

  @override
  String get new_followers_following => '新增跟隨';

  @override
  String get empty_list_message => '空列表';

  @override
  String get switch_account => '切換賬戶';

  @override
  String get run => '運行';

  @override
  String get choose_login_method => '選擇登入方式';

  @override
  String get browser_login => '透過瀏覽器登入';

  @override
  String get manual_cookie => '鍵入Cookie';

  @override
  String get joined => '加入於';

  @override
  String get im_logged_in => '我已登入';

  @override
  String get cancel => '取消';

  @override
  String get ok => '確定';

  @override
  String get account_added_successfully => '賬戶添加成功！';

  @override
  String get saving_account => '正在保存賬戶...';

  @override
  String get cookie => 'Cookie';

  @override
  String get no_cookie_found => '未能找到 cookie';

  @override
  String get no_auth_token_found => '未能找到 auth_token';

  @override
  String get found_auth_token_last_check => '在上次檢查中找到了 Auth Token';

  @override
  String get general => '通用';

  @override
  String get login_first => '需要登入';

  @override
  String get login_first_description => '請至少添加一個帳戶以繼續';

  @override
  String get log_in => '登入';

  @override
  String get delete => '刪除';

  @override
  String confirm_delete_account(Object accountId) {
    return '您確定要刪除賬戶 $accountId 嗎？此操作無法撤銷。刪除賬戶將永久移除其所有關聯數據（歷史紀錄、跟隨者/跟隨列表等）。如果您只想更新 Cookie，請直接重新添加該賬戶。';
  }

  @override
  String get copy => '拷貝';

  @override
  String get copied_to_clipboard => '已拷貝到剪貼簿！';

  @override
  String get no_json_data_available => '無 JSON 數據';
}

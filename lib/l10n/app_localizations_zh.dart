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
  String get new_account => '添加/更新账号';

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

  @override
  String get temporarily_restricted => '暂时受限';

  @override
  String get failed_to_load_user_list => '加载用户列表失败';

  @override
  String get no_users_in_this_category => '列表为空';

  @override
  String get analysis_log => '分析日志';

  @override
  String get no_active_account_error => '无法运行分析：没有活动的账号。';

  @override
  String get analysis_failed_error => '分析失败';

  @override
  String get no_analysis_data => '尚未生成分析数据';

  @override
  String get run_analysis_now => '立即运行分析';

  @override
  String last_updated_at(String date) {
    return '上次更新：$date';
  }

  @override
  String get user_history_page_title => '个人资料历史';

  @override
  String get storage_settings => '存储设置';

  @override
  String get save_avatar_history => '保存头像';

  @override
  String get save_banner_history => '保存横幅';

  @override
  String get avatar_quality => '质量';

  @override
  String get quality_low => '低';

  @override
  String get quality_high => '高';

  @override
  String get history_strategy => '历史头像/横幅存储策略';

  @override
  String get strategy_save_all => '从不删除';

  @override
  String get strategy_save_latest => '仅保留最新';

  @override
  String get strategy_save_last_n => '删除早于最近';

  @override
  String get strategy_save_last_n_suffix => '次更改的头像/横幅';

  @override
  String get theme_mode => '主题';

  @override
  String get theme_mode_system => '跟随系统';

  @override
  String get theme_mode_light => '浅色';

  @override
  String get theme_mode_dark => '深色';

  @override
  String get log => '日志';

  @override
  String get view_log => '查看日志';

  @override
  String get clear => '清除';

  @override
  String get api_request_settings => 'API 请求设置';

  @override
  String get xclient_generator_title => 'XClientTransactionID 生成器';

  @override
  String get num_ids_to_generate => '要生成的 ID 数量：';

  @override
  String get please_enter_valid_number => '请输入有效的数字（1-100）';

  @override
  String get path_must_start_with_slash => '路径必须以 / 开头';

  @override
  String get fetching_resources => '正在获取资源';

  @override
  String generating_ids_local(int count) {
    return '正在本地生成 $count 个 ID...';
  }

  @override
  String get generation_canceled => '生成已取消。';

  @override
  String id_generation_failed(String error) {
    return 'ID 生成失败：$error';
  }

  @override
  String get generating => '正在生成...';

  @override
  String get generate => '生成';

  @override
  String load_settings_failed(String error) {
    return '加载设置失败：$error';
  }

  @override
  String get xclient_generator_source => '来源：';

  @override
  String get refresh => '刷新';

  @override
  String get reset => '重置';

  @override
  String get operation_name => '操作：';

  @override
  String get graphql_path_config => 'GQL QueryId 配置';
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
  String get new_account => '添加/更新賬戶';

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

  @override
  String get temporarily_restricted => '暫時受限';

  @override
  String get failed_to_load_user_list => '載入用戶列表失敗';

  @override
  String get no_users_in_this_category => '空列表';

  @override
  String get analysis_log => '分析日誌';

  @override
  String get no_active_account_error => '無法運行分析：沒有活動的賬戶。';

  @override
  String get analysis_failed_error => '分析失敗';

  @override
  String get no_analysis_data => '尚未生成分析數據';

  @override
  String get run_analysis_now => '立即運行分析';

  @override
  String last_updated_at(String date) {
    return '上次更新：$date';
  }

  @override
  String get user_history_page_title => '個人資料歷史';

  @override
  String get storage_settings => '儲存設定';

  @override
  String get save_avatar_history => '儲存頭像';

  @override
  String get save_banner_history => '儲存橫幅';

  @override
  String get avatar_quality => '品質';

  @override
  String get quality_low => '低';

  @override
  String get quality_high => '高';

  @override
  String get history_strategy => '歷史頭像/橫幅儲存策略';

  @override
  String get strategy_save_all => '從不刪除';

  @override
  String get strategy_save_latest => '僅保留最新';

  @override
  String get strategy_save_last_n => '刪除早於最近';

  @override
  String get strategy_save_last_n_suffix => '次更改的頭像/橫幅';

  @override
  String get theme_mode => '主題';

  @override
  String get theme_mode_system => '跟隨系統';

  @override
  String get theme_mode_light => '淺色';

  @override
  String get theme_mode_dark => '深色';

  @override
  String get log => '日誌';

  @override
  String get view_log => '查看日誌';

  @override
  String get clear => '清除';

  @override
  String get api_request_settings => 'API 請求設定';

  @override
  String get xclient_generator_title => 'XClientTransactionID 產生器';

  @override
  String get num_ids_to_generate => '要產生的 ID 數量：';

  @override
  String get please_enter_valid_number => '請輸入有效的數字（1-100）';

  @override
  String get path_must_start_with_slash => '路徑必須以 / 開頭';

  @override
  String get fetching_resources => '正在取得資源';

  @override
  String generating_ids_local(int count) {
    return '正在本地產生 $count 個 ID...';
  }

  @override
  String get generation_canceled => '產生已取消。';

  @override
  String id_generation_failed(String error) {
    return 'ID 產生失敗：$error';
  }

  @override
  String get generating => '正在產生...';

  @override
  String get generate => '產生';

  @override
  String load_settings_failed(String error) {
    return '載入設定失敗：$error';
  }

  @override
  String get xclient_generator_source => '來源：';

  @override
  String get refresh => '刷新';

  @override
  String get reset => '重設';

  @override
  String get operation_name => '操作：';

  @override
  String get graphql_path_config => 'GQL QueryId 配置';
}

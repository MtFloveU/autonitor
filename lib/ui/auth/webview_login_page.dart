import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../l10n/app_localizations.dart';

class WebViewLoginPage extends StatefulWidget {
  const WebViewLoginPage({super.key});

  @override
  State<WebViewLoginPage> createState() => _WebViewLoginPageState();
}

class _WebViewLoginPageState extends State<WebViewLoginPage> {
  final Uri _url = Uri.parse('https://x.com/login');
  final CookieManager _cookieManager = CookieManager.instance();

  bool _hasFoundAuthTokenInLastCheck = false;

  Future<void> _onLoginComplete() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );

    try {
      final WebUri targetUrl = WebUri("https://x.com");

      List<Cookie> gotCookies; // 将 gotCookies 提到 try 块之前

      try {
        // 尝试获取 cookie
        gotCookies = await _cookieManager.getCookies(url: targetUrl);
      } catch (e, s) {
        // --- 修改点 1：捕获所有 Error 和 Exception ---
        // [已修改] 捕获 *所有* 异常和错误 (StateError, PlatformException, Error, etc.)
        // 只要 getCookies 失败，就视为空列表，让后续逻辑处理 "No cookie found" 提示。
        debugPrint("Error during getCookies, treating as empty list: $e\n$s");
        gotCookies = []; // 手动设置为空列表
      }

      // 先关闭加载圈
      if (!mounted) return;
      // 这一行现在是安全的，因为内部的catch会捕获所有错误
      Navigator.pop(context);

      // 检查 cookie 是否存在 (现在的 gotCookies 可能是 [] 了)
      if (gotCookies.isEmpty) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.no_cookie_found)));
        return;
      }

      // 是否有 auth_token
      final bool hasAuthToken = gotCookies.any((c) => c.name == 'auth_token');
      _hasFoundAuthTokenInLastCheck = hasAuthToken;

      if (!hasAuthToken) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.no_auth_token_found)));
        return;
      }

      // 构造 cookie 字符串
      final String finalCookieString = gotCookies
          .map((c) => '${c.name}=${c.value}')
          .join('; ');

      // 弹出确认框
      final l10n = AppLocalizations.of(context)!;
      final bool? isConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(l10n.cookie),
            content: SingleChildScrollView(
              child: SelectableText(
                finalCookieString,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                child: Text(l10n.cancel),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                child: Text(l10n.ok),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          );
        },
      );

      if (isConfirmed == true && mounted) {
        Navigator.pop(context, finalCookieString);
      }
    } catch (e, s) {
      // --- 修改点 2：捕获所有 Error 和 Exception ---
      debugPrint("Unhandled error in _onLoginComplete: $e\n$s");
      if (mounted) Navigator.pop(context); // 关闭加载圈
      if (mounted) {
        // 其他未预料到的错误仍会在这里显示
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.browser_login),
        actions: [
          if (_hasFoundAuthTokenInLastCheck)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Tooltip(
                message: l10n.found_auth_token_last_check,
                child: const Icon(Icons.check_circle, color: Colors.green),
              ),
            ),
          TextButton(
            onPressed: _onLoginComplete,
            child: Text(l10n.im_logged_in),
          ),
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri.uri(_url)),
        initialSettings: InAppWebViewSettings(
          clearSessionCache: true,
          clearCache: true,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// [已更新]
// 核心改动：
// 1. 移除了未使用的 `_webViewController` 字段。
// 2. 为所有在 `await` 之后使用 `context` 的地方添加了 `if (context.mounted)` 安全检查。
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
      builder: (context) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );

    String finalCookieString = '';
    
    try {
      final WebUri targetUrl = WebUri("https://x.com");
      final List<Cookie> gotCookies = await _cookieManager.getCookies(url: targetUrl);
      
      _hasFoundAuthTokenInLastCheck = gotCookies.any((c) => c.name == 'auth_token');

      // [已修复] 在 await 之后使用 context 之前进行 mounted 检查
      if (!context.mounted) return; 
      Navigator.pop(context); // 关闭加载圈

      if (gotCookies.isEmpty || !_hasFoundAuthTokenInLastCheck) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("未能找到 auth_token。请确认您已完全登录。")),
        );
        return;
      }

      finalCookieString = gotCookies.map((c) => '${c.name}=${c.value}').join('; ');
      
      final bool? isConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("确认Cookie"),
            content: SingleChildScrollView(
              child: SelectableText(finalCookieString, style: const TextStyle(fontSize: 12)),
            ),
            actions: [
              TextButton(child: const Text("取消"), onPressed: () => Navigator.pop(context, false)),
              ElevatedButton(child: const Text("确认"), onPressed: () => Navigator.pop(context, true)),
            ],
          );
        },
      );

      if (isConfirmed == true) {
        if (mounted) {
          Navigator.pop(context, finalCookieString);
        }
      }

    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("获取Cookie时发生错误: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("浏览器登录"),
        actions: [
          if (_hasFoundAuthTokenInLastCheck)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Tooltip(
                message: "在上次检查中找到了Auth Token",
                child: Icon(Icons.check_circle, color: Colors.green),
              ),
            ),
          TextButton(
            onPressed: _onLoginComplete,
            child: const Text("我已登录"),
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


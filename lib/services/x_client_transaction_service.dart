// lib/x_client_transaction_service.dart
import 'dart:convert';
import 'dart:math';
// ignore: depend_on_referenced_packages
import 'package:crypto/crypto.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom show Element;
import 'package:dio/dio.dart';
import 'package:autonitor/services/log_service.dart';

/// XClientTransactionService / XClientGenerator
/// 基于最新 Python 版本重写并修正的完整 Dart 实现。
/// 使用 XClientGenerator().fetchAndGenerateTransactionId(method: "GET", url: "https://x.com/....")
/// 来获取有效的 x-client-transaction-id 字符串。
///
/// 注意：网络请求使用 Dio，并依赖正常的网络连通性。
class XClientTransactionService {
  // 数值插值
  List<double> interpolate(List<num> fromList, List<num> toList, double f) {
    if (fromList.length != toList.length) {
      throw Exception("插值参数长度不匹配");
    }
    final List<double> out = [];
    for (int i = 0; i < fromList.length; i++) {
      out.add(interpolateNum(fromList[i], toList[i], f));
    }
    return out;
  }

  double interpolateNum(num fromVal, num toVal, double f) {
    return fromVal * (1 - f) + toVal * f;
  }

  List<double> convertRotationToMatrix(double degrees) {
    final double radians = degrees * pi / 180.0;
    final double cosVal = cos(radians);
    final double sinVal = sin(radians);
    // 匹配 Python 中返回的 4 元素列表：[cos, -sin, sin, cos]
    return [cosVal, -sinVal, sinVal, cosVal];
  }

  final String homePageHtml;    // 完整的主页 HTML 文本
  final String ondemandJsText;  // ondemand.s.*.js 文本
  final String randomKeyword;
  final int randomNumber;       // 附加的随机数 (类似于 Python 中的 ADDITIONAL_RANDOM_NUMBER)

  late final int rowIndexIndex;       // 从 ondemand 中提取的首个索引
  late final List<int> keyBytesIndices; // 用于计算 frameTimeProduct 的剩余索引
  late final List<int> keyBytes;      // Base64 解码后的 key bytes (来自 meta)
  late final String animationKey;     // 计算得出的动画 key

  static const int _epochOffsetSeconds = 1682924400;
  // 匹配 indices 规则
  static const String _indicesPattern = r"""(\(\w{1}\[(\d{1,2})\],\s*16\))+""";

  XClientTransactionService({
    required this.homePageHtml,
    required this.ondemandJsText,
    String? randomKeyword,
    int? randomNumber,
  }) : randomKeyword = randomKeyword ?? "obfiowerehiring", // 最新默认关键字
       randomNumber = randomNumber ?? 3 {
    final Map<String, dynamic> indices = _getIndices(ondemandJsText);
    rowIndexIndex = indices['rowIndex'] as int;
    keyBytesIndices = List<int>.from(indices['keyBytesIndices'] as List<int>);

    final String metaKey = _getKey(homePageHtml);
    keyBytes = _getKeyBytes(metaKey);
    animationKey = _getAnimationKey(keyBytes, homePageHtml);
  }

  // ----------------- 辅助方法: 从 ondemand 提取索引 -----------------
  Map<String, dynamic> _getIndices(String ondemandText) {
    final RegExp rx = RegExp(_indicesPattern, multiLine: true);
    final Iterable<RegExpMatch> matches = rx.allMatches(ondemandText);
    final List<int> idxs = [];

    for (final m in matches) {
      // 第二个捕获组包含实际数字
      if (m.groupCount >= 2) {
        final g = m.group(2);
        if (g != null) {
          try {
            idxs.add(int.parse(g));
          } catch (_) {}
        }
      }
    }

    if (idxs.isEmpty) {
      throw Exception("无法从 ondemand JS 中获取 KEY_BYTE indices");
    }

    return {
      // 第一项为 rowIndexIndex (用来检索 keyBytes)
      'rowIndex': idxs.first,
      // 剩余的用来计算 frameTimeProduct
      'keyBytesIndices': idxs.length > 1 ? idxs.sublist(1) : <int>[],
    };
  }

  // ----------------- 辅助方法: 提取 Meta Key -----------------
  String _getKey(String htmlText) {
    final doc = html_parser.parse(htmlText);
    final html_dom.Element? meta = doc.querySelector(
      "meta[name='twitter-site-verification']",
    );
    final String? content = meta?.attributes['content'];
    if (content == null || content.isEmpty) {
      throw Exception(
        "无法从页面 HTML 中获取 twitter-site-verification meta content",
      );
    }
    return content;
  }

  List<int> _getKeyBytes(String keyBase64) {
    try {
      final bytes = base64.decode(keyBase64);
      return bytes;
    } catch (e) {
      // 降级: 当作 utf8 字节处理
      return utf8.encode(keyBase64);
    }
  }

  // ----------------- 辅助方法: 提取 SVG 帧矩阵 -----------------
  List<html_dom.Element> _getFrames(String htmlText) {
    final doc = html_parser.parse(htmlText);
    final List<html_dom.Element> frames = [];
    for (int i = 0; i < 4; i++) {
      final el = doc.querySelector("#loading-x-anim-$i");
      if (el != null) frames.add(el);
    }
    return frames;
  }

  /// 将 SVG path 'd' 的值解析为二维整数数组
  /// 保留负数和小数点（我们会四舍五入到最近的整数）。
  List<List<int>> _get2dArray(List<int> keyBytes, String homePageResponse) {
    final frames = _getFrames(homePageResponse);
    if (frames.isEmpty) {
      throw Exception("无法在 HTML 中找到动画帧元素");
    }

    final frameIndex = keyBytes[5] % frames.length; // 安全索引
    final html_dom.Element frame = frames[frameIndex];

    html_dom.Element? pathElement;

    if (frame.children.isNotEmpty) {
      final html_dom.Element gElement = frame.children[0];
      final List<html_dom.Element> childrenOfG = gElement.children;

      if (childrenOfG.length > 1) {
        pathElement = childrenOfG[1];
      } else if (childrenOfG.isNotEmpty) {
        pathElement = childrenOfG[0];
      }

      if (pathElement == null || pathElement.localName != 'path') {
        pathElement = gElement.querySelector('path');
      }
    }

    final String? dAttribute = pathElement?.attributes['d'];
    if (dAttribute == null || dAttribute.length < 9) {
      throw Exception("无法从 SVG path 提取 'd' 属性。当前属性: $dAttribute");
    }

    final List<String> cSegments = dAttribute.substring(9).split("C");

    final List<List<int>> result = [];
    final RegExp nonDigitRegex = RegExp(r"[^\d]+");

    for (final item in cSegments) {
      final String cleanedItem = item.replaceAll(nonDigitRegex, " ").trim();
      if (cleanedItem.isNotEmpty) {
        final List<int> numbers = cleanedItem
            .split(RegExp(r'\s+'))
            .where((s) => s.isNotEmpty)
            .map((s) => int.tryParse(s) ?? 0)
            .toList();
        result.add(numbers);
      }
    }

    // 如果只找到少于 4 行，复制几份，防止 rowIndex 越界
    while (result.length < 4) {
      result.add(result[0]);
    }

    return result;
  }

  // ----------------- 浮点数处理 -----------------
  static double _customRoundDouble(double x) {
    // 模拟之前 Python 使用的舍入机制
    final int floorX = x.floor();
    return ((x - floorX).abs() >= 0.5) ? floorX + 1.0 : floorX.toDouble();
  }

  static double _isOddVal(int n) {
    return n % 2 != 0 ? -1.0 : 0.0;
  }

  /// 模拟 Python 中浮点数转 Hex：将正双精度转为 hex integer.fraction 形式
  String _floatToHex(double x) {
    if (x == 0.0) return '0';
    x = x.abs();
    final int integer = x.floor();
    double frac = x - integer;
    final List<String> parts = [];
    
    // 处理整数部分
    if (integer == 0) {
      parts.add('0');
    } else {
      int tmp = integer;
      final List<String> intHex = [];
      while (tmp > 0) {
        final int r = tmp % 16;
        if (r >= 10) {
          intHex.insert(0, String.fromCharCode(r + 55)); // A..F
        } else {
          intHex.insert(0, r.toString());
        }
        tmp ~/= 16;
      }
      parts.addAll(intHex);
    }
    
    // 处理小数部分
    if (frac > 0) {
      parts.add('.');
      int count = 0;
      while (frac > 0 && count < 16) {
        frac *= 16;
        final int digit = frac.floor();
        frac -= digit;
        if (digit >= 10) {
          parts.add(String.fromCharCode(digit + 55));
        } else {
          parts.add(digit.toString());
        }
        count++;
      }
    }
    return parts.join();
  }

  // ----------------- 动画生成及 Cubic 曲线计算 -----------------
  String _animate(List<int> frames, double targetTime) {
    // frames 预期格式: [r0, g0, b0, r1, g1, b1, rotateByte, curveBytes...]
    if (frames.length < 7) {
      throw Exception("帧行必须包含至少 7 个值");
    }
    final List<double> fromColor = [
      frames[0].toDouble(),
      frames[1].toDouble(),
      frames[2].toDouble(),
      1.0, // alpha
    ];
    final List<double> toColor = [
      frames[3].toDouble(),
      frames[4].toDouble(),
      frames[5].toDouble(),
      1.0, // alpha
    ];
    final double toRotationDeg = _solve(
      frames[6].toDouble(),
      60.0,
      360.0,
      true,
    );

    final List<int> cubicFrames = frames.sublist(7);
    final List<double> curves = [];
    for (int i = 0; i < cubicFrames.length; i++) {
      final double val = _solve(
        cubicFrames[i].toDouble(),
        _isOddVal(i),
        1.0,
        false,
      );
      curves.add(val);
    }

    final Cubic cubic = Cubic(curves);
    final double v = cubic.getValue(targetTime);

    // 颜色插值
    final List<double> color = interpolate(fromColor, toColor, v);
    final List<int> roundedColor = color
        .map((c) => max(0, min(255, c.round())))
        .toList();

    // 旋转矩阵插值
    final List<double> rotation = interpolate([0.0], [toRotationDeg], v);
    final List<double> matrix = convertRotationToMatrix(rotation[0]);

    // 构建最终字符串
    final List<String> strArr = [];
    // 颜色的 hex 值 (Python 使用 format(round(value), 'x')：不补 0)
    for (int i = 0; i < 3; i++) {
      final String hx = roundedColor[i].toRadixString(16);
      strArr.add(hx);
    }

    // 矩阵浮点数 -> 类 hex 的字符串表达形式
    for (final val in matrix) {
      double r = double.parse(val.toStringAsFixed(2));
      if (r < 0) r = r.abs();
      final String hexVal = _floatToHex(r);
      String finalHex;
      if (hexVal.startsWith('.')) {
        finalHex = '0${hexVal.substring(1)}';
      } else if (hexVal.isEmpty) {
        finalHex = '0';
      } else {
        finalHex = hexVal;
      }
      strArr.add(finalHex.toLowerCase());
    }

    // 按照 Python 逻辑补两个 0 
    strArr.addAll(['0', '0']);
    final String animationKey = strArr.join().replaceAll(RegExp(r'[.\-]'), '');
    return animationKey;
  }

  double _solve(double value, double minVal, double maxVal, bool rounding) {
    final double res = value * (maxVal - minVal) / 255.0 + minVal;
    if (rounding) {
      return res.floorToDouble();
    }
    return double.parse(res.toStringAsFixed(2));
  }

  String _getAnimationKey(List<int> keyBytesLocal, String homePage) {
    // 参考 Python 代码中默认设置的 totalTime = 4096
    const int totalTime = 4096;

    if (rowIndexIndex >= keyBytesLocal.length) {
      throw Exception("rowIndexIndex ($rowIndexIndex) 超出边界");
    }
    final int rowIndex = keyBytesLocal[rowIndexIndex] % 16;

    int frameTimeProduct = 1;
    for (final idx in keyBytesIndices) {
      if (idx >= keyBytesLocal.length) {
        throw Exception("Key byte index $idx 超出边界");
      }
      final int v = keyBytesLocal[idx] % 16;
      frameTimeProduct *= v;
    }

    final double frameTime = _customRoundDouble(frameTimeProduct / 10.0) * 10.0;

    final List<List<int>> arr = _get2dArray(keyBytesLocal, homePage);
    if (rowIndex >= arr.length) {
      throw Exception("帧行索引 $rowIndex 超出边界 (最大 ${arr.length})");
    }
    final List<int> frameRow = arr[rowIndex];

    final double targetTime = frameTime / totalTime;
    final String animKey = _animate(frameRow, targetTime);
    return animKey;
  }

  // ----------------- 公开方法: 生成 Transaction ID -----------------
  String generateTransactionId({
    required String method,
    required String url,
    int? timeNowOverride, // 秒数, 基于 epoch offset
  }) {
    final String path = Uri.parse(url).path;

    // 计算 finalTimeNow = floor(now_seconds - epochOffsetSeconds)
    final int nowSec = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    final int finalTimeNow = timeNowOverride ?? (nowSec - _epochOffsetSeconds);

    // 基于 finalTimeNow 得到 4 字节的 little-endian
    final List<int> timeNowBytes = [
      (finalTimeNow >> 0) & 0xFF,
      (finalTimeNow >> 8) & 0xFF,
      (finalTimeNow >> 16) & 0xFF,
      (finalTimeNow >> 24) & 0xFF,
    ];

    // 构建 hash 输入。Python：f"{method}!{path}!{time_now}{self.random_keyword}{animation_key}"
    final String hashInput =
        "$method!$path!$finalTimeNow$randomKeyword$animationKey";
    final List<int> hashInputBytes = utf8.encode(hashInput);
    final Digest digest = sha256.convert(hashInputBytes);
    final List<int> hashBytes = digest.bytes;

    final int randomNum = Random().nextInt(256);
    final List<int> bytesArr = [
      ...keyBytes,
      ...timeNowBytes,
      ...hashBytes.sublist(0, min(16, hashBytes.length)),
      randomNumber,
    ];

    final List<int> out = [randomNum, ...bytesArr.map((b) => b ^ randomNum)];

    // Base64 编码并移除末尾的 '='
    final String b64 = base64.encode(out);
    return b64.replaceAll('=', '');
  }
}

// -------------------- Cubic 贝塞尔曲线计算类 --------------------
class Cubic {
  final List<double> curves;
  Cubic(List<double> arr) : curves = arr.map((e) => e.toDouble()).toList();

  double getValue(double time) {
    if (time <= 0.0) {
      if (curves.length >= 4) {
        if (curves[0] > 0.0) return (curves[1] / curves[0]) * time;
        if (curves[1] == 0.0 && curves[2] > 0.0) {
          return (curves[3] / curves[2]) * time;
        }
      }
      return 0.0;
    }
    if (time >= 1.0) {
      if (curves.length >= 4) {
        if (curves[2] < 1.0) {
          return 1.0 + ((curves[3] - 1.0) / (curves[2] - 1.0)) * (time - 1.0);
        }
        if (curves[2] == 1.0 && curves[0] < 1.0) {
          return 1.0 + ((curves[1] - 1.0) / (curves[0] - 1.0)) * (time - 1.0);
        }
      }
      return 1.0;
    }

    double start = 0.0;
    double end = 1.0;
    double mid = 0.0;
    while (start < end) {
      mid = (start + end) / 2.0;
      double xEst = _calc(
        (curves.isNotEmpty ? curves[0] : 0.0),
        (curves.length > 2 ? curves[2] : 0.0),
        mid,
      );
      if ((time - xEst).abs() < 0.00001) {
        return _calc(
          (curves.length > 1 ? curves[1] : 0.0),
          (curves.length > 3 ? curves[3] : 0.0),
          mid,
        );
      }
      if (xEst < time) {
        start = mid;
      } else {
        end = mid;
      }
    }
    return _calc(
      (curves.length > 1 ? curves[1] : 0.0),
      (curves.length > 3 ? curves[3] : 0.0),
      mid,
    );
  }

  static double _calc(double a, double b, double m) {
    return 3.0 * a * (1 - m) * (1 - m) * m +
        3.0 * b * (1 - m) * m * m +
        m * m * m;
  }
}

// -------------------- Generator: 抓取网页并生成 ID --------------------
class XClientGenerator {
  final Dio _dio;
  XClientGenerator() : _dio = Dio() {
    // 基于 utils.generate_headers() 的最新 header 参数配置
    _dio.options.headers = {
      "Authority": "x.com",
      "Accept-Language": "en-US,en;q=0.9",
      "Cache-Control": "no-cache",
      "Referer": "https://x.com",
      "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36",
      "X-Twitter-Active-User": "yes",
      "X-Twitter-Client-Language": "en"
    };
  }

  static const String _ondemandTemplate =
      "https://abs.twimg.com/responsive-web/client-web/ondemand.s.{filename}a.js";

  // 最新 Python 的解析逻辑：先提取索引数字 -> 后查找对应该数字的哈希映射
  static final RegExp _ondemandIndexRegex = RegExp(
    r""",(\d+):["']ondemand\.s["']""",
    multiLine: true,
  );

  String? _getOndemandUrlFromHtml(String html) {
    // 1. 获取映射索引
    final m1 = _ondemandIndexRegex.firstMatch(html);
    if (m1 != null && m1.groupCount >= 1) {
      final String index = m1.group(1)!;
      // 2. 根据索引去查找哈希值 (即文件名), 匹配: ,INDEX:"HASH"
      final RegExp hashRegex = RegExp(',$index:"([0-9a-f]+)"');
      final m2 = hashRegex.firstMatch(html);
      if (m2 != null && m2.groupCount >= 1) {
        final String hash = m2.group(1)!;
        return _ondemandTemplate.replaceFirst('{filename}', hash);
      }
    }
    return null;
  }

  // 处理 X/Twitter 最近可能下发的重定向和挑战页面
  Future<String> _fetchHomePage() async {
    logger.i("正在获取主页 https://x.com ...");
    var response = await _dio.get("https://x.com");
    var htmlText = response.data.toString();

    final RegExp migrationUrlRegex = RegExp(
      r"""(http(?:s)?://(?:www\.)?(twitter|x){1}\.com(/x)?/migrate([/?])?tok=[a-zA-Z0-9%\-_]+)+""",
    );

    // 第一重防护：判断是否有 meta 自动重定向
    var doc = html_parser.parse(htmlText);
    final metaRefresh = doc.querySelector("meta[http-equiv='refresh']");
    if (metaRefresh != null) {
      final match = migrationUrlRegex.firstMatch(metaRefresh.outerHtml) ?? migrationUrlRegex.firstMatch(htmlText);
      if (match != null) {
        final redirectUrl = match.group(0)!;
        logger.i("发现迁移重定向机制，正在跳转至: $redirectUrl");
        response = await _dio.get(redirectUrl);
        htmlText = response.data.toString();
        doc = html_parser.parse(htmlText);
      }
    }

    // 第二重防护：判断是否有迁移表单 (比如验证用户/机器人环境等)
    final form = doc.querySelector("form[name='f']") ?? doc.querySelector("form[action='https://x.com/x/migrate']");
    if (form != null) {
      final action = form.attributes['action'] ?? "https://x.com/x/migrate";
      final method = (form.attributes['method'] ?? "POST").toUpperCase();
      final inputs = form.querySelectorAll("input");
      final Map<String, dynamic> data = {};
      for (var input in inputs) {
        final name = input.attributes['name'];
        final value = input.attributes['value'];
        if (name != null) {
          data[name] = value ?? "";
        }
      }
      logger.i("检测到环境验证/迁移表单，正在自动提交至: $action");
      if (method == "POST") {
        response = await _dio.post(
          action,
          data: data,
          options: Options(
            headers: {"Content-Type": "application/x-www-form-urlencoded"}
          )
        );
      } else {
        response = await _dio.get(action, queryParameters: data);
      }
      htmlText = response.data.toString();
    }

    return htmlText;
  }

  Future<XClientTransactionService> fetchService() async {
    logger.i("正在获取 XClient 生成所需要的网页及 JS...");
    try {
      // 1. 获取处理重定向后的完整主页
      final String homeHtml = await _fetchHomePage();

      // 2. 解析主页寻找 ondemand 文件的动态 URL
      final ondemandUrl = _getOndemandUrlFromHtml(homeHtml);
      if (ondemandUrl == null) {
        throw Exception("主页 HTML 中未找到 ondemand 哈希及动态地址");
      }
      logger.i("获取到 ondemand js 的地址: $ondemandUrl");

      // 3. 获取对应的 ondemand js 内容
      final ondemandResp = await _dio.get(ondemandUrl);
      final String ondemandJs = ondemandResp.data.toString();

      // 4. 组装并初始化 Service 返回
      final svc = XClientTransactionService(
        homePageHtml: homeHtml,
        ondemandJsText: ondemandJs,
      );
      logger.i("Service 实例创建并初始化完毕");
      return svc;
    } on DioException catch (e) {
      logger.i("获取网页数据时发生网络错误: ${e.message}");
      rethrow;
    } catch (e, s) {
      logger.i("创建 Service 期间遇到未知异常: $e\n$s");
      rethrow;
    }
  }

  Future<String?> fetchAndGenerateTransactionId({
    required String method,
    required String url,
  }) async {
    logger.i("开始单次请求执行及获取过程...");
    try {
      final svc = await fetchService();

      final txid = svc.generateTransactionId(method: method, url: url);
      logger.i("成功生成 txid: $txid");
      return txid;
    } on DioException catch (e) {
      logger.i("网络层错误: ${e.message}");
      return null;
    } catch (e, s) {
      logger.i("计算 txid 时捕获到异常: $e\n$s");
      return null;
    }
  }
}
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
/// Full implementation translated & corrected from Python/JS reference.
/// Use XClientGenerator.fetchAndGenerateTransactionId(method: "GET", url: "https://x.com/....")
/// to get a valid x-client-transaction-id string.
///
/// NOTE: network calls use Dio and expect normal network availability.
class XClientTransactionService {
  // 数值插值
  List<double> interpolate(List<num> fromList, List<num> toList, double f) {
    if (fromList.length != toList.length) {
      throw Exception("Mismatched interpolation arguments");
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
    // 匹配 Python 中返回的 4 元素列表
    return [cosVal, -sinVal, sinVal, cosVal];
  }

  final String homePageHtml; // full home page HTML text
  final String ondemandJsText; // text of ondemand.s.*.js
  final String randomKeyword;
  final int
  randomNumber; // additional random number appended (like Python constant)

  late final int
  rowIndexIndex; // index extracted from ondemand indices (first one)
  late final List<int>
  keyBytesIndices; // indices used to compute frameTimeProduct
  late final List<int> keyBytes; // base64-decoded key bytes (from meta)
  late final String animationKey; // computed animation key

  static const int _epochOffsetSeconds = 1682924400;
  static const String _indicesPattern = r"""(\(\w{1}\[(\d{1,2})\],\s*16\))+""";

  XClientTransactionService({
    required this.homePageHtml,
    required this.ondemandJsText,
    String? randomKeyword,
    int? randomNumber,
  }) : randomKeyword = randomKeyword ?? "obfiowerehiring",
       randomNumber = randomNumber ?? 3 {
    final Map<String, dynamic> indices = _getIndices(ondemandJsText);
    rowIndexIndex = indices['rowIndex'] as int;
    keyBytesIndices = List<int>.from(indices['keyBytesIndices'] as List<int>);

    final String metaKey = _getKey(homePageHtml);
    keyBytes = _getKeyBytes(metaKey);
    animationKey = _getAnimationKey(keyBytes, homePageHtml);
  }

  // ----------------- helpers: parsing ondemand for indices -----------------
  Map<String, dynamic> _getIndices(String ondemandText) {
    final RegExp rx = RegExp(_indicesPattern, multiLine: true);
    final Iterable<RegExpMatch> matches = rx.allMatches(ondemandText);
    final List<int> idxs = [];

    for (final m in matches) {
      // the second capture group contains the number
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
      throw Exception("Couldn't get KEY_BYTE indices from ondemand JS");
    }

    return {
      // first entry is rowIndexIndex (index into keyBytes)
      'rowIndex': idxs.first,
      // remaining are keyBytes indices used for frameTimeProduct
      'keyBytesIndices': idxs.length > 1 ? idxs.sublist(1) : <int>[],
    };
  }

  // ----------------- helpers: meta key extraction -----------------
  String _getKey(String htmlText) {
    final doc = html_parser.parse(htmlText);
    final html_dom.Element? meta = doc.querySelector(
      "meta[name='twitter-site-verification']",
    );
    final String? content = meta?.attributes['content'];
    if (content == null || content.isEmpty) {
      throw Exception(
        "Couldn't get twitter-site-verification meta content from page HTML",
      );
    }
    return content;
  }

  List<int> _getKeyBytes(String keyBase64) {
    try {
      final bytes = base64.decode(keyBase64);
      return bytes;
    } catch (e) {
      // fallback: interpret as utf8 bytes
      return utf8.encode(keyBase64);
    }
  }

  // ----------------- helpers: extract SVG frames matrix -----------------
  List<html_dom.Element> _getFrames(String htmlText) {
    final doc = html_parser.parse(htmlText);
    final List<html_dom.Element> frames = [];
    for (int i = 0; i < 4; i++) {
      final el = doc.querySelector("#loading-x-anim-$i");
      if (el != null) frames.add(el);
    }
    return frames;
  }

  /// Parse the SVG path 'd' values into a 2D array of integer numbers
  /// This preserves negative numbers & decimals (we round to nearest int).
  List<List<int>> _get2dArray(List<int> keyBytes, String homePageResponse) {
    final frames = _getFrames(homePageResponse);
    if (frames.isEmpty) {
      throw Exception("Couldn't find animation frames in HTML.");
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
      throw Exception(
        "Couldn't extract 'd' attribute from SVG path. Attribute: $dAttribute",
      );
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

    // **如果只找到 1 行，复制几份，防止 rowIndex 越界**
    while (result.length < 4) {
      result.add(result[0]);
    }

    return result;
  }

  // ----------------- numeric helpers -----------------
  static double _customRoundDouble(double x) {
    // emulate Python rounding used previously
    final int floorX = x.floor();
    return ((x - floorX).abs() >= 0.5) ? floorX + 1.0 : floorX.toDouble();
  }

  static double _isOddVal(int n) {
    return n % 2 != 0 ? -1.0 : 0.0;
  }

  /// Emulate floatToHex from reference: convert positive double to hex integer.fraction form (no "0x").
  String _floatToHex(double x) {
    if (x == 0.0) return '0';
    x = x.abs();
    final int integer = x.floor();
    double frac = x - integer;
    final List<String> parts = [];
    // integer to hex
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
    // fractional
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

  // ----------------- Cubic / animation helpers -----------------
  String _animate(List<int> frames, double targetTime) {
    // frames expected: [r0,g0,b0, r1,g1,b1, rotateByte, curveBytes...]
    if (frames.length < 7) {
      throw Exception("Frame row must contain at least 7 values");
    }
    final List<double> fromColor = [
      frames[0].toDouble(),
      frames[1].toDouble(),
      frames[2].toDouble(),
      1.0,
    ];
    final List<double> toColor = [
      frames[3].toDouble(),
      frames[4].toDouble(),
      frames[5].toDouble(),
      1.0,
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

    // color interpolation
    final List<double> color = interpolate(fromColor, toColor, v);
    final List<int> roundedColor = color
        .map((c) => max(0, min(255, c.round())))
        .toList();

    // rotation matrix
    final List<double> rotation = interpolate([0.0], [toRotationDeg], v);
    final List<double> matrix = convertRotationToMatrix(rotation[0]);

    // build string pieces
    final List<String> strArr = [];
    // hex of colors (skip alpha)
    for (int i = 0; i < 3; i++) {
      final String hx = roundedColor[i].toRadixString(16);
      strArr.add(hx);
    }

    // matrix floats => hex-like representation
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

    // append two zeros as in translation
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
    // totalTime 4096 used in reference
    const int totalTime = 4096;

    // rowIndexIndex is the stored index extracted from ondemand (an index into keyBytes)
    if (rowIndexIndex >= keyBytesLocal.length) {
      throw Exception(
        "rowIndexIndex ($rowIndexIndex) out of bounds for keyBytes length ${keyBytesLocal.length}",
      );
    }
    final int rowIndex = keyBytesLocal[rowIndexIndex] % 16;

    int frameTimeProduct = 1;
    for (final idx in keyBytesIndices) {
      if (idx >= keyBytesLocal.length) {
        throw Exception(
          "Key byte index $idx out of bounds (${keyBytesLocal.length})",
        );
      }
      final int v = keyBytesLocal[idx] % 16;
      frameTimeProduct *= v;
    }

    final double frameTime = _customRoundDouble(frameTimeProduct / 10.0) * 10.0;

    final List<List<int>> arr = _get2dArray(keyBytesLocal, homePage);
    if (rowIndex >= arr.length) {
      throw Exception(
        "Frame row index $rowIndex out of bounds (arr length ${arr.length})",
      );
    }
    final List<int> frameRow = arr[rowIndex];

    final double targetTime = frameTime / totalTime;
    final String animKey = _animate(frameRow, targetTime);
    return animKey;
  }

  // ----------------- Public: generate transaction id -----------------
  String generateTransactionId({
    required String method,
    required String url,
    int? timeNowOverride, // seconds relative to our epoch offset
  }) {
    final String path = Uri.parse(url).path;

    // compute finalTimeNow = floor(now_seconds - epochOffsetSeconds)
    final int nowSec = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    final int finalTimeNow = timeNowOverride ?? (nowSec - _epochOffsetSeconds);

    // 4 bytes little-endian from finalTimeNow
    final List<int> timeNowBytes = [
      (finalTimeNow >> 0) & 0xFF,
      (finalTimeNow >> 8) & 0xFF,
      (finalTimeNow >> 16) & 0xFF,
      (finalTimeNow >> 24) & 0xFF,
    ];

    // build hash input exactly like reference: "$method!$path!$time$keyword$animationKey"
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

    // base64 encode and remove '=' padding
    final String b64 = base64.encode(out);
    return b64.replaceAll('=', '');
  }
}

// -------------------- Cubic helper class --------------------
class Cubic {
  final List<double> curves;
  Cubic(List<double> arr) : curves = arr.map((e) => e.toDouble()).toList();

  double getValue(double time) {
    if (time <= 0.0) {
      // approximate start gradient
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

// -------------------- Generator class to fetch home page & ondemand --------------------
class XClientGenerator {
  final Dio _dio;
  XClientGenerator() : _dio = Dio() {
    _dio.options.headers = {
      "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36",
      "Accept-Language": "en-US,en;q=0.9",
      "Cache-Control": "no-cache",
      "Referer": "https://api.x.com",
    };
  }

  static const String _ondemandTemplate =
      "https://abs.twimg.com/responsive-web/client-web/ondemand.s.{filename}a.js";
  static final RegExp _ondemandRegex = RegExp(
    r"""['|"]{1}ondemand\.s['|"]{1}:\s*['|"]{1}([\w]*)['|"]{1}""",
    multiLine: true,
  );

  String? _getOndemandUrlFromHtml(String html) {
    final m = _ondemandRegex.firstMatch(html);
    if (m != null && m.groupCount >= 1) {
      final String fname = m.group(1)!;
      return _ondemandTemplate.replaceFirst('{filename}', fname);
    }
    return null;
  }

  Future<XClientTransactionService> fetchService() async {
    logger.i("Fetching resources for service...");
    try {
      // 1. fetch home page
      logger.i("Fetching https://x.com ...");
      final homeResp = await _dio.get("https://x.com");
      final String homeHtml = homeResp.data.toString();

      // 2. find ondemand file url
      final ondemandUrl = _getOndemandUrlFromHtml(homeHtml);
      if (ondemandUrl == null) {
        throw Exception("ondemand filename not found in home page HTML.");
      }
      logger.i("Found ondemand url: $ondemandUrl");

      // 3. fetch ondemand js
      final ondemandResp = await _dio.get(ondemandUrl);
      final String ondemandJs = ondemandResp.data.toString();

      // 4. create service & return
      final svc = XClientTransactionService(
        homePageHtml: homeHtml,
        ondemandJsText: ondemandJs,
      );
      logger.i("Service instance created.");
      return svc;
    } on DioException catch (e) {
      logger.i("Network error while fetching service: ${e.message}");
      rethrow;
    } catch (e, s) {
      logger.i("Error creating service: $e\n$s");
      rethrow;
    }
  }

  Future<String?> fetchAndGenerateTransactionId({
    required String method,
    required String url,
  }) async {
    logger.i("Starting fetch-and-generate (single)...");
    try {
      // 复用 fetchService()
      final svc = await fetchService();

      final txid = svc.generateTransactionId(method: method, url: url);
      logger.i("Generated txid: $txid");
      return txid;
    } on DioException catch (e) {
      logger.i("Network error: ${e.message}");
      return null;
    } catch (e, s) {
      logger.i("Error generating txid: $e\n$s");
      return null;
    }
  }
}

import 'dart:convert';
import 'dart:math';
// ignore: depend_on_referenced_packages
import 'package:crypto/crypto.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom show Element;
import 'package:dio/dio.dart';
import 'package:autonitor/services/log_service.dart';

/// XClientTransactionService / XClientGenerator
/// A full Dart implementation rewritten and corrected based on the latest Python version.
/// Use XClientGenerator().fetchAndGenerateTransactionId(method: "GET", url: "https://x.com/....")
/// to obtain a valid x-client-transaction-id string.
///
/// Note: Network requests use Dio and rely on normal network connectivity.
class XClientTransactionService {
  // Numerical interpolation
  List<double> interpolate(List<num> fromList, List<num> toList, double f) {
    if (fromList.length != toList.length) {
      throw Exception("Interpolation parameter length mismatch");
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
    // Matches the 4-element list returned in Python: [cos, -sin, sin, cos]
    return [cosVal, -sinVal, sinVal, cosVal];
  }

  final String homePageHtml; // Full home page HTML text
  final String ondemandJsText; // ondemand.s.*.js text
  final String randomKeyword;
  final int
  randomNumber; // Additional random number (similar to ADDITIONAL_RANDOM_NUMBER in Python)

  late final int rowIndexIndex; // First index extracted from ondemand
  late final List<int>
  keyBytesIndices; // Remaining indices used to calculate frameTimeProduct
  late final List<int> keyBytes; // Base64 decoded key bytes (from meta)
  late final String animationKey; // Calculated animation key

  static const int _epochOffsetSeconds = 1682924400;
  // Matches indices pattern
  static const String _indicesPattern = r"""(\(\w{1}\[(\d{1,2})\],\s*16\))+""";

  XClientTransactionService({
    required this.homePageHtml,
    required this.ondemandJsText,
    String? randomKeyword,
    int? randomNumber,
  }) : randomKeyword =
           randomKeyword ?? "obfiowerehiring", // Latest default keyword
       randomNumber = randomNumber ?? 3 {
    final Map<String, dynamic> indices = _getIndices(ondemandJsText);
    rowIndexIndex = indices['rowIndex'] as int;
    keyBytesIndices = List<int>.from(indices['keyBytesIndices'] as List<int>);

    final String metaKey = _getKey(homePageHtml);
    keyBytes = _getKeyBytes(metaKey);
    animationKey = _getAnimationKey(keyBytes, homePageHtml);
  }

  // ----------------- Helper method: Extract indices from ondemand -----------------
  Map<String, dynamic> _getIndices(String ondemandText) {
    final RegExp rx = RegExp(_indicesPattern, multiLine: true);
    final Iterable<RegExpMatch> matches = rx.allMatches(ondemandText);
    final List<int> idxs = [];

    for (final m in matches) {
      // The second capture group contains the actual number
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
      throw Exception("Unable to obtain KEY_BYTE indices from ondemand JS");
    }

    return {
      // First item is rowIndexIndex (used to retrieve keyBytes)
      'rowIndex': idxs.first,
      // The rest are used to calculate frameTimeProduct
      'keyBytesIndices': idxs.length > 1 ? idxs.sublist(1) : <int>[],
    };
  }

  // ----------------- Helper method: Extract Meta Key -----------------
  String _getKey(String htmlText) {
    final doc = html_parser.parse(htmlText);
    final html_dom.Element? meta = doc.querySelector(
      "meta[name='twitter-site-verification']",
    );
    final String? content = meta?.attributes['content'];
    if (content == null || content.isEmpty) {
      throw Exception(
        "Unable to get twitter-site-verification meta content from page HTML",
      );
    }
    return content;
  }

  List<int> _getKeyBytes(String keyBase64) {
    try {
      final bytes = base64.decode(keyBase64);
      return bytes;
    } catch (e) {
      // Fallback: treat as utf8 bytes
      return utf8.encode(keyBase64);
    }
  }

  // ----------------- Helper method: Extract SVG frame matrices -----------------
  List<html_dom.Element> _getFrames(String htmlText) {
    final doc = html_parser.parse(htmlText);
    final List<html_dom.Element> frames = [];
    for (int i = 0; i < 4; i++) {
      final el = doc.querySelector("#loading-x-anim-$i");
      if (el != null) frames.add(el);
    }
    return frames;
  }

  /// Parses the SVG path 'd' value into a 2D integer array.
  /// Retains negative numbers and decimal points (rounded to the nearest integer).
  List<List<int>> _get2dArray(List<int> keyBytes, String homePageResponse) {
    final frames = _getFrames(homePageResponse);
    if (frames.isEmpty) {
      throw Exception("Animation frame elements not found in HTML");
    }

    final frameIndex = keyBytes[5] % frames.length; // Safe index
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
        "Unable to extract 'd' attribute from SVG path. Current attribute: $dAttribute",
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

    // If fewer than 4 rows are found, copy a few to prevent rowIndex out of bounds
    while (result.length < 4) {
      result.add(result[0]);
    }

    return result;
  }

  // ----------------- Float processing -----------------
  static double _customRoundDouble(double x) {
    // Simulate the rounding mechanism used in previous Python versions
    final int floorX = x.floor();
    return ((x - floorX).abs() >= 0.5) ? floorX + 1.0 : floorX.toDouble();
  }

  static double _isOddVal(int n) {
    return n % 2 != 0 ? -1.0 : 0.0;
  }

  /// Simulates float to hex in Python: convert positive double to hex integer.fraction format
  String _floatToHex(double x) {
    if (x == 0.0) return '0';
    x = x.abs();
    final int integer = x.floor();
    double frac = x - integer;
    final List<String> parts = [];

    // Handle integer part
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

    // Handle fractional part
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

  // ----------------- Animation generation and Cubic curve calculation -----------------
  String _animate(List<int> frames, double targetTime) {
    // Expected format for frames: [r0, g0, b0, r1, g1, b1, rotateByte, curveBytes...]
    if (frames.length < 7) {
      throw Exception("Frame row must contain at least 7 values");
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

    // Color interpolation
    final List<double> color = interpolate(fromColor, toColor, v);
    final List<int> roundedColor = color
        .map((c) => max(0, min(255, c.round())))
        .toList();

    // Rotation matrix interpolation
    final List<double> rotation = interpolate([0.0], [toRotationDeg], v);
    final List<double> matrix = convertRotationToMatrix(rotation[0]);

    // Build final string
    final List<String> strArr = [];
    // Hex value of color (Python uses format(round(value), 'x'): no padding with 0)
    for (int i = 0; i < 3; i++) {
      final String hx = roundedColor[i].toRadixString(16);
      strArr.add(hx);
    }

    // Matrix float -> hex-like string representation
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

    // Add two zeros following Python logic
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
    // Refer to totalTime = 4096 default setting in Python code
    const int totalTime = 4096;

    if (rowIndexIndex >= keyBytesLocal.length) {
      throw Exception("rowIndexIndex ($rowIndexIndex) out of bounds");
    }
    final int rowIndex = keyBytesLocal[rowIndexIndex] % 16;

    int frameTimeProduct = 1;
    for (final idx in keyBytesIndices) {
      if (idx >= keyBytesLocal.length) {
        throw Exception("Key byte index $idx out of bounds");
      }
      final int v = keyBytesLocal[idx] % 16;
      frameTimeProduct *= v;
    }

    final double frameTime = _customRoundDouble(frameTimeProduct / 10.0) * 10.0;

    final List<List<int>> arr = _get2dArray(keyBytesLocal, homePage);
    if (rowIndex >= arr.length) {
      throw Exception(
        "Frame row index $rowIndex out of bounds (max ${arr.length})",
      );
    }
    final List<int> frameRow = arr[rowIndex];

    final double targetTime = frameTime / totalTime;
    final String animKey = _animate(frameRow, targetTime);
    return animKey;
  }

  // ----------------- Public method: Generate Transaction ID -----------------
  String generateTransactionId({
    required String method,
    required String url,
    int? timeNowOverride, // Seconds, based on epoch offset
  }) {
    final String path = Uri.parse(url).path;

    // Calculate finalTimeNow = floor(now_seconds - epochOffsetSeconds)
    final int nowSec = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    final int finalTimeNow = timeNowOverride ?? (nowSec - _epochOffsetSeconds);

    // Get 4-byte little-endian based on finalTimeNow
    final List<int> timeNowBytes = [
      (finalTimeNow >> 0) & 0xFF,
      (finalTimeNow >> 8) & 0xFF,
      (finalTimeNow >> 16) & 0xFF,
      (finalTimeNow >> 24) & 0xFF,
    ];

    // Construct hash input. Python: f"{method}!{path}!{time_now}{self.random_keyword}{animation_key}"
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

    // Base64 encode and remove trailing '='
    final String b64 = base64.encode(out);
    return b64.replaceAll('=', '');
  }
}

// -------------------- Cubic Bezier curve calculation class --------------------
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

// -------------------- Generator: Scrape webpage and generate ID --------------------
class XClientGenerator {
  final Dio _dio;
  XClientGenerator() : _dio = Dio() {
    // Latest header parameter configuration based on utils.generate_headers()
    _dio.options.headers = {
      "Authority": "x.com",
      "Accept-Language": "en-US,en;q=0.9",
      "Cache-Control": "no-cache",
      "Referer": "https://x.com",
      "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36",
      "X-Twitter-Active-User": "yes",
      "X-Twitter-Client-Language": "en",
    };
  }

  static const String _ondemandTemplate =
      "https://abs.twimg.com/responsive-web/client-web/ondemand.s.{filename}a.js";

  // Latest Python parsing logic: first extract index number -> then look up the hash mapping corresponding to that number
  static final RegExp _ondemandIndexRegex = RegExp(
    r""",(\d+):["']ondemand\.s["']""",
    multiLine: true,
  );

  String? _getOndemandUrlFromHtml(String html) {
    // 1. Get mapping index
    final m1 = _ondemandIndexRegex.firstMatch(html);
    if (m1 != null && m1.groupCount >= 1) {
      final String index = m1.group(1)!;
      // 2. Find hash value (i.e., filename) based on index, match: ,INDEX:"HASH"
      final RegExp hashRegex = RegExp(',$index:"([0-9a-f]+)"');
      final m2 = hashRegex.firstMatch(html);
      if (m2 != null && m2.groupCount >= 1) {
        final String hash = m2.group(1)!;
        return _ondemandTemplate.replaceFirst('{filename}', hash);
      }
    }
    return null;
  }

  // Handle redirection and challenge pages that X/Twitter might issue recently
  Future<String> _fetchHomePage() async {
    logger.i("Fetching https://x.com ...");
    var response = await _dio.get("https://x.com");
    var htmlText = response.data.toString();

    final RegExp migrationUrlRegex = RegExp(
      r"""(http(?:s)?://(?:www\.)?(twitter|x){1}\.com(/x)?/migrate([/?])?tok=[a-zA-Z0-9%\-_]+)+""",
    );

    // First layer of protection: determine if there is a meta automatic redirect
    var doc = html_parser.parse(htmlText);
    final metaRefresh = doc.querySelector("meta[http-equiv='refresh']");
    if (metaRefresh != null) {
      final match =
          migrationUrlRegex.firstMatch(metaRefresh.outerHtml) ??
          migrationUrlRegex.firstMatch(htmlText);
      if (match != null) {
        final redirectUrl = match.group(0)!;
        logger.i(
          "A migration redirection mechanism has been detected, redirecting to: $redirectUrl",
        );
        response = await _dio.get(redirectUrl);
        htmlText = response.data.toString();
        doc = html_parser.parse(htmlText);
      }
    }

    // Second layer of protection: determine if there is a migration form (e.g., verifying user/bot environment, etc.)
    final form =
        doc.querySelector("form[name='f']") ??
        doc.querySelector("form[action='https://x.com/x/migrate']");
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
      logger.i(
        "A migration form has been detected, automatically submitting to: $action",
      );
      if (method == "POST") {
        response = await _dio.post(
          action,
          data: data,
          options: Options(
            headers: {"Content-Type": "application/x-www-form-urlencoded"},
          ),
        );
      } else {
        response = await _dio.get(action, queryParameters: data);
      }
      htmlText = response.data.toString();
    }

    return htmlText;
  }

  Future<XClientTransactionService> fetchService() async {
    logger.i("Fetching XClient required web pages and JS...");
    try {
      // 1. Obtain the full home page after handling redirects
      final String homeHtml = await _fetchHomePage();

      // 2. Parse the home page to find the dynamic URL of the ondemand file
      final ondemandUrl = _getOndemandUrlFromHtml(homeHtml);
      if (ondemandUrl == null) {
        throw Exception(
          "Ondemand hash and dynamic address not found in home page HTML",
        );
      }
      logger.i("Obtained ondemand js address: $ondemandUrl");

      // 3. Get the corresponding ondemand js content
      final ondemandResp = await _dio.get(ondemandUrl);
      final String ondemandJs = ondemandResp.data.toString();

      // 4. Assemble and initialize Service return
      final svc = XClientTransactionService(
        homePageHtml: homeHtml,
        ondemandJsText: ondemandJs,
      );
      logger.i("Service instance created and initialized");
      return svc;
    } on DioException catch (e) {
      logger.i(
        "Network error occurred while fetching web page data: ${e.message}",
      );
      rethrow;
    } catch (e, s) {
      logger.i("Encountered unknown exception during Service creation: $e\n$s");
      rethrow;
    }
  }

  Future<String?> fetchAndGenerateTransactionId({
    required String method,
    required String url,
  }) async {
    logger.i("Starting single request execution and retrieval process...");
    try {
      final svc = await fetchService();

      final txid = svc.generateTransactionId(method: method, url: url);
      logger.i("Successfully generated txid: $txid");
      return txid;
    } on DioException catch (e) {
      logger.i("Network layer error: ${e.message}");
      return null;
    } catch (e, s) {
      logger.i("Exception caught while calculating txid: $e\n$s");
      return null;
    }
  }
}

import 'dart:convert';
import 'dart:math';

import 'package:autonitor/services/log_service.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart' show Element;
import 'package:html/parser.dart' as html_parser;

/// Dart port of `x_client_transaction.ClientTransaction`.
///
/// The public API intentionally accepts a full URL because all existing
/// autonitor callers provide one.  Only its path is part of X's hash input,
/// matching Python's `urlparse(url).path` usage.
class XClientTransactionService {
  XClientTransactionService({
    required this.homePageHtml,
    required this.ondemandJsText,
    String? randomKeyword,
    int? randomNumber,
  }) : randomKeyword = randomKeyword ?? _defaultKeyword,
       randomNumber = randomNumber ?? _additionalRandomNumber {
    final indices = _getIndices(ondemandJsText);
    _rowIndex = indices.$1;
    _keyBytesIndices = indices.$2;
    _key = _getKey(homePageHtml);
    _keyBytes = _getKeyBytes(_key);
    _animationKey = _getAnimationKey(_keyBytes, homePageHtml);
  }

  static const String _defaultKeyword = 'obfiowerehiring';
  static const int _additionalRandomNumber = 3;
  static const int _epochOffsetSeconds = 1682924400;

  /// This is the same expression as `INDICES_REGEX` in the Python project.
  static final RegExp _indicesRegex = RegExp(
    r'(\(\w{1}\[(\d{1,2})\],\s*16\))+',
    multiLine: true,
  );

  final String homePageHtml;
  final String ondemandJsText;
  final String randomKeyword;
  final int randomNumber;

  late final int _rowIndex;
  late final List<int> _keyBytesIndices;
  late final String _key;
  late final List<int> _keyBytes;
  late final String _animationKey;

  (int, List<int>) _getIndices(String ondemandText) {
    final indices = <int>[];
    for (final match in _indicesRegex.allMatches(ondemandText)) {
      final value = match.group(2);
      if (value != null) {
        indices.add(int.parse(value));
      }
    }
    if (indices.isEmpty) {
      throw StateError("Couldn't get KEY_BYTE indices from ondemand script.");
    }
    return (indices.first, List<int>.unmodifiable(indices.skip(1)));
  }

  String _getKey(String html) {
    final content = html_parser
        .parse(html)
        .querySelector("meta[name='twitter-site-verification']")
        ?.attributes['content'];
    if (content == null || content.isEmpty) {
      throw StateError(
        "Couldn't get [twitter-site-verification] key from the page source.",
      );
    }
    return content;
  }

  List<int> _getKeyBytes(String key) {
    var normalizedKey = key.trim();
    while (normalizedKey.length % 4 != 0) {
      normalizedKey += '=';
    }
    try {
      return base64.decode(normalizedKey);
    } on FormatException catch (error) {
      throw FormatException('Invalid twitter-site-verification key.', error);
    }
  }

  List<Element> _getFrames(String html) {
    return html_parser.parse(html).querySelectorAll('[id^="loading-x-anim"]');
  }

  List<List<int>> _get2dArray(List<int> keyBytes, String html) {
    if (keyBytes.length <= 5) {
      throw StateError(
        'Verification key is too short to select an animation frame.',
      );
    }

    final frames = _getFrames(html);
    final frameIndex = keyBytes[5] % 4;
    if (frameIndex >= frames.length) {
      throw StateError('The required loading animation frame is unavailable.');
    }

    // Equivalent to Python's
    // list(list(frames[index].children)[0].children)[1].get("d").
    final frame = frames[frameIndex];
    if (frame.children.isEmpty || frame.children.first.children.length < 2) {
      throw StateError('Unexpected loading animation SVG structure.');
    }
    final path = frame.children.first.children[1];
    final d = path.attributes['d'];
    if (path.localName != 'path' || d == null || d.length < 9) {
      throw StateError('Loading animation SVG path is unavailable.');
    }

    return d
        .substring(9)
        .split('C')
        .map(
          (segment) => segment
              .replaceAll(RegExp(r'[^\d]+'), ' ')
              .trim()
              .split(RegExp(r'\s+'))
              .where((value) => value.isNotEmpty)
              .map(int.parse)
              .toList(growable: false),
        )
        .toList(growable: false);
  }

  static double _solve(double value, double min, double max, bool rounding) {
    final result = value * (max - min) / 255 + min;
    return rounding ? result.floorToDouble() : _roundToDecimals(result, 2);
  }

  static double _roundToDecimals(double value, int decimals) {
    final scale = pow(10, decimals).toDouble();
    return _roundLikePython(value * scale) / scale;
  }

  /// Python's `round(float)` is nearest-even, unlike Dart's `double.round()`.
  static int _roundLikePython(double value) {
    final lower = value.floor();
    final fraction = value - lower;
    if (fraction < 0.5) return lower;
    if (fraction > 0.5) return lower + 1;
    return lower.isEven ? lower : lower + 1;
  }

  static double _isOdd(int number) => number.isOdd ? -1.0 : 0.0;

  static List<double> _interpolate(
    List<double> from,
    List<double> to,
    double progress,
  ) {
    if (from.length != to.length) {
      throw ArgumentError('Mismatched interpolation arguments: $from, $to');
    }
    return List<double>.generate(
      from.length,
      (index) => from[index] * (1 - progress) + to[index] * progress,
      growable: false,
    );
  }

  static List<double> _convertRotationToMatrix(double degrees) {
    final radians = degrees * pi / 180;
    final cosine = cos(radians);
    final sine = sin(radians);
    return [cosine, -sine, sine, cosine];
  }

  static String _floatToHex(double value) {
    var integer = value.truncate();
    var fraction = value - integer;
    final result = <String>[];

    if (integer > 0) {
      result.add(integer.toRadixString(16).toUpperCase());
    }
    if (fraction == 0) return result.join();

    result.add('.');
    // A binary double has at most 13 hexadecimal fractional digits.  The
    // guard also prevents malformed non-finite input from looping forever.
    for (var digits = 0; fraction > 0 && digits < 16; digits++) {
      fraction *= 16;
      final digit = fraction.truncate();
      fraction -= digit;
      result.add(digit.toRadixString(16).toUpperCase());
    }
    return result.join();
  }

  String _animate(List<int> frame, double targetTime) {
    if (frame.length < 11) {
      throw StateError('Loading animation frame does not contain curve data.');
    }

    final fromColor = [
      frame[0].toDouble(),
      frame[1].toDouble(),
      frame[2].toDouble(),
      1.0,
    ];
    final toColor = [
      frame[3].toDouble(),
      frame[4].toDouble(),
      frame[5].toDouble(),
      1.0,
    ];
    final toRotation = _solve(frame[6].toDouble(), 60, 360, true);
    final curves = List<double>.generate(
      frame.length - 7,
      (index) => _solve(frame[index + 7].toDouble(), _isOdd(index), 1, false),
      growable: false,
    );
    final progress = Cubic(curves).getValue(targetTime);
    final color = _interpolate(
      fromColor,
      toColor,
      progress,
    ).map((value) => value.clamp(0, 255).toDouble()).toList(growable: false);
    final matrix = _convertRotationToMatrix(
      _interpolate([0], [toRotation], progress).single,
    );

    final output = <String>[
      for (final value in color.take(3))
        _roundLikePython(value).toRadixString(16),
      for (final value in matrix)
        (() {
          final rounded = _roundToDecimals(value, 2).abs();
          final hex = _floatToHex(rounded);
          return (hex.startsWith('.')
                  ? '0$hex'
                  : hex.isEmpty
                  ? '0'
                  : hex)
              .toLowerCase();
        })(),
      '0',
      '0',
    ];
    return output.join().replaceAll(RegExp(r'[.\-]'), '');
  }

  String _getAnimationKey(List<int> keyBytes, String html) {
    if (_rowIndex >= keyBytes.length ||
        _keyBytesIndices.any((index) => index >= keyBytes.length)) {
      throw StateError(
        'Ondemand script index exceeds verification key length.',
      );
    }

    final rowIndex = keyBytes[_rowIndex] % 16;
    final frameTimeProduct = _keyBytesIndices.fold<int>(
      1,
      (product, index) => product * (keyBytes[index] % 16),
    );
    final frameTime = _roundLikePython(frameTimeProduct / 10) * 10;
    final rows = _get2dArray(keyBytes, html);
    if (rowIndex >= rows.length) {
      throw StateError('Loading animation row $rowIndex is unavailable.');
    }
    return _animate(rows[rowIndex], frameTime / 4096);
  }

  /// Generates one `x-client-transaction-id` value.
  String generateTransactionId({
    required String method,
    required String url,
    int? timeNowOverride,
  }) {
    final path = Uri.parse(url).path;
    final timeNow =
        timeNowOverride ??
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - _epochOffsetSeconds;
    final timeBytes = List<int>.generate(
      4,
      (index) => (timeNow >> (index * 8)) & 0xff,
      growable: false,
    );
    final hash = sha256
        .convert(
          utf8.encode('$method!$path!$timeNow$randomKeyword$_animationKey'),
        )
        .bytes;
    final random = Random().nextInt(256);
    final bytes = [..._keyBytes, ...timeBytes, ...hash.take(16), randomNumber];
    return base64
        .encode([random, ...bytes.map((byte) => byte ^ random)])
        .replaceAll('=', '');
  }
}

/// Port of `x_client_transaction.cubic_curve.Cubic`.
class Cubic {
  Cubic(this.curves) {
    if (curves.length < 4) {
      throw ArgumentError.value(
        curves,
        'curves',
        'At least four values are required.',
      );
    }
  }

  final List<double> curves;

  double getValue(double time) {
    if (time <= 0) {
      final gradient = curves[0] > 0
          ? curves[1] / curves[0]
          : curves[1] == 0 && curves[2] > 0
          ? curves[3] / curves[2]
          : 0.0;
      return gradient * time;
    }
    if (time >= 1) {
      final gradient = curves[2] < 1
          ? (curves[3] - 1) / (curves[2] - 1)
          : curves[2] == 1 && curves[0] < 1
          ? (curves[1] - 1) / (curves[0] - 1)
          : 0.0;
      return 1 + gradient * (time - 1);
    }

    var start = 0.0;
    var end = 1.0;
    var midpoint = 0.0;
    while (start < end) {
      midpoint = (start + end) / 2;
      final estimate = _calculate(curves[0], curves[2], midpoint);
      if ((time - estimate).abs() < 0.00001) {
        return _calculate(curves[1], curves[3], midpoint);
      }
      if (estimate < time) {
        start = midpoint;
      } else {
        end = midpoint;
      }
    }
    return _calculate(curves[1], curves[3], midpoint);
  }

  static double _calculate(double a, double b, double midpoint) {
    return 3 * a * (1 - midpoint) * (1 - midpoint) * midpoint +
        3 * b * (1 - midpoint) * midpoint * midpoint +
        midpoint * midpoint * midpoint;
  }
}

/// Fetches the changing X bootstrap resources used by [XClientTransactionService].
class XClientGenerator {
  XClientGenerator({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.headers.addAll(_headers);
  }

  static const _headers = <String, String>{
    'Authority': 'x.com',
    'Accept-Language': 'en-US,en;q=0.9',
    'Cache-Control': 'no-cache',
    'Referer': 'https://x.com',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36',
    'X-Twitter-Active-User': 'yes',
    'X-Twitter-Client-Language': 'en',
  };
  static const _ondemandTemplate =
      'https://abs.twimg.com/responsive-web/client-web/ondemand.s.{filename}a.js';
  static final _ondemandIndexRegex = RegExp(
    r''',(\d+):["']ondemand\.s["']''',
    multiLine: true,
  );
  static final _directOndemandHashRegex = RegExp(
    r'''["']ondemand\.s["']\s*:\s*["']([0-9a-zA-Z_]+)["']''',
    multiLine: true,
  );
  static final _migrationUrlRegex = RegExp(
    r'(http(?:s)?://(?:www\.)?(twitter|x){1}\.com(/x)?/migrate([/?])?tok=[a-zA-Z0-9%\-_]+)+',
  );

  final Dio _dio;

  String? _getOndemandUrlFromHtml(String html) {
    // Python's ON_DEMAND_FILE_REGEX followed by ON_DEMAND_HASH_PATTERN.
    final index = _ondemandIndexRegex.firstMatch(html)?.group(1);
    if (index != null) {
      final hash = RegExp(',$index:"([0-9a-f]+)"').firstMatch(html)?.group(1);
      if (hash != null) return _ondemandUrl(hash);
    }

    // X has also served this direct object form.  Supporting it keeps the
    // autonitor integration working without changing the Python-compatible
    // primary parsing behaviour above.
    final directHash = _directOndemandHashRegex.firstMatch(html)?.group(1);
    return directHash == null ? null : _ondemandUrl(directHash);
  }

  static String _ondemandUrl(String hash) =>
      _ondemandTemplate.replaceFirst('{filename}', hash);

  Future<String> _fetchHomePage() async {
    logger.i('Fetching X home page for transaction-id resources.');
    var response = await _dio.get<String>('https://x.com/home');
    var html = response.data ?? '';
    var document = html_parser.parse(html);

    final refresh = document.querySelector("meta[http-equiv='refresh']");
    final migrationUrl = refresh == null
        ? null
        : _migrationUrlRegex.firstMatch(refresh.outerHtml)?.group(0) ??
              _migrationUrlRegex.firstMatch(html)?.group(0);
    if (migrationUrl != null) {
      logger.i('Following X migration redirect.');
      response = await _dio.get<String>(migrationUrl);
      html = response.data ?? '';
      document = html_parser.parse(html);
    }

    final form =
        document.querySelector("form[name='f']") ??
        document.querySelector("form[action='https://x.com/x/migrate']");
    if (form != null) {
      final action = form.attributes['action'] ?? 'https://x.com/x/migrate';
      final values = <String, String>{
        for (final input in form.querySelectorAll('input'))
          if (input.attributes['name'] case final String name)
            name: input.attributes['value'] ?? '',
      };
      final method = (form.attributes['method'] ?? 'POST').toUpperCase();
      logger.i('Submitting X migration form.');
      response = method == 'POST'
          ? await _dio.post<String>(
              action,
              data: values,
              options: Options(contentType: Headers.formUrlEncodedContentType),
            )
          : await _dio.get<String>(action, queryParameters: values);
      html = response.data ?? '';
    }
    return html;
  }

  Future<XClientTransactionService> fetchService() async {
    try {
      final homePage = await _fetchHomePage();
      final ondemandUrl = _getOndemandUrlFromHtml(homePage);
      if (ondemandUrl == null) {
        throw StateError(
          'Unable to find the ondemand script URL on X home page.',
        );
      }
      final response = await _dio.get<String>(ondemandUrl);
      final script = response.data;
      if (script == null || script.isEmpty) {
        throw StateError('X ondemand script response was empty.');
      }
      return XClientTransactionService(
        homePageHtml: homePage,
        ondemandJsText: script,
      );
    } on DioException catch (error, stackTrace) {
      logger.w(
        'Unable to fetch X transaction-id resources: ${error.message}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<String?> fetchAndGenerateTransactionId({
    required String method,
    required String url,
  }) async {
    try {
      return (await fetchService()).generateTransactionId(
        method: method,
        url: url,
      );
    } catch (error, stackTrace) {
      logger.w(
        'Unable to generate X transaction ID: $error',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}

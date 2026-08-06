import 'dart:async';
import 'dart:isolate';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class JsonParseWorker {
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _mainReceive = ReceivePort();
  final Map<int, Completer<List<Map<String, dynamic>>>> _completers = {};
  int _nextId = 0;
  bool _initializing = false;

  // singleton
  static final JsonParseWorker instance = JsonParseWorker._();
  JsonParseWorker._();

  Future<void> initIfNeeded() async {
    if (_sendPort != null) return;
    if (_initializing) {
      // wait until ready
      while (_sendPort == null) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
      return;
    }
    _initializing = true;

    final completer = Completer<void>();
    final rp = ReceivePort();
    rp.listen((message) {
      // first message should be the worker's SendPort
      if (message is SendPort) {
        _sendPort = message;
        // listen for responses from worker
        _mainReceive.listen(_handleMessageFromWorker);
        completer.complete();
      }
    });

    _isolate = await Isolate.spawn<_IsolateInitMessage>(
      _isolateEntry,
      _IsolateInitMessage(rp.sendPort, _mainReceive.sendPort),
      // errors and exit handling can be added if needed
    );
    await completer.future;
    _initializing = false;
  }

  Future<List<Map<String, dynamic>>> parseBatch(
    List<Map<String, dynamic>> items,
  ) async {
    // items: each item is a small map with keys:
    // 'userId','dbScreenName','dbName','dbAvatarUrl','dbAvatarLocalPath','dbBannerLocalPath','dbBio','jsonString'
    // We will encode as JSON bytes and wrap in TransferableTypedData to avoid copying large strings.
    await initIfNeeded();

    final id = _nextId++;
    final completer = Completer<List<Map<String, dynamic>>>();
    _completers[id] = completer;

    final jsonString = jsonEncode(items);
    final bytes = utf8.encode(jsonString);
    final ttd = TransferableTypedData.fromList([Uint8List.fromList(bytes)]);

    // send [id, TransferableTypedData, replyPort]
    _sendPort!.send([id, ttd, _mainReceive.sendPort]);

    return completer.future;
  }

  void _handleMessageFromWorker(dynamic message) {
    // expected: [id, List<Map<String,dynamic>>] or [id, {error: ...}]
    if (message is List && message.length == 2) {
      final id = message[0] as int;
      final completer = _completers.remove(id);
      if (completer == null) return;

      final payload = message[1];
      if (payload is Map && payload['error'] != null) {
        completer.completeError(FormatException(payload['error'].toString()));
        return;
      }
      if (payload is! List) {
        completer.completeError(
          const FormatException('Invalid JSON parser worker response.'),
        );
        return;
      }

      final typed = payload
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      completer.complete(typed);
    }
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _sendPort = null;
    _mainReceive.close();
    _completers.clear();
  }
}

class _IsolateInitMessage {
  final SendPort replyToMain;
  final SendPort
  mainReplyPort; // not used in this basic setup but passed for extensibility
  _IsolateInitMessage(this.replyToMain, this.mainReplyPort);
}

void _isolateEntry(_IsolateInitMessage initMsg) {
  final workerReceive = ReceivePort();
  // send the worker's sendPort back to main isolate
  initMsg.replyToMain.send(workerReceive.sendPort);

  workerReceive.listen((message) {
    // message: [id, TransferableTypedData, replyPort]
    if (message is List && message.length == 3) {
      final int id = message[0] as int;
      final TransferableTypedData ttd = message[1] as TransferableTypedData;
      final SendPort replyPort = message[2] as SendPort;

      try {
        final bytes = ttd.materialize().asUint8List();
        final jsonString = utf8.decode(bytes);
        final list = jsonDecode(jsonString) as List<dynamic>;

        // Parse each persisted user snapshot. A damaged or absent snapshot is
        // not replaced with synthetic fields: doing so creates misleading zero
        // counts in analysis results.
        final List<Map<String, dynamic>> results = [];

        for (final raw in list) {
          final Map<String, dynamic> item = Map<String, dynamic>.from(
            raw as Map,
          );
          final String? nestedJson = item['jsonString'] as String?;
          if (nestedJson == null || nestedJson.isEmpty) {
            throw FormatException(
              'Missing persisted JSON for user ${item['userId']}.',
            );
          }
          final decoded = jsonDecode(nestedJson);
          if (decoded is! Map) {
            throw FormatException(
              'Persisted JSON for user ${item['userId']} is not an object.',
            );
          }
          final jsonMap = Map<String, dynamic>.from(decoded);
          // Inject local paths using snake_case keys the rest of the app expects.
          if (item['dbAvatarLocalPath'] != null) {
            jsonMap['avatar_local_path'] = item['dbAvatarLocalPath'];
          }
          if (item['dbBannerLocalPath'] != null) {
            jsonMap['banner_local_path'] = item['dbBannerLocalPath'];
          }
          results.add(jsonMap);
        }

        // send back [id, results]
        replyPort.send([id, results]);
      } catch (e) {
        replyPort.send([
          id,
          {'error': e.toString()},
        ]);
      }
    }
  });
}

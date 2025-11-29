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
    // expected: [id, List<Map<String,dynamic>>]
    if (message is List && message.length == 2) {
      final id = message[0] as int;
      final payload = message[1] as List<dynamic>;
      final completer = _completers.remove(id);
      if (completer != null) {
        // ensure proper typing
        final typed = payload
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        completer.complete(typed);
      }
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

        // For each item, parse the nested jsonString if present, inject local paths,
        // and return a simple Map representing the final user JSON (or fallback minimal fields)
        final List<Map<String, dynamic>> results = [];

        for (final raw in list) {
          final Map<String, dynamic> item = Map<String, dynamic>.from(
            raw as Map,
          );
          final String? nestedJson = item['jsonString'] as String?;
          if (nestedJson != null && nestedJson.isNotEmpty) {
            try {
              final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(
                jsonDecode(nestedJson) as Map,
              );
              // inject local paths using snake_case keys the rest of your code expects
              if (item['dbAvatarLocalPath'] != null) {
                jsonMap['avatar_local_path'] = item['dbAvatarLocalPath'];
              }
              if (item['dbBannerLocalPath'] != null) {
                jsonMap['banner_local_path'] = item['dbBannerLocalPath'];
              }
              results.add(jsonMap);
              continue;
            } catch (e) {
              // fallthrough to fallback minimal map
            }
          }
          // fallback minimal map if json absent/corrupted
          results.add({
            'restId': item['userId'],
            'screenName': item['dbScreenName'],
            'name': item['dbName'],
            'avatarUrl': item['dbAvatarUrl'],
            'avatarLocalPath': item['dbAvatarLocalPath'],
            'bannerLocalPath': item['dbBannerLocalPath'],
            'bio': item['dbBio'],
          });
        }

        // send back [id, results]
        replyPort.send([id, results]);
      } catch (e) {
        // on unexpected error send empty list to avoid deadlock (you may prefer to send error)
        replyPort.send([id, <Map<String, dynamic>>[]]);
      }
    }
  });
}

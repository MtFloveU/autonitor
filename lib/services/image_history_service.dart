import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../main.dart';
import '../models/app_settings.dart';
import '../services/database.dart';
import 'log_service.dart';

final imageHistoryServiceProvider = Provider<ImageHistoryService>((ref) {
  final db = ref.watch(databaseProvider);
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  return ImageHistoryService(db, dio);
});

enum MediaType { avatar, banner }

const String _kMediaHistoryDirName = 'media_history';

class ImageHistoryService {
  final AppDatabase _db;
  final Dio _dio;
  String? _basePath;

  ImageHistoryService(this._db, this._dio);

  Future<String> _getMediaHistoryPath() async {
    if (_basePath != null) return _basePath!;

    final supportDir = await getApplicationSupportDirectory();
    final mediaDir = Directory(p.join(supportDir.path, _kMediaHistoryDirName));

    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    _basePath = mediaDir.path;
    return _basePath!;
  }

  Future<bool> _downloadImage(String url, String savePath) async {
    try {
      await _dio.download(url, savePath, options: Options());
      return true;
    } on DioException catch (e) {
      logger.e("Image download failed for $url: ${e.message}", error: e);
      try {
        final file = File(savePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      return false;
    } catch (e, s) {
      logger.e("Unknown error downloading $url", error: e, stackTrace: s);
      try {
        final file = File(savePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        logger.w("Failed to delete partially downloaded file at $savePath");
      }
      return false;
    }
  }

  Future<String?> processMediaUpdate({
    required String userId,
    required String ownerId,
    required MediaType mediaType,
    required String? oldUrl,
    required String? newUrl,
    required AppSettings settings,
  }) async {
    String? effectiveNewUrl = newUrl;
    String? effectiveOldUrl = oldUrl;
    const String suffixRegex = r'_(normal|bigger|400x400)';

    if (mediaType == MediaType.avatar) {
      if (settings.avatarQuality == AvatarQuality.low) {
        if (effectiveNewUrl != null) {
          effectiveNewUrl = effectiveNewUrl.replaceFirst(
            RegExp(suffixRegex),
            '_bigger',
          );
        }
        if (effectiveOldUrl != null) {
          effectiveOldUrl = effectiveOldUrl.replaceFirst(
            RegExp(suffixRegex),
            '_bigger',
          );
        }
      } else {
        if (effectiveNewUrl != null) {
          effectiveNewUrl = effectiveNewUrl.replaceFirst(
            RegExp(suffixRegex),
            '_400x400',
          );
        }
        if (effectiveOldUrl != null) {
          effectiveOldUrl = effectiveOldUrl.replaceFirst(
            RegExp(suffixRegex),
            '_400x400',
          );
        }
      }
    }

    final bool shouldSave =
        (mediaType == MediaType.avatar && settings.saveAvatarHistory) ||
        (mediaType == MediaType.banner && settings.saveBannerHistory);
    if (!shouldSave) return null;
    if (effectiveNewUrl == null || effectiveNewUrl.isEmpty) {
      return null;
    }

    logger.i("Change detected for $userId ($mediaType): $effectiveNewUrl");

    final basePath = await _getMediaHistoryPath();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileExtension = p
        .extension(effectiveNewUrl.split('?').first)
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    String qualitySuffix = '';
    if (mediaType == MediaType.avatar) {
      // 仅为头像添加质量后缀
      qualitySuffix = (settings.avatarQuality == AvatarQuality.high)
          ? '_high'
          : '_low';
    }
    final fileName =
        '${ownerId}_${userId}_${mediaType.name}_$timestamp$qualitySuffix${fileExtension.isNotEmpty ? fileExtension : '.jpg'}';
    final absoluteSavePath = p.join(basePath, fileName);

    final success = await _downloadImage(effectiveNewUrl, absoluteSavePath);

    if (!success) {
      logger.w("Failed to download $effectiveNewUrl. Aborting history save.");
      return null;
    }

    final relativeFilePath = p.join(_kMediaHistoryDirName, fileName);

    final historyCompanion = MediaHistoryCompanion(
      userId: Value(userId),
      mediaType: Value(mediaType.name),
      localFilePath: Value(relativeFilePath),
      remoteUrl: Value(effectiveNewUrl),
      timestamp: Value(DateTime.now()),
    );
    await _db.insertMediaHistory(historyCompanion);

    // 6. TODO: 在这里实现“清理策略” (saveLatest, saveLastN)

    return relativeFilePath;
  }
}

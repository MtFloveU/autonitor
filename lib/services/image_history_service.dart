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

  Future<String?> saveMediaIfNotExists({
  required String remoteUrl,
  required MediaType mediaType,
  required bool isHighQuality,
}) async {
  if (remoteUrl.isEmpty) return null;

  // 1. 数据库检查
  final exists = await hasMediaWithUrl(remoteUrl);

  if (exists) {
    // 已有这个 remoteUrl，不需要下载
    return null;
  }

  // 2. 计算保存路径
  final basePath = await _getMediaHistoryPath();
  final hash = remoteUrl.hashCode.toUnsigned(32);
  final ext = p.extension(remoteUrl.split('?').first);
  final fileName = '${mediaType.name}_${hash}${ext.isNotEmpty ? ext : ".jpg"}';
  final absolutePath = p.join(basePath, fileName);

  // 3. 下载文件
  final success = await _downloadImage(remoteUrl, absolutePath);
  if (!success) return null;

  // 4. 写入数据库
  final relativePath = p.join(_kMediaHistoryDirName, fileName);
  await _db.into(_db.mediaHistory).insert(
        MediaHistoryCompanion.insert(
          mediaType: mediaType.name,
          localFilePath: relativePath,
          remoteUrl: remoteUrl,
          isHighQuality: Value(isHighQuality),
        ),
      );

  return relativePath;
}


  Future<bool> hasMediaWithUrl(String remoteUrl) async {
  final query = await (_db.select(_db.mediaHistory)
        ..where((tbl) => tbl.remoteUrl.equals(remoteUrl)))
      .get();

  return query.isNotEmpty;
}


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
      mediaType: Value(mediaType.name),
      localFilePath: Value(relativeFilePath),
      remoteUrl: Value(effectiveNewUrl),
      isHighQuality: Value(
        mediaType == MediaType.avatar &&
            settings.avatarQuality == AvatarQuality.high,
      ),
    );
    await _db.insertMediaHistory(historyCompanion);

    // 6. TODO: 在这里实现“清理策略” (saveLatest, saveLastN)

    return relativeFilePath;
  }

  Future<MediaHistoryEntry?> getMediaRecord(String remoteUrl) async {
  final query = await (_db.select(_db.mediaHistory)
        ..where((tbl) => tbl.remoteUrl.equals(remoteUrl)))
      .getSingleOrNull();
  return query;
}

Future<String?> downloadAndSave({
  required String remoteUrl,
  required MediaType mediaType,
  required bool isHighQuality,
}) async {
  if (remoteUrl.isEmpty) return null;

  // 处理头像 URL 后缀
  String effectiveUrl = remoteUrl;
  if (mediaType == MediaType.avatar) {
    const String suffixRegex = r'_(normal|bigger|400x400)';
    effectiveUrl = isHighQuality
        ? remoteUrl.replaceFirst(RegExp(suffixRegex), '_400x400')
        : remoteUrl.replaceFirst(RegExp(suffixRegex), '_bigger');
  }

  // 计算文件名（同一个 URL 只有一个文件，覆盖低质量）
  final basePath = await _getMediaHistoryPath();
  final hash = remoteUrl.hashCode.toUnsigned(32); // 用原始 URL 哈希
  final ext = p.extension(remoteUrl.split('?').first).isNotEmpty
      ? p.extension(remoteUrl.split('?').first)
      : ".jpg";
  final fileName = '${mediaType.name}_${hash}${ext}';
  final absolutePath = p.join(basePath, fileName);

  // 下载图片（覆盖旧文件）
  final file = File(absolutePath);
  if (await file.exists()) {
    await file.delete();
  }

  final success = await _downloadImage(effectiveUrl, absolutePath);
  if (!success) return null;

  // 更新数据库，存储原始 URL，不存替换后的 URL
  final relativePath = p.join(_kMediaHistoryDirName, fileName);
  final existingRecord = await getMediaRecord(remoteUrl);
  final historyCompanion = MediaHistoryCompanion(
    id: existingRecord != null ? Value(existingRecord.id) : Value.absent(),
    mediaType: Value(mediaType.name),
    localFilePath: Value(relativePath),
    remoteUrl: Value(remoteUrl), // 使用原始 URL
    isHighQuality: Value(isHighQuality),
  );

  if (existingRecord != null) {
    await _db.update(_db.mediaHistory).replace(historyCompanion);
  } else {
    await _db.into(_db.mediaHistory).insert(historyCompanion);
  }

  return relativePath;
}


}

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
    final fileName = '${mediaType.name}_$hash${ext.isNotEmpty ? ext : ".jpg"}';
    final absolutePath = p.join(basePath, fileName);

    // 3. 下载文件
    final success = await _downloadImage(remoteUrl, absolutePath);
    if (!success) return null;

    // 4. 写入数据库
    final relativePath = p.join(_kMediaHistoryDirName, fileName);
    await _db
        .into(_db.mediaHistory)
        .insert(
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
    final query = await (_db.select(
      _db.mediaHistory,
    )..where((tbl) => tbl.remoteUrl.equals(remoteUrl))).get();

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
    // 1. 基础校验
    if (newUrl == null || newUrl.isEmpty) return null;

    final bool shouldSave =
        (mediaType == MediaType.avatar && settings.saveAvatarHistory) ||
        (mediaType == MediaType.banner && settings.saveBannerHistory);
    if (!shouldSave) return null;

    // 2. 确定是否需要高质量
    // Banner 始终高质量；Avatar 根据设置决定
    final bool wantHighQuality =
        (mediaType == MediaType.banner) ||
        (mediaType == MediaType.avatar &&
            settings.avatarQuality == AvatarQuality.high);

    // [核心修复] 3. 使用【原始 URL】检查数据库
    // 这样能确保我们用的是最稳定的 Key，与 downloadAndSave 逻辑保持一致
    final existingRecord = await getMediaRecord(newUrl);

    if (existingRecord != null) {
      // --- 修改开始：增加文件存在性检查 ---

      // 1. 构造绝对路径以检查文件
      final supportDir = await getApplicationSupportDirectory();
      final checkPath = p.join(supportDir.path, existingRecord.localFilePath);
      final fileExists = await File(checkPath).exists();

      if (fileExists) {
        // 只有当文件真的存在时，才允许跳过下载
        // 3a. 检查是否需要升级画质
        if (!(wantHighQuality && !existingRecord.isHighQuality)) {
          // 画质满足且文件存在 -> 不需要更新，直接返回
          return existingRecord.localFilePath;
        }
        // 需要升级画质 -> 继续向下执行下载
      } else {
        // 数据库有记录，但文件没了 -> 记录日志，并继续向下执行以重新下载
        logger.w(
          "Found DB record for $userId but file missing at $checkPath. Forcing re-download.",
        );
      }
    }

    // 4. 计算实际下载用的 URL (Effective URL)
    String effectiveNewUrl = newUrl;
    const String suffixRegex = r'_(normal|bigger|400x400)';

    if (mediaType == MediaType.avatar) {
      if (settings.avatarQuality == AvatarQuality.low) {
        effectiveNewUrl = newUrl.replaceFirst(RegExp(suffixRegex), '_bigger');
      } else {
        effectiveNewUrl = newUrl.replaceFirst(RegExp(suffixRegex), '_400x400');
      }
    }

    logger.i(
      "Downloading new media for $userId ($mediaType) [Upgrade: ${existingRecord != null}]: $effectiveNewUrl",
    );

    // 5. 确定保存路径
    String relativeFilePath;
    String absoluteSavePath;

    if (existingRecord != null) {
      // [优化] 如果记录存在（只是画质升级），复用旧路径，覆盖旧文件
      // 注意：existingRecord.localFilePath 是相对路径 (e.g. "media_history/xxx.jpg")
      relativeFilePath = existingRecord.localFilePath;

      final supportDir = await getApplicationSupportDirectory();
      absoluteSavePath = p.join(supportDir.path, relativeFilePath);
    } else {
      // [新建] 生成新路径
      final basePath = await _getMediaHistoryPath();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = p
          .extension(newUrl.split('?').first)
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

      // 文件名格式：ownerId_userId_type_timestamp.jpg
      final fileName =
          '${ownerId}_${userId}_${mediaType.name}_$timestamp${fileExtension.isNotEmpty ? fileExtension : '.jpg'}';

      absoluteSavePath = p.join(basePath, fileName);
      relativeFilePath = p.join(_kMediaHistoryDirName, fileName);
    }

    // 6. 执行下载
    final success = await _downloadImage(effectiveNewUrl, absoluteSavePath);

    if (!success) {
      logger.w("Failed to download $effectiveNewUrl.");
      // 如果是升级失败，虽然新图没下来，但旧图可能还在（或者是坏的），
      // 为了安全起见，如果下载失败，我们返回 null 或者旧路径？
      // 这里选择返回 null 表示本次更新操作没能获取到新资源
      return existingRecord?.localFilePath;
    }

    // 7. 更新/插入数据库
    // [核心修复] 存储【原始 URL】(newUrl)，并更新 isHighQuality 标志
    final historyCompanion = MediaHistoryCompanion(
      id: existingRecord != null
          ? Value(existingRecord.id)
          : const Value.absent(),
      mediaType: Value(mediaType.name),
      localFilePath: Value(relativeFilePath),
      remoteUrl: Value(newUrl), // 存原始 URL !!!
      isHighQuality: Value(wantHighQuality),
    );

    if (existingRecord != null) {
      await _db.update(_db.mediaHistory).replace(historyCompanion);
    } else {
      await _db.insertMediaHistory(historyCompanion);
    }

    return relativeFilePath;
  }

  Future<void> deduplicateMediaHistory() async {
    await _db.customStatement('''
    DELETE FROM media_history 
    WHERE id NOT IN (
      SELECT MAX(id) 
      FROM media_history 
      GROUP BY remote_url
    )
  ''');
  }

  Future<MediaHistoryEntry?> getMediaRecord(String remoteUrl) async {
    return (_db.select(_db.mediaHistory)
          ..where((tbl) => tbl.remoteUrl.equals(remoteUrl))
          ..orderBy([
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
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
    final fileName = '${mediaType.name}_$hash$ext';
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

import 'package:async/async.dart';
import 'package:async_locks/async_locks.dart';
import 'package:autonitor/models/twitter_user.dart';
import '../models/app_settings.dart';
import '../services/database.dart';
import '../services/image_history_service.dart';

typedef LogCallback = void Function(String message);

// 数据类，保存处理结果
class MediaProcessingResult {
  final Map<String, Map<MediaType, String>> downloadedPaths;

  MediaProcessingResult({required this.downloadedPaths});
}

class MediaProcessor {
  final ImageHistoryService _imageService;
  final AppSettings _settings;
  final LogCallback _log;

  MediaProcessor({
    required ImageHistoryService imageService,
    required AppSettings settings,
    required String ownerId,
    required LogCallback log,
  }) : _imageService = imageService,
       _settings = settings,
       _log = log;

  Future<MediaProcessingResult> processMedia({
    required Map<String, TwitterUser> newUsers,
    required Map<String, FollowUser> oldRelations,
  }) async {
    final List<Map<String, dynamic>> downloadTasks = [];

    for (final userId in newUsers.keys) {
      final userObj = newUsers[userId]!;

      // --- Avatar ---
      final String? avatarUrl = userObj.avatarUrl;
      if (avatarUrl != null &&
          avatarUrl.isNotEmpty &&
          _settings.saveAvatarHistory) {
        downloadTasks.add({
          'userId': userId,
          'remoteUrl': avatarUrl,
          'mediaType': MediaType.avatar,
          'isHighQuality': _settings.avatarQuality == AvatarQuality.high,
        });
      }

      // --- Banner ---
      final String? bannerUrl = userObj.bannerUrl;
      if (bannerUrl != null &&
          bannerUrl.isNotEmpty &&
          _settings.saveBannerHistory) {
        downloadTasks.add({
          'userId': userId,
          'remoteUrl': bannerUrl,
          'mediaType': MediaType.banner,
          'isHighQuality': true, // 横幅无需区分质量
        });
      }
    }

    return _runDownloadTasks(downloadTasks);
  }

  Future<MediaProcessingResult> _runDownloadTasks(
    List<Map<String, dynamic>> downloadTasks,
  ) async {
    final int totalToDownload = downloadTasks.length;
    _log("Found $totalToDownload media items to download.");

    if (totalToDownload == 0) {
      return MediaProcessingResult(downloadedPaths: {});
    }

    final group = FutureGroup<Map<String, dynamic>?>();
    final semaphore = Semaphore(50);
    int completed = 0;
    final counterLock = Semaphore(1);

    for (final task in downloadTasks) {
      final String userId = task['userId']!;
      final String remoteUrl = task['remoteUrl']!;
      final MediaType mediaType = task['mediaType']!;
      final bool isHighQuality = task['isHighQuality']!;

      group.add(
        Future(() async {
          await semaphore.acquire();
          try {
            final existingRecord = await _imageService.getMediaRecord(
              remoteUrl,
            );
            String? localPath;

            if (existingRecord != null) {
              if (!existingRecord.isHighQuality && isHighQuality) {
                // 已存在低质量，当前请求高质量 -> 覆盖下载
                localPath = await _imageService.downloadAndSave(
                  remoteUrl: remoteUrl,
                  mediaType: mediaType,
                  isHighQuality: true,
                );
              } else {
                // 已存在高质量或低质量不需要覆盖 -> 使用现有路径
                localPath = existingRecord.localFilePath;
              }
            } else {
              // 没有记录 -> 正常下载
              localPath = await _imageService.downloadAndSave(
                remoteUrl: remoteUrl,
                mediaType: mediaType,
                isHighQuality: isHighQuality,
              );
            }

            if (localPath != null) {
              await counterLock.acquire();
              completed++;
              _log("Download progress: $completed / $totalToDownload");
              counterLock.release();
              return {'userId': userId, 'type': mediaType, 'path': localPath};
            }
          } catch (e) {
            _log("Failed to download media for $userId: $e");
          } finally {
            semaphore.release();
          }
          return null;
        }),
      );
    }

    group.close();
    final results = await group.future;

    final Map<String, Map<MediaType, String>> downloadedPaths = {};
    for (final result in results) {
      if (result != null) {
        final String userId = result['userId'];
        final MediaType type = result['type'];
        final String path = result['path'];

        downloadedPaths.putIfAbsent(userId, () => {});
        downloadedPaths[userId]![type] = path;
      }
    }

    _log(
      "Finished downloading ${results.where((r) => r != null).length} items.",
    );

    return MediaProcessingResult(downloadedPaths: downloadedPaths);
  }
}

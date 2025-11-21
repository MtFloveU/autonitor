import 'package:async/async.dart';
import 'package:async_locks/async_locks.dart';
import '../models/app_settings.dart';
import '../services/database.dart'; // 为了 FollowUser (如果还用到)
import '../services/image_history_service.dart';
import '../models/twitter_user.dart'; // [新增]

typedef LogCallback = void Function(String message);

// 数据类，保存处理结果
class MediaProcessingResult {
  // 包含所有用户的媒体路径（无论是新下载的还是数据库已有的）
  final Map<String, Map<MediaType, String>> downloadedPaths;
  final int newDownloadCount;

  MediaProcessingResult({
    required this.downloadedPaths,
    required this.newDownloadCount,
  });
}

// 内部辅助类：下载候选任务
class _MediaCandidate {
  final String userId;
  final String remoteUrl;
  final MediaType mediaType;
  final bool isHighQuality;

  _MediaCandidate({
    required this.userId,
    required this.remoteUrl,
    required this.mediaType,
    required this.isHighQuality,
  });
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
    // [修改] 适配 TwitterUser
    required Map<String, TwitterUser> newUsers,
    required Map<String, FollowUser> oldRelations,
  }) async {
    final List<_MediaCandidate> candidates = [];

    // 1. 收集所有潜在的媒体任务
    for (final userId in newUsers.keys) {
      final user = newUsers[userId]!;

      // --- Avatar ---
      if (user.avatarUrl != null &&
          user.avatarUrl!.isNotEmpty &&
          _settings.saveAvatarHistory) {
        candidates.add(
          _MediaCandidate(
            userId: userId,
            remoteUrl: user.avatarUrl!,
            mediaType: MediaType.avatar,
            isHighQuality: _settings.avatarQuality == AvatarQuality.high,
          ),
        );
      }

      // --- Banner ---
      if (user.bannerUrl != null &&
          user.bannerUrl!.isNotEmpty &&
          _settings.saveBannerHistory) {
        candidates.add(
          _MediaCandidate(
            userId: userId,
            remoteUrl: user.bannerUrl!,
            mediaType: MediaType.banner,
            isHighQuality: true, // 横幅默认高质量
          ),
        );
      }
    }

    // 2. 执行筛选和下载
    return _processCandidates(candidates);
  }

  Future<MediaProcessingResult> _processCandidates(
    List<_MediaCandidate> candidates,
  ) async {
    _log("Checking status for media items...");

    final Map<String, Map<MediaType, String>> finalPaths = {};
    final List<_MediaCandidate> toDownload = [];

    // --- 阶段 A: 并发检查数据库 (Filter Phase) ---
    final checkSemaphore = Semaphore(50); // 限制并发查库数
    final checkGroup = FutureGroup<void>();

    for (final candidate in candidates) {
      checkGroup.add(
        Future(() async {
          await checkSemaphore.acquire();
          try {
            final existing = await _imageService.getMediaRecord(
              candidate.remoteUrl,
            );
            bool needsDownload = true;

            if (existing != null) {
              // 如果已存在，检查是否需要升级画质
              if (!existing.isHighQuality && candidate.isHighQuality) {
                needsDownload = true; // 需要升级 -> 加入下载队列
              } else {
                needsDownload = false; // 不需要下载 -> 直接使用现有路径
                _addPathToResult(
                  finalPaths,
                  candidate.userId,
                  candidate.mediaType,
                  existing.localFilePath,
                );
              }
            }

            if (needsDownload) {
              toDownload.add(candidate);
            }
          } finally {
            checkSemaphore.release();
          }
        }),
      );
    }

    checkGroup.close();
    await checkGroup.future;

    // --- 阶段 B: 执行下载 (Download Phase) ---
    _log("Found ${toDownload.length} new media items to download.");

    if (toDownload.isEmpty) {
      return MediaProcessingResult(
        downloadedPaths: finalPaths,
        newDownloadCount: 0,
      );
    }

    final downloadSemaphore = Semaphore(20); // 限制并发下载数
    final downloadGroup = FutureGroup<void>();
    int completed = 0;
    final counterLock = Semaphore(1); // 简单的计数锁

    for (final task in toDownload) {
      downloadGroup.add(
        Future(() async {
          await downloadSemaphore.acquire();
          try {
            // 执行实际下载逻辑
            final localPath = await _imageService.downloadAndSave(
              remoteUrl: task.remoteUrl,
              mediaType: task.mediaType,
              isHighQuality: task.isHighQuality,
            );

            if (localPath != null) {
              _addPathToResult(
                finalPaths,
                task.userId,
                task.mediaType,
                localPath,
              );

              // 更新进度日志
              await counterLock.acquire();
              completed++;
              _log("Download progress: $completed / ${toDownload.length}");

              counterLock.release();
            }
          } catch (e) {
            _log("Failed to download media for ${task.userId}: $e");
          } finally {
            downloadSemaphore.release();
          }
        }),
      );
    }

    downloadGroup.close();
    await downloadGroup.future;

    _log("Finished processing media.");
    return MediaProcessingResult(
      downloadedPaths: finalPaths,
      newDownloadCount: completed,
    );
  }

  // 线程安全的 Map 写入辅助方法（在 Dart 单线程模型下，非 await 间隙是安全的）
  void _addPathToResult(
    Map<String, Map<MediaType, String>> paths,
    String userId,
    MediaType type,
    String path,
  ) {
    paths.putIfAbsent(userId, () => {});
    paths[userId]![type] = path;
  }
}

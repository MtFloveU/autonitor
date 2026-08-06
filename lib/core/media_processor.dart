import 'package:async/async.dart';
import 'package:async_locks/async_locks.dart';
import '../models/app_settings.dart';
import '../services/database.dart';
import '../services/image_history_service.dart';
import '../models/sync_progress.dart';
import '../models/twitter_user.dart';

typedef LogCallback = void Function(String message);

class MediaProcessingResult {
  final Map<String, Map<MediaType, String>> downloadedPaths;
  final int newDownloadCount;

  MediaProcessingResult({
    required this.downloadedPaths,
    required this.newDownloadCount,
  });
}

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
  final Future<void> Function() _checkPauseCallback;
  final SyncProgressCallback? _onProgress;

  // 每提交多少个 Future 后向事件循环让一次宏任务时间片。
  // await _checkPauseCallback() 是微任务让步（不触发 vsync），
  // Future.delayed(Duration.zero) 是宏任务让步（允许 Flutter 处理帧/输入）。
  static const int _submitBatchSize = 50;

  MediaProcessor({
    required ImageHistoryService imageService,
    required AppSettings settings,
    required String ownerId,
    required LogCallback log,
    required Future<void> Function() checkPauseCallback,
    SyncProgressCallback? onProgress,
  }) : _imageService = imageService,
       _settings = settings,
       _log = log,
       _checkPauseCallback = checkPauseCallback,
       _onProgress = onProgress;

  Future<MediaProcessingResult> processMedia({
    required Map<String, TwitterUser> newUsers,
    required Map<String, FollowUser> oldRelations,
    required Set<String> followerIds,
    required Set<String> followingIds,
  }) async {
    final List<_MediaCandidate> candidates = [];

    for (final userId in newUsers.keys) {
      final user = newUsers[userId]!;
      final shouldSaveMedia = switch (_settings.mediaSaveScope) {
        MediaSaveScope.all => true,
        MediaSaveScope.followingOnly => followingIds.contains(userId),
        MediaSaveScope.mutualOnly =>
          followerIds.contains(userId) && followingIds.contains(userId),
      };
      if (!shouldSaveMedia) continue;

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

      if (user.bannerUrl != null &&
          user.bannerUrl!.isNotEmpty &&
          _settings.saveBannerHistory) {
        candidates.add(
          _MediaCandidate(
            userId: userId,
            remoteUrl: user.bannerUrl!,
            mediaType: MediaType.banner,
            isHighQuality: true,
          ),
        );
      }
    }

    return _processCandidates(candidates);
  }

  Future<MediaProcessingResult> _processCandidates(
    List<_MediaCandidate> candidates,
  ) async {
    _log("Checking status for ${candidates.length} media items...");
    _onProgress?.call(
      SyncProgress(
        stage: SyncStage.downloadingMedia,
        step: SyncStep.checkingMedia,
        completedItems: 0,
        totalItems: candidates.length,
      ),
    );

    final Map<String, Map<MediaType, String>> finalPaths = {};
    final List<_MediaCandidate> toDownload = [];
    var checked = 0;

    // ── 阶段 A：并发 DB 检查 ──────────────────────────────────────────────
    final checkSemaphore = Semaphore(50);
    final checkGroup = FutureGroup<void>();

    for (int i = 0; i < candidates.length; i++) {
      await _checkPauseCallback();

      final candidate = candidates[i];
      checkGroup.add(
        Future(() async {
          await checkSemaphore.acquire();
          try {
            final existing = await _imageService.getMediaRecord(
              candidate.remoteUrl,
            );
            if (existing != null &&
                (existing.isHighQuality || !candidate.isHighQuality) &&
                await _imageService.localMediaExists(existing.localFilePath)) {
              // 已有且无需升级画质，直接复用
              _addPathToResult(
                finalPaths,
                candidate.userId,
                candidate.mediaType,
                existing.localFilePath,
              );
            } else {
              if (existing != null) {
                _log(
                  'Media cache record exists but its file is unavailable; retrying ${candidate.remoteUrl}.',
                );
              }
              toDownload.add(candidate);
            }
            checked++;
            _onProgress?.call(
              SyncProgress(
                stage: SyncStage.downloadingMedia,
                step: SyncStep.checkingMedia,
                completedItems: checked,
                totalItems: candidates.length,
              ),
            );
          } finally {
            checkSemaphore.release();
          }
        }),
      );

      // 修复 1：每提交 _submitBatchSize 个 Future 后 yield 一次宏任务时间片。
      // Future.delayed(Duration.zero) 经 Timer 调度，优先级低于微任务队列，
      // 能让 Flutter 引擎处理 vsync / 触摸事件，彻底解决 UI 无响应问题。
      // 对照：await _checkPauseCallback() 仅让步微任务，不能触发 vsync。
      if ((i + 1) % _submitBatchSize == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    checkGroup.close();
    await checkGroup.future;

    // ── 阶段 B：并发下载 ──────────────────────────────────────────────────
    _log("Found ${toDownload.length} new media items to download.");
    _onProgress?.call(
      SyncProgress(
        stage: SyncStage.downloadingMedia,
        step: SyncStep.downloadingMedia,
        completedItems: 0,
        totalItems: toDownload.length,
      ),
    );

    if (toDownload.isEmpty) {
      return MediaProcessingResult(
        downloadedPaths: finalPaths,
        newDownloadCount: 0,
      );
    }

    final downloadSemaphore = Semaphore(20);
    final downloadGroup = FutureGroup<void>();

    // 修复 2：移除 counterLock（Semaphore(1)）。
    // Dart 是单线程的，两个 await 之间的代码段天然是原子的。
    // completed++ 和 _log() 都发生在同步窗口内，其他协程无法插入，
    // 完全不需要互斥锁，白加两次异步状态机跳转（acquire + release）。
    int completed = 0;
    int finishedDownloads = 0;

    for (int i = 0; i < toDownload.length; i++) {
      await _checkPauseCallback();

      final task = toDownload[i];
      downloadGroup.add(
        Future(() async {
          await downloadSemaphore.acquire();
          try {
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
              // 安全：同步递增，await downloadAndSave() 已返回，
              // 当前执行到此处时无其他协程可抢占
              completed++;
              _log("Download progress: $completed / ${toDownload.length}");
            }
          } catch (e) {
            _log("Failed to download media for ${task.userId}: $e");
          } finally {
            finishedDownloads++;
            _onProgress?.call(
              SyncProgress(
                stage: SyncStage.downloadingMedia,
                step: SyncStep.downloadingMedia,
                completedItems: finishedDownloads,
                totalItems: toDownload.length,
                currentItemName: _displayName(task.remoteUrl),
              ),
            );
            downloadSemaphore.release();
            // A completed download can trigger many more queued callbacks at
            // once. Yield a macrotask after each progress update so Flutter
            // can process a frame and user input before this worker continues.
            await Future<void>.delayed(Duration.zero);
          }
        }),
      );

      // 同阶段 A，每批提交后 yield 一次宏任务时间片
      if ((i + 1) % _submitBatchSize == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    downloadGroup.close();
    await downloadGroup.future;

    _log("Finished processing media.");
    return MediaProcessingResult(
      downloadedPaths: finalPaths,
      newDownloadCount: completed,
    );
  }

  void _addPathToResult(
    Map<String, Map<MediaType, String>> paths,
    String userId,
    MediaType type,
    String path,
  ) {
    paths.putIfAbsent(userId, () => {});
    paths[userId]![type] = path;
  }

  String _displayName(String remoteUrl) {
    final uri = Uri.tryParse(remoteUrl);
    final segments = uri?.pathSegments;
    return segments != null && segments.isNotEmpty ? segments.last : remoteUrl;
  }
}

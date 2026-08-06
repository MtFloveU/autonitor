import 'dart:io';
import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data_processor.dart';
import '../models/account.dart';
import '../services/database.dart';
import '../services/log_service.dart';
import '../services/twitter_api_service.dart';
import '../services/twitter_api_v1_service.dart';
import '../main.dart';
import 'auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/image_history_service.dart';
import '../repositories/account_repository.dart';
import '../models/sync_progress.dart';
import '../models/app_settings.dart';
import 'package:autonitor/l10n/app_localizations.dart';

// --- 1. Define Status Enum ---
enum AnalysisStatus {
  idle,
  running,
  pausing,
  paused,
  stopping,
  completed,
  failed,
  stopped,
}

// --- 2. Define State ---
class AnalysisState {
  final AnalysisStatus status;
  final List<String> log;
  final SyncProgress? progress;
  final DateTime? rateLimitResetAt;

  AnalysisState({
    this.status = AnalysisStatus.idle,
    this.log = const [],
    this.progress,
    this.rateLimitResetAt,
  });

  // 辅助 getter：是否处于“活跃”处理状态（不包含完成或失败）
  // 用于判断是否需要阻止返回、显示停止按钮等
  bool get isProcessing =>
      status == AnalysisStatus.running ||
      status == AnalysisStatus.pausing ||
      status == AnalysisStatus.paused ||
      status == AnalysisStatus.stopping;

  AnalysisState copyWith({
    AnalysisStatus? status,
    List<String>? log,
    SyncProgress? progress,
    DateTime? rateLimitResetAt,
  }) {
    return AnalysisState(
      status: status ?? this.status,
      log: log ?? this.log,
      progress: progress ?? this.progress,
      rateLimitResetAt: rateLimitResetAt ?? this.rateLimitResetAt,
    );
  }
}

// --- 3. Define Service ---
class AnalysisService extends StateNotifier<AnalysisState> {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Ref _ref;

  late final AppDatabase _database;
  late final TwitterApiService _apiServiceGql;
  late final TwitterApiV1Service _apiServiceV1;

  Completer<void>? _pauseLock;

  AnalysisService(this._ref) : super(AnalysisState()) {
    if (Platform.isAndroid) {
      _initLocalNotifications();
    }
    _database = _ref.read(databaseProvider);
    _apiServiceGql = _ref.read(twitterApiServiceProvider);
    _apiServiceV1 = _ref.read(twitterApiV1ServiceProvider);
  }

  void _initLocalNotifications() {
    if (!Platform.isAndroid) return;
    const androidInit = AndroidInitializationSettings('ic_launcher_foreground');
    const initSettings = InitializationSettings(android: androidInit);
    _localNotifications.initialize(initSettings);
  }

  Future<void> _showStatusNotification(String title, String body) async {
    if (!Platform.isAndroid) return;
    const androidDetails = AndroidNotificationDetails(
      'analysis_completion_channel',
      'Analysis Status',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _localNotifications.show(
      1,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  void _initForegroundTask() {
    if (!Platform.isAndroid) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'analysis_service',
        channelName: 'Analysis Service',
        channelDescription: 'Running background analysis...',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
        eventAction: ForegroundTaskEventAction.once(),
      ),
    );
  }

  // --- 控制逻辑 ---

  void togglePause() {
    if (state.status == AnalysisStatus.running) {
      state = state.copyWith(status: AnalysisStatus.pausing);
    } else if (state.status == AnalysisStatus.paused) {
      state = state.copyWith(status: AnalysisStatus.running);
      if (_pauseLock != null && !_pauseLock!.isCompleted) {
        _pauseLock!.complete();
      }
      _pauseLock = null;
    }
  }

  void stopAnalysis() {
    state = state.copyWith(status: AnalysisStatus.stopping);
    if (state.isProcessing) {
      if (_pauseLock != null && !_pauseLock!.isCompleted) {
        _pauseLock!.complete();
      }
    }
  }

  Future<void> _workerCheckPoint() async {
    if (state.status == AnalysisStatus.stopping) {
      state = state.copyWith(status: AnalysisStatus.stopped);
      throw Exception("User stopped analysis");
    }

    if (state.status == AnalysisStatus.pausing) {
      _pauseLock = Completer<void>();
      state = state.copyWith(status: AnalysisStatus.paused);
    }

    if (state.status == AnalysisStatus.paused && _pauseLock != null) {
      await _pauseLock!.future;
    }

    if (state.status == AnalysisStatus.stopping) {
      state = state.copyWith(status: AnalysisStatus.stopped);
      throw Exception("User stopped analysis");
    }
  }

  Future<void> _waitForRateLimit(DateTime resetAt) async {
    state = AnalysisState(
      status: state.status,
      log: state.log,
      progress: state.progress,
      rateLimitResetAt: resetAt,
    );
    while (true) {
      await _workerCheckPoint();
      final remaining = resetAt.difference(DateTime.now());
      if (remaining <= Duration.zero) break;
      await Future<void>.delayed(
        remaining > const Duration(seconds: 1)
            ? const Duration(seconds: 1)
            : remaining,
      );
      // Trigger a UI refresh for the visible countdown without changing the
      // active operation or resuming the blocked request early.
      state = AnalysisState(
        status: state.status,
        log: state.log,
        progress: state.progress,
        rateLimitResetAt: resetAt,
      );
    }
    state = AnalysisState(
      status: state.status,
      log: state.log,
      progress: state.progress,
    );
  }

  // 重置状态（UI返回时调用）
  void resetState() {
    if (!state.isProcessing) {
      state = AnalysisState();
    }
  }

  Future<void> runAnalysis(
    Account accountToProcess,
    SyncFetchMode syncFetchMode,
  ) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final l10n = AppLocalizations.of(context)!;

    if (Platform.isAndroid) {
      if (await FlutterForegroundTask.checkNotificationPermission() !=
          NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      final bool isIgnoringBattery =
          await FlutterForegroundTask.isIgnoringBatteryOptimizations;
      if (!isIgnoringBattery) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
      _initForegroundTask();
      await FlutterForegroundTask.startService(
        notificationTitle: l10n.sync_notification_title,
        notificationText: l10n.sync_notification_text(
          accountToProcess.screenName ?? 'Unknown',
        ),
        notificationIcon: const NotificationIcon(
          metaDataName: 'app.autonitor.NOTIFICATION_ICON',
        ),
      );
    }

    // --- Init ---
    _pauseLock = null;
    state = AnalysisState(
      status: AnalysisStatus.running,
      progress: const SyncProgress(stage: SyncStage.preparing),
    );

    void logCallback(String message) {
      // Keep diagnostics available without allowing a long-running sync to
      // repeatedly copy an unbounded list and stall the visual progress UI.
      final log = [...state.log, message];
      state = state.copyWith(log: log.length > 500 ? log.sublist(1) : log);
    }

    void progressCallback(SyncProgress progress) {
      state = state.copyWith(progress: progress);
    }

    logCallback('Initializing DataProcessor...');

    try {
      final settings = _ref.read(settingsProvider).asData!.value;
      final imageService = _ref.read(imageHistoryServiceProvider);
      final accountRepository = _ref.read(accountRepositoryProvider);

      final dataProcessor = DataProcessor(
        ref: _ref,
        database: _database,
        apiServiceGql: _apiServiceGql,
        apiServiceV1: _apiServiceV1,
        ownerAccount: accountToProcess,
        logCallback: logCallback,
        settings: settings,
        syncFetchMode: syncFetchMode,
        imageService: imageService,
        accountRepository: accountRepository,
        checkPauseCallback: _workerCheckPoint,
        onProgress: progressCallback,
        waitForRateLimit: _waitForRateLimit,
      );

      await dataProcessor.runFullProcess();
      await _ref.read(accountsProvider.notifier).loadAccounts();

      logCallback('Process finished successfully.');

      // [Change] 成功完成，状态设为 completed
      state = state.copyWith(
        status: AnalysisStatus.completed,
        progress: const SyncProgress(stage: SyncStage.completed),
      );

      await _showStatusNotification(
        l10n.sync_notification_title,
        l10n.sync_completed_notification_text(
          accountToProcess.screenName ?? 'Unknown',
        ),
      );
    } catch (e, s) {
      if (e.toString().contains("User stopped analysis")) {
        logCallback('Analysis stopped by user.');
        state = state.copyWith(
          status: AnalysisStatus.stopped,
          progress: const SyncProgress(stage: SyncStage.stopped),
        );
      } else {
        logCallback(
          '!!! PROCESS FAILED for account ${accountToProcess.id}: $e',
        );
        logger.e("Analysis process failed", error: e, stackTrace: s);

        // [Change] 失败，状态设为 failed
        state = state.copyWith(
          status: AnalysisStatus.failed,
          progress: const SyncProgress(stage: SyncStage.failed),
        );

        await _showStatusNotification(
          l10n.sync_notification_title,
          l10n.sync_failed_notification_text(
            accountToProcess.screenName ?? 'Unknown',
          ),
        );
      }
    } finally {
      // Cleanup locks
      if (_pauseLock != null && !_pauseLock!.isCompleted) {
        _pauseLock!.complete();
      }

      if (state.status == AnalysisStatus.stopping) {
        state = state.copyWith(
          status: AnalysisStatus.stopped,
          progress: const SyncProgress(stage: SyncStage.stopped),
        );
      }

      if (Platform.isAndroid) {
        await FlutterForegroundTask.stopService();
      }
    }
  }
}

final analysisServiceProvider =
    StateNotifierProvider<AnalysisService, AnalysisState>((ref) {
      return AnalysisService(ref);
    });

final analysisIsRunningProvider = Provider<bool>((ref) {
  return ref.watch(analysisServiceProvider).isProcessing;
});

final analysisLogProvider = Provider<List<String>>((ref) {
  return ref.watch(analysisServiceProvider).log;
});

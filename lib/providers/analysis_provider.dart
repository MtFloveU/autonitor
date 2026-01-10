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
import 'package:autonitor/l10n/app_localizations.dart';

// --- 1. Define the state that this service will hold ---
class AnalysisState {
  final bool isRunning;
  final List<String> log;

  AnalysisState({this.isRunning = false, this.log = const []});

  AnalysisState copyWith({bool? isRunning, List<String>? log}) {
    return AnalysisState(
      isRunning: isRunning ?? this.isRunning,
      log: log ?? this.log,
    );
  }
}

// --- 2. Define the StateNotifier (the Service itself) ---
class AnalysisService extends StateNotifier<AnalysisState> {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Ref _ref;

  late final AppDatabase _database;
  late final TwitterApiService _apiServiceGql;
  late final TwitterApiV1Service _apiServiceV1;

  AnalysisService(this._ref) : super(AnalysisState()) {
    // Initialize notification settings only on Android
    if (Platform.isAndroid) {
      _initLocalNotifications();
    }

    _database = _ref.read(databaseProvider);
    _apiServiceGql = _ref.read(twitterApiServiceProvider);
    _apiServiceV1 = _ref.read(twitterApiV1ServiceProvider);
  }

  void _initLocalNotifications() {
    if (!Platform.isAndroid) return;

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidInit);
    _localNotifications.initialize(initSettings);
  }

  /// Sends a completion/failure notification (Android Only)
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
        showNotification: false, // Explicitly false for safety
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

  Future<void> runAnalysis(Account accountToProcess) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final l10n = AppLocalizations.of(context)!;

    // --- Android Specific Setup ---
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
      );
    }

    // --- Core Logic (Cross-platform) ---
    state = state.copyWith(isRunning: true, log: []);
    void logCallback(String message) {
      state = state.copyWith(log: [...state.log, message]);
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
        imageService: imageService,
        accountRepository: accountRepository,
      );

      await dataProcessor.runFullProcess();
      await _ref.read(accountsProvider.notifier).loadAccounts();

      logCallback('Process finished successfully.');

      // Notify completion (Android Only)
      await _showStatusNotification(
        l10n.sync_notification_title,
        l10n.sync_completed_notification_text(
          accountToProcess.screenName ?? 'Unknown',
        ),
      );
    } catch (e, s) {
      logCallback('!!! PROCESS FAILED for account ${accountToProcess.id}: $e');
      logger.e("Analysis process failed", error: e, stackTrace: s);

      // Notify failure (Android Only)
      await _showStatusNotification(
        l10n.sync_notification_title,
        l10n.sync_failed_notification_text(
          accountToProcess.screenName ?? 'Unknown',
        ),
      );
    } finally {
      state = state.copyWith(isRunning: false);

      // --- Android Specific Teardown ---
      if (Platform.isAndroid) {
        await FlutterForegroundTask.stopService();
      }
    }
  }
}

// --- 3. Providers ---
final analysisServiceProvider =
    StateNotifierProvider<AnalysisService, AnalysisState>((ref) {
      return AnalysisService(ref);
    });

final analysisIsRunningProvider = Provider<bool>((ref) {
  return ref.watch(analysisServiceProvider).isRunning;
});

final analysisLogProvider = Provider<List<String>>((ref) {
  return ref.watch(analysisServiceProvider).log;
});

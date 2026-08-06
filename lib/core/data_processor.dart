import 'package:autonitor/providers/runid_provider.dart';

import 'database_updater.dart';
import 'media_processor.dart';
import 'network_data_fetcher.dart';
import 'new_network_data_fetcher.dart' as new_network;
import 'relationship_analyzer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../services/database.dart';
import '../services/twitter_api_service.dart';
import '../services/twitter_api_v1_service.dart';
import '../models/app_settings.dart';
import '../services/image_history_service.dart';
import '../repositories/account_repository.dart';
import '../providers/x_client_transaction_provider.dart';
import '../providers/graphql_queryid_provider.dart';
import '../services/x_client_transaction_service.dart';
import '../models/sync_progress.dart';

typedef LogCallback = void Function(String message);
// 回调定义保持不变
typedef CheckPauseCallback = Future<void> Function();
typedef WaitForRateLimitCallback = Future<void> Function(DateTime resetAt);

class DataProcessor {
  final Ref _ref;
  final AppDatabase _database;
  final TwitterApiService _apiServiceGql;
  final TwitterApiV1Service _apiServiceV1;
  final String _ownerId;
  final String _ownerCookie;
  final int _ownerFollowersCount;
  final int _ownerFollowingCount;
  final AccountRepository _accountRepository;
  final LogCallback _log;
  final AppSettings _settings;
  final SyncFetchMode _syncFetchMode;
  final ImageHistoryService _imageService;

  final CheckPauseCallback _checkPauseCallback;
  final SyncProgressCallback _onProgress;
  final WaitForRateLimitCallback _waitForRateLimit;

  late final NetworkDataFetcher _networkFetcher;
  late final new_network.NewNetworkDataFetcher _newNetworkFetcher;
  late final RelationshipAnalyzer _relationshipAnalyzer;
  late final MediaProcessor _mediaProcessor;
  late final DatabaseUpdater _databaseUpdater;

  DataProcessor({
    required Ref ref,
    required AppDatabase database,
    required TwitterApiService apiServiceGql,
    required TwitterApiV1Service apiServiceV1,
    required AccountRepository accountRepository,
    required Account ownerAccount,
    required AppSettings settings,
    required SyncFetchMode syncFetchMode,
    required ImageHistoryService imageService,
    required LogCallback logCallback,
    required CheckPauseCallback checkPauseCallback,
    required SyncProgressCallback onProgress,
    required WaitForRateLimitCallback waitForRateLimit,
  }) : _ref = ref,
       _database = database,
       _apiServiceGql = apiServiceGql,
       _apiServiceV1 = apiServiceV1,
       _accountRepository = accountRepository,
       _ownerId = ownerAccount.id,
       _ownerCookie = ownerAccount.cookie,
       _ownerFollowersCount = ownerAccount.followersCount,
       _ownerFollowingCount = ownerAccount.followingCount,
       _log = logCallback,
       _settings = settings,
       _syncFetchMode = syncFetchMode,
       _imageService = imageService,
       _checkPauseCallback = checkPauseCallback,
       _onProgress = onProgress,
       _waitForRateLimit = waitForRateLimit {
    _networkFetcher = NetworkDataFetcher(
      apiServiceGql: _apiServiceGql,
      apiServiceV1: _apiServiceV1,
      ref: _ref,
      ownerId: _ownerId,
      ownerCookie: _ownerCookie,
      log: _log,
      checkPauseCallback: _checkPauseCallback,
      onProgress: _onProgress,
      waitForRateLimit: _waitForRateLimit,
      apiRequestMode: _settings.apiRequestMode,
      cffiUrl: _settings.remoteFastApiUrl,
      cffiApiKey: _settings.fastApiApiKey,
    );

    _newNetworkFetcher = new_network.NewNetworkDataFetcher(
      apiServiceGql: _apiServiceGql,
      apiServiceV1: _apiServiceV1,
      ref: _ref,
      ownerId: _ownerId,
      ownerCookie: _ownerCookie,
      log: _log,
      checkPauseCallback: _checkPauseCallback,
      onProgress: _onProgress,
      waitForRateLimit: _waitForRateLimit,
      apiRequestMode: _settings.apiRequestMode,
      cffiUrl: _settings.remoteFastApiUrl,
      cffiApiKey: _settings.fastApiApiKey,
    );

    _mediaProcessor = MediaProcessor(
      imageService: _imageService,
      settings: _settings,
      ownerId: _ownerId,
      log: _log,
      checkPauseCallback: _checkPauseCallback,
      onProgress: _onProgress,
    );

    _databaseUpdater = DatabaseUpdater(database: _database);
  }

  Future<void> _initializeRelationshipAnalyzer() async {
    // [Fix] 现在将回调注入分析器，解决分析阶段卡顿无法暂停的问题
    XClientTransactionService? xctService;
    try {
      xctService = await _ref.read(xctServiceProvider.future);
    } catch (error) {
      _log(
        'WARNING: X transaction ID is unavailable ($error). Continuing without the optional header.',
      );
    }

    _relationshipAnalyzer = RelationshipAnalyzer(
      apiServiceGql: _apiServiceGql,
      accountRepository: _accountRepository,
      ownerId: _ownerId,
      ownerCookie: _ownerCookie,
      log: _log,
      checkPauseCallback: _checkPauseCallback,
      xctService: xctService,
      apiRequestMode: _settings.apiRequestMode,
      cffiUrl: _settings.remoteFastApiUrl,
      cffiApiKey: _settings.fastApiApiKey,
      onProgress: _onProgress,
    );
  }

  Future<Account?> _refreshOwnerProfile() async {
    _log("Refreshing owner account profile ($_ownerId)...");
    try {
      final ownerAccount = Account(id: _ownerId, cookie: _ownerCookie);
      final refreshedAccount = await _accountRepository.refreshAccountProfile(
        ownerAccount,
      );
      _log("Owner account profile refresh successful.");
      return refreshedAccount;
    } catch (e) {
      _log(
        "!!! WARNING: Failed to refresh owner account profile: $e. Continuing...",
      );
      return null;
    }
  }

  Future<void> _initDependencies() async {
    _log("Initalizing XClientTransactionID generator...");
    try {
      await _ref.read(transactionIdProvider.notifier).init();
    } catch (e) {
      _log(
        "!!! CRITICAL ERROR: Failed to initialize XClientTransactionID generator: $e",
      );
    }
    _onProgress(
      const SyncProgress(
        stage: SyncStage.initializingServices,
        step: SyncStep.loadingQueryIds,
      ),
    );
    _log("Loading GQL Query IDs...");
    try {
      _ref
          .read(gqlQueryIdProvider.notifier)
          .getCurrentQueryIdForDisplay('Following');
    } catch (e) {
      _log("Error ensuring GQL Query IDs are loaded: $e");
    }
  }

  Future<void> runFullProcess() async {
    _onProgress(
      const SyncProgress(
        stage: SyncStage.preparing,
        step: SyncStep.generatingRunId,
      ),
    );
    _log("Starting analysis process for account ID: $_ownerId...");
    final runIdService = _ref.read(runIdProvider);
    final currentRunId = await runIdService.generateUniqueRunId();
    _log("Generated unique RunID: $currentRunId");

    try {
      await _checkPauseCallback();

      _onProgress(
        const SyncProgress(
          stage: SyncStage.refreshingProfile,
          step: SyncStep.refreshingOwnerProfile,
        ),
      );
      final refreshedOwner = await _refreshOwnerProfile();
      await _checkPauseCallback();

      _onProgress(
        const SyncProgress(
          stage: SyncStage.initializingServices,
          step: SyncStep.initializingTransactionId,
        ),
      );
      await _initializeRelationshipAnalyzer();
      await _checkPauseCallback();

      await _initDependencies();

      _onProgress(
        const SyncProgress(
          stage: SyncStage.loadingExistingData,
          step: SyncStep.loadingExistingRelations,
        ),
      );
      _log("Fetching old relationships from database...");
      final oldRelationsList = await _database.getNetworkRelationships(
        _ownerId,
      );
      final Map<String, FollowUser> oldRelationsMap = {
        for (var relation in oldRelationsList) relation.userId: relation,
      };
      _log("Found ${oldRelationsMap.length} existing relationships.");

      await _checkPauseCallback();
      _onProgress(const SyncProgress(stage: SyncStage.fetchingNetwork));
      late final NetworkFetchResult networkData;
      final followersTotal =
          refreshedOwner?.followersCount ?? _ownerFollowersCount;
      final followingTotal =
          refreshedOwner?.followingCount ?? _ownerFollowingCount;
      switch (_syncFetchMode) {
        case SyncFetchMode.fast:
          networkData = await _networkFetcher.fetchAllNetworkData(
            followersTotal: followersTotal,
            followingTotal: followingTotal,
          );
        case SyncFetchMode.expert:
          final fetchedData = await _newNetworkFetcher.fetchAllNetworkData(
            followersTotal: followersTotal,
            followingTotal: followingTotal,
          );
          networkData = NetworkFetchResult(
            uniqueUsers: fetchedData.uniqueUsers,
            followerIds: fetchedData.followerIds,
            followingIds: fetchedData.followingIds,
          );
        case SyncFetchMode.fastest:
          final fetchedData = await _newNetworkFetcher.fetchAllNetworkData(
            followersTotal: followersTotal,
            followingTotal: followingTotal,
            enrichProfiles: false,
          );
          networkData = NetworkFetchResult(
            uniqueUsers: fetchedData.uniqueUsers,
            followerIds: fetchedData.followerIds,
            followingIds: fetchedData.followingIds,
          );
      }
      _log(
        "Finished fetching. Total unique users: ${networkData.uniqueUsers.length}",
      );

      await _checkPauseCallback();

      _onProgress(const SyncProgress(stage: SyncStage.analyzingChanges));
      final analysisResult = await _relationshipAnalyzer.analyze(
        oldRelationsMap: oldRelationsMap,
        networkData: networkData,
      );
      _log(
        "Analysis complete. Generated ${analysisResult.reports.length} change reports.",
      );

      await _checkPauseCallback();

      _onProgress(const SyncProgress(stage: SyncStage.downloadingMedia));
      final mediaResult = await _mediaProcessor.processMedia(
        newUsers: networkData.uniqueUsers,
        oldRelations: oldRelationsMap,
        followerIds: networkData.followerIds,
        followingIds: networkData.followingIds,
      );
      _log("Finished downloading ${mediaResult.newDownloadCount} images.");

      await _checkPauseCallback();

      _onProgress(
        const SyncProgress(
          stage: SyncStage.savingResults,
          step: SyncStep.preparingDatabaseChanges,
        ),
      );
      _log("Writing changes to database...");
      _onProgress(
        const SyncProgress(
          stage: SyncStage.savingResults,
          step: SyncStep.writingDatabaseChanges,
        ),
      );
      await _databaseUpdater.saveChanges(
        ownerId: _ownerId,
        networkData: networkData,
        analysisResult: analysisResult,
        mediaResult: mediaResult,
        oldRelationsMap: oldRelationsMap,
        currentRunId: currentRunId,
        syncFetchMode: _syncFetchMode,
      );

      _onProgress(
        const SyncProgress(
          stage: SyncStage.finalizing,
          step: SyncStep.recordingSyncLog,
        ),
      );
      _log("Recording sync log...");
      await _databaseUpdater.insertSyncLog(
        runId: currentRunId,
        ownerId: _ownerId,
        status: 1,
        timestamp: DateTime.now(),
      );

      _log(
        "Analysis process completed successfully for account ID: $_ownerId.",
      );
      _onProgress(const SyncProgress(stage: SyncStage.completed));
    } catch (e, s) {
      _log("!!! CRITICAL ERROR: $e");
      _log("Stacktrace: $s");
      rethrow;
    }
  }
}

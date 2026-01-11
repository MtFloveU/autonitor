import 'package:autonitor/providers/runid_provider.dart';

import 'database_updater.dart';
import 'media_processor.dart';
import 'network_data_fetcher.dart';
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

typedef LogCallback = void Function(String message);
// 回调定义保持不变
typedef CheckPauseCallback = Future<void> Function();

class DataProcessor {
  final Ref _ref;
  final AppDatabase _database;
  final TwitterApiService _apiServiceGql;
  final TwitterApiV1Service _apiServiceV1;
  final String _ownerId;
  final String _ownerCookie;
  final AccountRepository _accountRepository;
  final LogCallback _log;
  final AppSettings _settings;
  final ImageHistoryService _imageService;
  
  final CheckPauseCallback _checkPauseCallback;

  late final NetworkDataFetcher _networkFetcher;
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
    required ImageHistoryService imageService,
    required LogCallback logCallback,
    required CheckPauseCallback checkPauseCallback,
  }) : _ref = ref,
       _database = database,
       _apiServiceGql = apiServiceGql,
       _apiServiceV1 = apiServiceV1,
       _accountRepository = accountRepository,
       _ownerId = ownerAccount.id,
       _ownerCookie = ownerAccount.cookie,
       _log = logCallback,
       _settings = settings,
       _imageService = imageService,
       _checkPauseCallback = checkPauseCallback
  {
    _networkFetcher = NetworkDataFetcher(
      apiServiceGql: _apiServiceGql,
      apiServiceV1: _apiServiceV1,
      ref: _ref,
      ownerId: _ownerId,
      ownerCookie: _ownerCookie,
      log: _log,
      checkPauseCallback: _checkPauseCallback,
    );

    // [Fix] 现在将回调注入分析器，解决分析阶段卡顿无法暂停的问题
    _relationshipAnalyzer = RelationshipAnalyzer(
      apiServiceGql: _apiServiceGql,
      accountRepository: _accountRepository,
      ownerId: _ownerId,
      ownerCookie: _ownerCookie,
      log: _log,
      checkPauseCallback: _checkPauseCallback, 
    );

    _mediaProcessor = MediaProcessor(
      imageService: _imageService,
      settings: _settings,
      ownerId: _ownerId,
      log: _log,
      checkPauseCallback: _checkPauseCallback,
    );

    _databaseUpdater = DatabaseUpdater(database: _database);
  }

  Future<void> _refreshOwnerProfile() async {
    _log("Refreshing owner account profile ($_ownerId)...");
    try {
      final ownerAccount = Account(id: _ownerId, cookie: _ownerCookie);
      await _accountRepository.refreshAccountProfile(ownerAccount);
      _log("Owner account profile refresh successful.");
    } catch (e) {
      _log("!!! WARNING: Failed to refresh owner account profile: $e. Continuing...");
    }
  }

  Future<void> _initDependencies() async {
    _log("Initalizing XClientTransactionID generator...");
    try {
      await _ref.read(transactionIdProvider.notifier).init();
    } catch (e) {
      _log("!!! CRITICAL ERROR: Failed to initialize XClientTransactionID generator: $e");
    }
    _log("Loading GQL Query IDs...");
    try {
      _ref.read(gqlQueryIdProvider.notifier).getCurrentQueryIdForDisplay('Following');
    } catch (e) {
      _log("Error ensuring GQL Query IDs are loaded: $e");
    }
  }

  Future<void> runFullProcess() async {
    _log("Starting analysis process for account ID: $_ownerId...");
    final runIdService = _ref.read(runIdProvider);
    final currentRunId = await runIdService.generateUniqueRunId();
    _log("Generated unique RunID: $currentRunId");

    try {
      await _checkPauseCallback();

      await _refreshOwnerProfile();
      await _checkPauseCallback();

      await _initDependencies();

      _log("Fetching old relationships from database...");
      final oldRelationsList = await _database.getNetworkRelationships(_ownerId);
      final Map<String, FollowUser> oldRelationsMap = {
        for (var relation in oldRelationsList) relation.userId: relation,
      };
      _log("Found ${oldRelationsMap.length} existing relationships.");

      await _checkPauseCallback();

      final networkData = await _networkFetcher.fetchAllNetworkData();
      _log("Finished fetching. Total unique users: ${networkData.uniqueUsers.length}");

      await _checkPauseCallback();

      final analysisResult = await _relationshipAnalyzer.analyze(
        oldRelationsMap: oldRelationsMap,
        networkData: networkData,
      );
      _log("Analysis complete. Generated ${analysisResult.reports.length} change reports.");

      await _checkPauseCallback();

      final mediaResult = await _mediaProcessor.processMedia(
        newUsers: networkData.uniqueUsers,
        oldRelations: oldRelationsMap,
      );
      _log("Finished downloading ${mediaResult.newDownloadCount} images.");

      await _checkPauseCallback();

      _log("Writing changes to database...");
      await _databaseUpdater.saveChanges(
        ownerId: _ownerId,
        networkData: networkData,
        analysisResult: analysisResult,
        mediaResult: mediaResult,
        oldRelationsMap: oldRelationsMap,
        currentRunId: currentRunId,
      );

      _log("Recording sync log...");
      await _databaseUpdater.insertSyncLog(
        runId: currentRunId,
        ownerId: _ownerId,
        status: 1, 
        timestamp: DateTime.now(),
      );

      _log("Analysis process completed successfully for account ID: $_ownerId.");
    } catch (e, s) {
      _log("!!! CRITICAL ERROR: $e");
      _log("Stacktrace: $s");
      rethrow;
    }
  }
}
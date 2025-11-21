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

  // New helper classes
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
  })  : _ref = ref,
        _database = database,
        _apiServiceGql = apiServiceGql,
        _apiServiceV1 = apiServiceV1,
        _accountRepository = accountRepository,
        _ownerId = ownerAccount.id,
        _ownerCookie = ownerAccount.cookie,
        _log = logCallback,
        _settings = settings,
        _imageService = imageService {
    // Initialize the helper classes, passing them the dependencies they need
    _networkFetcher = NetworkDataFetcher(
      apiServiceGql: _apiServiceGql,
      apiServiceV1: _apiServiceV1,
      ref: _ref,
      ownerId: _ownerId,
      ownerCookie: _ownerCookie,
      log: _log,
    );

    _relationshipAnalyzer = RelationshipAnalyzer(
      apiServiceGql: _apiServiceGql,
      accountRepository: _accountRepository,
      ownerId: _ownerId,
      ownerCookie: _ownerCookie,
      log: _log,
    );

    _mediaProcessor = MediaProcessor(
      imageService: _imageService,
      settings: _settings,
      ownerId: _ownerId,
      log: _log,
    );

    _databaseUpdater = DatabaseUpdater(
      database: _database,
      log: _log,
    );
  }

  Future<void> _refreshOwnerProfile() async {
    _log("Refreshing owner account profile ($_ownerId)...");
    try {
      final ownerAccount = Account(id: _ownerId, cookie: _ownerCookie);
      await _accountRepository.refreshAccountProfile(ownerAccount);
      _log("Owner account profile refresh successful.");
    } catch (e) {
      _log(
        "!!! WARNING: Failed to refresh owner account profile: $e. "
        "Continuing with follower/following analysis...",
      );
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
      // Depending on severity, you might want to rethrow here
    }
    _log("Loading GQL Query IDs...");
    try {
      // Ensure query IDs are loaded. This can be expanded.
      _ref.read(gqlQueryIdProvider.notifier).getCurrentQueryIdForDisplay('Following');
    } catch (e) {
        _log("Error ensuring GQL Query IDs are loaded: $e");
    }
  }

  Future<void> runFullProcess() async {
    _log("Starting analysis process for account ID: $_ownerId...");
    try {
      // 1. Refresh Owner Profile
      await _refreshOwnerProfile();

      // 2. Initialize Dependencies
      await _initDependencies();

      // 3. Get Old Data from Database
      _log("Fetching old relationships from database...");
      final oldRelationsList = await _database.getNetworkRelationships(_ownerId);
      final Map<String, FollowUser> oldRelationsMap = {
        for (var relation in oldRelationsList) relation.userId: relation,
      };
      _log("Found ${oldRelationsMap.length} existing relationships.");

      // 4. Fetch New Network Data (Delegated)
      final networkData = await _networkFetcher.fetchAllNetworkData();
      _log(
        "Finished fetching. Total unique users: ${networkData.uniqueUsers.length}",
      );

      // 5. Analyze Changes (Delegated)
      final analysisResult = await _relationshipAnalyzer.analyze(
        oldRelationsMap: oldRelationsMap,
        networkData: networkData,
      );
      _log(
        "Analysis complete: ${analysisResult.addedIds.length} added, "
        "${analysisResult.removedIds.length} removed, "
        "${analysisResult.keptIds.length} kept.",
      );
      _log("Generated ${analysisResult.reports.length} change reports.");

      // 6. Process Media (Delegated)
      final mediaResult = await _mediaProcessor.processMedia(
        newUsers: networkData.uniqueUsers,
        oldRelations: oldRelationsMap,
      );
      _log(
        "Finished downloading ${mediaResult.downloadedPaths.length} images.",
      );

      // 7. Save to Database (Delegated)
      _log("Writing changes to database...");
      await _databaseUpdater.saveChanges(
        ownerId: _ownerId,
        networkData: networkData,
        analysisResult: analysisResult,
        mediaResult: mediaResult,
        oldRelationsMap: oldRelationsMap,
      );

      _log(
        "Analysis process completed successfully for account ID: $_ownerId.",
      );
    } catch (e, s) {
      _log(
        "!!! CRITICAL ERROR during analysis process for account ID: $_ownerId: $e",
      );
      _log("Stacktrace: $s");
      rethrow;
    }
  }
}
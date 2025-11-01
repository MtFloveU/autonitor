import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../core/data_processor.dart';
import '../models/account.dart';
import '../services/database.dart';
import '../services/twitter_api_service.dart';
import '../services/twitter_api_v1_service.dart';
import '../main.dart';
import 'auth_provider.dart';

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
  final Ref _ref;
  // The service needs all the tools DataProcessor needs
  late final AppDatabase _database;
  late final TwitterApiService _apiServiceGql;
  late final TwitterApiV1Service _apiServiceV1;

  AnalysisService(this._ref) : super(AnalysisState()) {
    // Get the tools
    _database = _ref.read(databaseProvider);
    _apiServiceGql = _ref.read(twitterApiServiceProvider);
    _apiServiceV1 = _ref.read(twitterApiV1ServiceProvider);
  }

  // --- We will move the logic from runAnalysisProcess here ---
  Future<void> runAnalysis(Account accountToProcess) async {
    // Logic will go here in the next step
    state = state.copyWith(isRunning: true, log: []);
    void logCallback(String message) {
      state = state.copyWith(log: [...state.log, message]);
    }

    logCallback('Initializing DataProcessor...');
    final dataProcessor = DataProcessor(
      database: _database,
      apiServiceGql: _apiServiceGql,
      apiServiceV1: _apiServiceV1,
      ownerAccount: accountToProcess,
      logCallback: logCallback,
    );
    try {
      await dataProcessor.runFullProcess();
      await _ref.read(accountsProvider.notifier).loadAccounts();
      logCallback('Process finished successfully.');
    } catch (e, s) {
      logCallback('!!! PROCESS FAILED for account ${accountToProcess.id}: $e');
      logCallback('Stacktrace: $s');
      rethrow;
    } finally {
      state = state.copyWith(isRunning: false);
    }
  }
}

// --- 3. Define the provider for this service ---
final analysisServiceProvider =
    StateNotifierProvider<AnalysisService, AnalysisState>((ref) {
      return AnalysisService(ref);
    });

// --- 4. (Recommended) Providers for just the log/status ---
// This makes it easy for the UI to listen *only* to what it needs.
final analysisIsRunningProvider = Provider<bool>((ref) {
  // It derives its state from the main service provider
  return ref.watch(analysisServiceProvider).isRunning;
});

final analysisLogProvider = Provider<List<String>>((ref) {
  // It derives its state from the main service provider
  return ref.watch(analysisServiceProvider).log;
});

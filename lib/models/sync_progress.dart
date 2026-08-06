/// The high-level stages shown while a network sync is running.
enum SyncStage {
  preparing,
  refreshingProfile,
  initializingServices,
  loadingExistingData,
  fetchingNetwork,
  analyzingChanges,
  downloadingMedia,
  savingResults,
  finalizing,
  completed,
  failed,
  stopped,
}

/// The concrete operation inside a high-level [SyncStage].  The UI localizes
/// these values, while the processing layer only reports facts and counters.
enum SyncStep {
  generatingRunId,
  refreshingOwnerProfile,
  initializingTransactionId,
  loadingQueryIds,
  loadingExistingRelations,
  fetchingFollowers,
  fetchingFollowing,
  enrichingProfiles,
  checkingRemovedRelations,
  comparingProfiles,
  checkingMedia,
  downloadingMedia,
  preparingDatabaseChanges,
  writingDatabaseChanges,
  recordingSyncLog,
}

/// The concrete operation currently running within a sync stage.
enum SyncOperation {
  createRun,
  refreshProfile,
  initializeTransaction,
  loadQueryIds,
  loadRelationships,
  fetchFollowers,
  fetchFollowing,
  enrichProfiles,
  compareRelationships,
  classifyRemovedAccounts,
  compareProfiles,
  checkMedia,
  downloadMedia,
  prepareDatabase,
  writeDatabase,
  recordSyncLog,
}

/// Progress information deliberately kept independent from UI and providers so
/// processing code can report useful state without knowing Flutter details.
class SyncProgress {
  const SyncProgress({
    required this.stage,
    this.completedItems,
    this.totalItems,
    this.currentItemName,
    this.step,
    this.currentBatch,
    this.operation,
  });

  final SyncStage stage;
  final int? completedItems;
  final int? totalItems;
  final String? currentItemName;
  final SyncStep? step;
  final int? currentBatch;
  final SyncOperation? operation;

  bool get hasItemProgress =>
      completedItems != null && totalItems != null && totalItems! > 0;

  double? get itemFraction =>
      hasItemProgress ? (completedItems! / totalItems!).clamp(0.0, 1.0) : null;
}

typedef SyncProgressCallback = void Function(SyncProgress progress);

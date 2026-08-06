part of '../settings_page.dart';

enum _BackupKind { config, database, media, all }

class BackupRestorePage extends ConsumerStatefulWidget {
  const BackupRestorePage({super.key});

  @override
  ConsumerState<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends ConsumerState<BackupRestorePage> {
  static const _backupCancellingMarker = '__backup_cancelling__';
  static const _androidBackupChannel = MethodChannel(
    'app.autonitor/backup_file',
  );
  bool _busy = false;
  final _backupProgress = ValueNotifier<BackupProgress>(
    const BackupProgress(completedFiles: 0, totalFiles: 0, currentFileName: ''),
  );
  final _restoreProgress = ValueNotifier<RestoreProgress>(
    const RestoreProgress(stage: RestoreStage.preparing),
  );
  BackupCancellationToken? _backupCancellation;

  BackupRestoreService get _service =>
      BackupRestoreService(ref.read(databaseProvider));

  @override
  void dispose() {
    _backupProgress.dispose();
    _restoreProgress.dispose();
    super.dispose();
  }

  Future<void> _backup(_BackupKind kind) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final cancellation = BackupCancellationToken();
    setState(() => _busy = true);
    _backupCancellation = cancellation;
    _backupProgress.value = const BackupProgress(
      completedFiles: 0,
      totalFiles: 0,
      currentFileName: '',
    );
    var progressShown = false;
    try {
      _showBackupProgressDialog(l10n.backup);
      progressShown = true;
      logger.i('Backup requested: ${kind.name}.');
      final settings = ref.read(settingsProvider).valueOrNull ?? AppSettings();
      final bytes = switch (kind) {
        _BackupKind.config => await _service.createConfigBackup(
          settings,
          onProgress: _updateBackupProgress,
          cancellationToken: cancellation,
        ),
        _BackupKind.database => await _service.createDatabaseBackup(
          onProgress: _updateBackupProgress,
          cancellationToken: cancellation,
        ),
        _BackupKind.media => await _service.createMediaBackup(
          onProgress: _updateBackupProgress,
          cancellationToken: cancellation,
        ),
        _BackupKind.all => await _service.createFullBackup(
          settings,
          onProgress: _updateBackupProgress,
          cancellationToken: cancellation,
        ),
      };
      cancellation.throwIfCancelled();
      logger.i('Backup data prepared. Opening the system save picker.');
      if (mounted && progressShown) {
        Navigator.of(context, rootNavigator: true).pop();
        progressShown = false;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final path = await _saveBackupFile(kind, bytes);
      if (path == null) {
        logger.i('Backup save cancelled by user.');
        return;
      }
      logger.i('Backup saved successfully: $path');
      if (mounted) {
        _showMessage(l10n.backup_successful);
      }
    } on BackupCancelledException {
      logger.i('Backup cancelled by user.');
      if (mounted) _showMessage(l10n.backup_cancelled);
    } catch (error) {
      logger.e('Backup failed: $error', error: error);
      if (mounted) {
        _showMessage(l10n.backup_failed(error.toString()), error: true);
      }
    } finally {
      if (mounted) {
        if (progressShown) {
          // The dialog blocks user back navigation with PopScope, so maybePop
          // leaves it on screen after a cancellation.  This is the matching
          // programmatic dismissal used before opening the document picker.
          Navigator.of(context, rootNavigator: true).pop();
          progressShown = false;
        }
        setState(() {
          _busy = false;
          _backupCancellation = null;
        });
      }
    }
  }

  String _backupExtension(_BackupKind kind) => kind == _BackupKind.config
      ? 'json'
      : kind == _BackupKind.database
      ? 'db'
      : 'zip';

  String _backupFileName(_BackupKind kind) =>
      'autonitor_${kind.name}_${DateTime.now().millisecondsSinceEpoch}.${_backupExtension(kind)}';

  Future<String?> _saveBackupFile(_BackupKind kind, Uint8List bytes) async {
    final fileName = _backupFileName(kind);
    if (!Platform.isAndroid) {
      return FilePicker.platform.saveFile(
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [_backupExtension(kind)],
        bytes: bytes,
      );
    }

    // file_picker sends `bytes` through a platform channel on Android.  A
    // large ZIP can make that transfer stall or crash just as the system
    // document picker is opened.  Stage it locally and let Android stream the
    // file to the user-selected URI instead.
    final tempDirectory = await Directory.systemTemp.createTemp(
      'autonitor_export_',
    );
    final sourceFile = File(p.join(tempDirectory.path, fileName));
    try {
      await sourceFile.writeAsBytes(bytes, flush: true);
      return await _androidBackupChannel
          .invokeMethod<String>('savePreparedFile', {
            'sourcePath': sourceFile.path,
            'fileName': fileName,
            'mimeType': _backupMimeType(kind),
          });
    } finally {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    }
  }

  String _backupMimeType(_BackupKind kind) => switch (kind) {
    _BackupKind.config => 'application/json',
    _BackupKind.database => 'application/octet-stream',
    _BackupKind.media || _BackupKind.all => 'application/zip',
  };

  void _updateBackupProgress(BackupProgress progress) {
    if (!mounted || _backupCancellation?.isCancelled == true) return;
    _backupProgress.value = progress;
  }

  void _showBackupProgressDialog(String title) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(title),
          content: ValueListenableBuilder<BackupProgress>(
            valueListenable: _backupProgress,
            builder: (context, progress, child) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress.currentFileName.isEmpty
                      ? l10n.backup_preparing
                      : progress.currentFileName == _backupCancellingMarker
                      ? l10n.backup_cancelling
                      : l10n.backup_processing_file(progress.currentFileName),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: progress.fraction),
                const SizedBox(height: 8),
                Text(
                  progress.totalFiles == 0
                      ? l10n.backup_collecting_files
                      : l10n.backup_progress(
                          progress.completedFiles,
                          progress.totalFiles,
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: _cancelBackup, child: Text(l10n.cancel)),
          ],
        ),
      ),
    );
  }

  void _cancelBackup() {
    final cancellation = _backupCancellation;
    if (cancellation == null || cancellation.isCancelled) return;
    logger.i('Backup cancellation requested by user.');
    cancellation.cancel();
    _backupProgress.value = const BackupProgress(
      completedFiles: 0,
      totalFiles: 0,
      currentFileName: _backupCancellingMarker,
    );
  }

  Future<void> _restore(_BackupKind kind) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final extensions = switch (kind) {
      _BackupKind.config => ['json'],
      _BackupKind.database => ['db'],
      _BackupKind.media || _BackupKind.all => ['zip'],
    };
    final selected = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      // Android must not copy a large ZIP into a Uint8List before restore.
      // file_picker supplies a local cache path for the selected document.
      withData: false,
    );
    final sourcePath = selected != null && selected.files.length == 1
        ? selected.files.single.path
        : null;
    if (sourcePath == null) return;
    if (!mounted) return;

    setState(() => _busy = true);
    _restoreProgress.value = const RestoreProgress(
      stage: RestoreStage.preparing,
    );
    var progressShown = false;
    try {
      _showRestoreProgressDialog(l10n.restore);
      progressShown = true;
      logger.i('Restore requested: ${kind.name}; source: $sourcePath');
      switch (kind) {
        case _BackupKind.config:
          final settings = await _service.parseConfigBackupFile(
            File(sourcePath),
          );
          await ref.read(settingsProvider.notifier).restoreSettings(settings);
          break;
        case _BackupKind.database:
          await _service.restoreDatabaseFromFile(
            File(sourcePath),
            onProgress: _updateRestoreProgress,
          );
          break;
        case _BackupKind.media:
          await _service.restoreMediaFromFile(
            File(sourcePath),
            onProgress: _updateRestoreProgress,
          );
          break;
        case _BackupKind.all:
          final settings = await _service.restoreFullBackupFromFile(
            File(sourcePath),
            onProgress: _updateRestoreProgress,
          );
          await ref.read(settingsProvider.notifier).restoreSettings(settings);
          break;
      }
      if (kind == _BackupKind.database || kind == _BackupKind.all) {
        await ref.read(accountsProvider.notifier).reloadAccountsAfterRestore();
      }
      if (mounted) {
        logger.i('Restore completed successfully: ${kind.name}');
        _showMessage(l10n.restore_successful);
      }
    } catch (error) {
      logger.e('Restore failed: ${kind.name}', error: error);
      if (mounted) {
        _showMessage(l10n.restore_failed(error.toString()), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      if (mounted && progressShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _updateRestoreProgress(RestoreProgress progress) {
    if (!mounted) return;
    _restoreProgress.value = progress;
  }

  void _showRestoreProgressDialog(String title) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(title),
          content: ValueListenableBuilder<RestoreProgress>(
            valueListenable: _restoreProgress,
            builder: (context, progress, child) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  switch (progress.stage) {
                    RestoreStage.preparing => l10n.restore_preparing,
                    RestoreStage.extracting => l10n.restore_extracting_file(
                      progress.currentFileName,
                    ),
                    RestoreStage.validatingDatabase =>
                      l10n.restore_validating_database,
                    RestoreStage.importingDatabase =>
                      l10n.restore_importing_database,
                    RestoreStage.replacingMedia => l10n.restore_replacing_media,
                  },
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: progress.fraction),
                if (progress.totalFiles > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.restore_progress(
                      progress.completedFiles,
                      progress.totalFiles,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String text, {bool error = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error
            ? theme.colorScheme.error
            : theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: theme.textTheme.bodyLarge),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.backup_and_restore)),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          _buildSectionHeader(context, l10n.backup),
          _buildActionTile(
            context: context,
            icon: Icons.file_copy_outlined,
            title: l10n.backup_config,
            onTap: _busy ? null : () => _backup(_BackupKind.config),
          ),
          _buildActionTile(
            context: context,
            icon: Icons.storage_outlined,
            title: l10n.backup_database,
            onTap: _busy ? null : () => _backup(_BackupKind.database),
          ),
          _buildActionTile(
            context: context,
            icon: Icons.photo_library_outlined,
            title: l10n.backup_medias,
            onTap: _busy ? null : () => _backup(_BackupKind.media),
          ),
          _buildActionTile(
            context: context,
            icon: Icons.backup_outlined,
            title: l10n.backup_all,
            onTap: _busy ? null : () => _backup(_BackupKind.all),
          ),
          _buildSectionHeader(context, l10n.restore),
          _buildActionTile(
            context: context,
            icon: Icons.file_copy_outlined,
            title: l10n.restore_config,
            onTap: _busy ? null : () => _restore(_BackupKind.config),
          ),
          _buildActionTile(
            context: context,
            icon: Icons.storage_outlined,
            title: l10n.restore_database,
            onTap: _busy ? null : () => _restore(_BackupKind.database),
          ),
          _buildActionTile(
            context: context,
            icon: Icons.photo_library_outlined,
            title: l10n.restore_medias,
            onTap: _busy ? null : () => _restore(_BackupKind.media),
          ),
          _buildActionTile(
            context: context,
            icon: Icons.cloud_download_outlined,
            title: l10n.restore_all,
            onTap: _busy ? null : () => _restore(_BackupKind.all),
          ),
        ],
      ),
    );
  }
}

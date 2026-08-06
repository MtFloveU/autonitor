import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/app_settings.dart';
import 'database.dart';
import 'log_service.dart';

typedef BackupProgressCallback = void Function(BackupProgress progress);
typedef RestoreProgressCallback = void Function(RestoreProgress progress);

class BackupProgress {
  const BackupProgress({
    required this.completedFiles,
    required this.totalFiles,
    required this.currentFileName,
  });

  final int completedFiles;
  final int totalFiles;
  final String currentFileName;

  double? get fraction => totalFiles == 0 ? null : completedFiles / totalFiles;
}

enum RestoreStage {
  preparing,
  extracting,
  validatingDatabase,
  importingDatabase,
  replacingMedia,
}

class RestoreProgress {
  const RestoreProgress({
    required this.stage,
    this.completedFiles = 0,
    this.totalFiles = 0,
    this.currentFileName = '',
  });

  final RestoreStage stage;
  final int completedFiles;
  final int totalFiles;
  final String currentFileName;

  double? get fraction => totalFiles == 0 ? null : completedFiles / totalFiles;
}

class BackupCancellationToken {
  bool _isCancelled = false;
  final _listeners = <void Function()>[];

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final listener in List<void Function()>.from(_listeners)) {
      listener();
    }
  }

  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  void throwIfCancelled() {
    if (_isCancelled) throw const BackupCancelledException();
  }
}

class BackupCancelledException implements Exception {
  const BackupCancelledException();

  @override
  String toString() => 'Backup cancelled.';
}

class _ZipSourceFile {
  const _ZipSourceFile(this.file, this.archivePath);

  final File file;
  final String archivePath;
}

/// Creates and restores user data backups. Cookies are intentionally excluded:
/// they remain in platform secure storage and must be entered again after an
/// account database is restored on another device.
class BackupRestoreService {
  BackupRestoreService(this._database);

  static const String configEntryName = 'settings.json';
  static const String databaseEntryName = 'autonitor_data.db';
  static const String manifestEntryName = 'manifest.json';
  static const String mediaDirectoryName = 'media_history';
  static const int _backupFormatVersion = 1;

  static const List<String> _databaseTables = [
    'logged_accounts',
    'account_profile_history',
    'follow_users',
    'follow_users_history',
    'change_reports',
    'media_history',
    'sync_logs',
  ];

  final AppDatabase _database;

  Future<Uint8List> createConfigBackup(
    AppSettings settings, {
    BackupProgressCallback? onProgress,
    BackupCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    onProgress?.call(
      const BackupProgress(
        completedFiles: 0,
        totalFiles: 1,
        currentFileName: configEntryName,
      ),
    );
    final bytes = Uint8List.fromList(
      utf8.encode(
        const JsonEncoder.withIndent('  ').convert(settings.toJson()),
      ),
    );
    cancellationToken?.throwIfCancelled();
    onProgress?.call(
      const BackupProgress(
        completedFiles: 1,
        totalFiles: 1,
        currentFileName: configEntryName,
      ),
    );
    return bytes;
  }

  Future<AppSettings> parseConfigBackup(Uint8List bytes) async {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'The configuration root must be a JSON object.',
        );
      }
      return AppSettings.fromJson(decoded);
    } on FormatException {
      rethrow;
    } catch (error, stackTrace) {
      logger.e(
        'Invalid configuration backup',
        error: error,
        stackTrace: stackTrace,
      );
      throw const FormatException('Invalid configuration file.');
    }
  }

  Future<AppSettings> parseConfigBackupFile(File file) async {
    try {
      return await parseConfigBackup(
        Uint8List.fromList(await file.readAsBytes()),
      );
    } on FileSystemException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid configuration file.');
    }
  }

  Future<Uint8List> createDatabaseBackup({
    BackupProgressCallback? onProgress,
    BackupCancellationToken? cancellationToken,
  }) async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'autonitor_database_backup_',
    );
    final backupFile = File(p.join(temporaryDirectory.path, databaseEntryName));

    try {
      cancellationToken?.throwIfCancelled();
      onProgress?.call(
        const BackupProgress(
          completedFiles: 0,
          totalFiles: 1,
          currentFileName: databaseEntryName,
        ),
      );
      await _createDatabaseSnapshot(backupFile);
      cancellationToken?.throwIfCancelled();
      final bytes = Uint8List.fromList(await backupFile.readAsBytes());
      onProgress?.call(
        const BackupProgress(
          completedFiles: 1,
          totalFiles: 1,
          currentFileName: databaseEntryName,
        ),
      );
      return bytes;
    } finally {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    }
  }

  Future<Uint8List> createMediaBackup({
    BackupProgressCallback? onProgress,
    BackupCancellationToken? cancellationToken,
  }) async {
    logger.i('Starting media backup.');
    final files = await _mediaSourceFiles(cancellationToken);
    final bytes = await _createZipBackup(
      files,
      onProgress: onProgress,
      cancellationToken: cancellationToken,
    );
    logger.i('Media backup archive created with ${files.length} files.');
    return bytes;
  }

  Future<Uint8List> createFullBackup(
    AppSettings settings, {
    BackupProgressCallback? onProgress,
    BackupCancellationToken? cancellationToken,
  }) async {
    logger.i('Starting full backup. Cookies are excluded.');
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'autonitor_full_backup_',
    );
    try {
      cancellationToken?.throwIfCancelled();
      final configFile = File(p.join(temporaryDirectory.path, configEntryName));
      final databaseFile = File(
        p.join(temporaryDirectory.path, databaseEntryName),
      );
      final manifestFile = File(
        p.join(temporaryDirectory.path, manifestEntryName),
      );

      onProgress?.call(
        const BackupProgress(
          completedFiles: 0,
          totalFiles: 0,
          currentFileName: configEntryName,
        ),
      );
      await configFile.writeAsBytes(await createConfigBackup(settings));
      cancellationToken?.throwIfCancelled();

      onProgress?.call(
        const BackupProgress(
          completedFiles: 0,
          totalFiles: 0,
          currentFileName: databaseEntryName,
        ),
      );
      await _createDatabaseSnapshot(databaseFile);
      cancellationToken?.throwIfCancelled();

      final manifest = <String, dynamic>{
        'formatVersion': _backupFormatVersion,
        'type': 'all',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'contents': ['config', 'database', 'media'],
        'cookiesIncluded': false,
      };
      await manifestFile.writeAsString(jsonEncode(manifest));

      final mediaFiles = await _mediaSourceFiles(cancellationToken);
      final sources = <_ZipSourceFile>[
        _ZipSourceFile(configFile, configEntryName),
        _ZipSourceFile(databaseFile, databaseEntryName),
        ...mediaFiles,
        _ZipSourceFile(manifestFile, manifestEntryName),
      ];
      final bytes = await _createZipBackup(
        sources,
        onProgress: onProgress,
        cancellationToken: cancellationToken,
      );
      logger.i('Full backup archive created with ${sources.length} files.');
      return bytes;
    } finally {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    }
  }

  Future<void> restoreDatabase(Uint8List bytes) async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'autonitor_database_restore_',
    );
    final sourceFile = File(p.join(temporaryDirectory.path, databaseEntryName));

    try {
      await sourceFile.writeAsBytes(bytes, flush: true);
      await _restoreDatabaseFile(sourceFile);
    } finally {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    }
  }

  /// Restores a database directly from the selected file. This avoids loading
  /// the entire database into Dart memory on Android.
  Future<void> restoreDatabaseFromFile(
    File sourceFile, {
    RestoreProgressCallback? onProgress,
  }) async {
    if (!await sourceFile.exists()) {
      throw const FileSystemException(
        'The selected backup file is unavailable.',
      );
    }
    onProgress?.call(
      const RestoreProgress(stage: RestoreStage.validatingDatabase),
    );
    await _restoreDatabaseFile(
      sourceFile,
      onBeforeImport: () => onProgress?.call(
        const RestoreProgress(stage: RestoreStage.importingDatabase),
      ),
    );
  }

  Future<void> restoreMedia(Uint8List bytes) async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'autonitor_media_restore_',
    );
    try {
      final sourceFile = File(p.join(temporaryDirectory.path, 'backup.zip'));
      await sourceFile.writeAsBytes(bytes, flush: true);
      await restoreMediaFromFile(sourceFile);
    } finally {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    }
  }

  /// Extracts media in a worker isolate and copies it from disk afterwards.
  /// Keeping archive entries on disk prevents a full media backup from being
  /// decompressed into the UI isolate at once.
  Future<void> restoreMediaFromFile(
    File sourceFile, {
    RestoreProgressCallback? onProgress,
  }) async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'autonitor_media_restore_',
    );
    try {
      await _extractBackupArchiveInWorker(
        sourcePath: sourceFile.path,
        outputDirectory: temporaryDirectory.path,
        onProgress: onProgress,
      );
      onProgress?.call(
        const RestoreProgress(stage: RestoreStage.replacingMedia),
      );
      await _replaceMediaDirectory(
        Directory(p.join(temporaryDirectory.path, mediaDirectoryName)),
      );
    } finally {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    }
  }

  /// Restores the settings, database and media embedded in an all-data archive.
  /// Cookies are never present in the archive and are deliberately untouched.
  Future<AppSettings> restoreFullBackup(Uint8List bytes) async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'autonitor_full_restore_',
    );
    try {
      final sourceFile = File(p.join(temporaryDirectory.path, 'backup.zip'));
      await sourceFile.writeAsBytes(bytes, flush: true);
      return restoreFullBackupFromFile(sourceFile);
    } finally {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    }
  }

  Future<AppSettings> restoreFullBackupFromFile(
    File sourceFile, {
    RestoreProgressCallback? onProgress,
  }) async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'autonitor_full_restore_',
    );
    try {
      final extracted = await _extractBackupArchiveInWorker(
        sourcePath: sourceFile.path,
        outputDirectory: temporaryDirectory.path,
        onProgress: onProgress,
      );
      if (!extracted['hasManifest']! ||
          !extracted['hasConfig']! ||
          !extracted['hasDatabase']!) {
        throw const FormatException('This is not a complete Autonitor backup.');
      }

      final manifestFile = File(
        p.join(temporaryDirectory.path, manifestEntryName),
      );
      final manifestJson = jsonDecode(await manifestFile.readAsString());
      if (manifestJson is! Map<String, dynamic> ||
          manifestJson['type'] != 'all' ||
          manifestJson['formatVersion'] != _backupFormatVersion) {
        throw const FormatException('Unsupported Autonitor backup format.');
      }

      onProgress?.call(
        const RestoreProgress(stage: RestoreStage.validatingDatabase),
      );
      final settings = await parseConfigBackupFile(
        File(p.join(temporaryDirectory.path, configEntryName)),
      );
      final databaseFile = File(
        p.join(temporaryDirectory.path, databaseEntryName),
      );

      // Validate every component before changing application data.
      await _validateDatabaseFile(databaseFile);
      onProgress?.call(
        const RestoreProgress(stage: RestoreStage.importingDatabase),
      );
      await _restoreDatabaseFile(databaseFile, skipValidation: true);
      onProgress?.call(
        const RestoreProgress(stage: RestoreStage.replacingMedia),
      );
      await _replaceMediaDirectory(
        Directory(p.join(temporaryDirectory.path, mediaDirectoryName)),
      );
      return settings;
    } finally {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    }
  }

  Future<void> _createDatabaseSnapshot(File backupFile) async {
    // VACUUM INTO asks SQLite to create a consistent snapshot even while the
    // application keeps its normal database connection open. SQLite does not
    // reliably support a bound parameter for this statement on every bundled
    // SQLite version, so use an escaped application-generated path instead.
    final escapedPath = backupFile.path.replaceAll("'", "''");
    await _database.customStatement("VACUUM INTO '$escapedPath'");
  }

  Future<List<_ZipSourceFile>> _mediaSourceFiles(
    BackupCancellationToken? cancellationToken,
  ) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final mediaDirectory = Directory(
      p.join(supportDirectory.path, mediaDirectoryName),
    );
    if (!await mediaDirectory.exists()) return [];

    final files = <_ZipSourceFile>[];
    await for (final entity in mediaDirectory.list(recursive: true)) {
      cancellationToken?.throwIfCancelled();
      if (entity is! File) continue;
      final relativePath = p.relative(entity.path, from: supportDirectory.path);
      files.add(_ZipSourceFile(entity, relativePath));
    }
    return files;
  }

  Future<Uint8List> _createZipBackup(
    List<_ZipSourceFile> files, {
    BackupProgressCallback? onProgress,
    BackupCancellationToken? cancellationToken,
  }) async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'autonitor_zip_backup_',
    );
    final outputFile = File(p.join(temporaryDirectory.path, 'backup.zip'));
    try {
      await _encodeZipInWorker(
        outputPath: outputFile.path,
        files: files,
        onProgress: onProgress,
        cancellationToken: cancellationToken,
      );
      cancellationToken?.throwIfCancelled();
      return Uint8List.fromList(await outputFile.readAsBytes());
    } finally {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    }
  }

  Future<void> _encodeZipInWorker({
    required String outputPath,
    required List<_ZipSourceFile> files,
    BackupProgressCallback? onProgress,
    BackupCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    final events = ReceivePort();
    final completion = Completer<void>();
    SendPort? workerCommands;
    late final void Function() cancellationListener;

    cancellationListener = () {
      workerCommands?.send('cancel');
    };
    cancellationToken?.addListener(cancellationListener);

    final subscription = events.listen((message) {
      if (message is List) {
        if (!completion.isCompleted) {
          completion.completeError(StateError('ZIP worker failed: $message'));
        }
        return;
      }
      final event = Map<String, dynamic>.from(message as Map);
      switch (event['type']) {
        case 'ready':
          workerCommands = event['commands'] as SendPort;
          if (cancellationToken?.isCancelled == true) {
            workerCommands!.send('cancel');
          }
          break;
        case 'progress':
          final progress = BackupProgress(
            completedFiles: event['completedFiles'] as int,
            totalFiles: event['totalFiles'] as int,
            currentFileName: event['currentFileName'] as String,
          );
          logger.d(
            'Compressing backup file ${progress.completedFiles + 1}/${progress.totalFiles}: ${progress.currentFileName}',
          );
          onProgress?.call(progress);
          break;
        case 'complete':
          if (!completion.isCompleted) completion.complete();
          break;
        case 'cancelled':
          if (!completion.isCompleted) {
            completion.completeError(const BackupCancelledException());
          }
          break;
        case 'error':
          if (!completion.isCompleted) {
            completion.completeError(StateError(event['message'] as String));
          }
          break;
      }
    });

    try {
      await Isolate.spawn(_zipBackupWorker, {
        'events': events.sendPort,
        'outputPath': outputPath,
        'files': [
          for (final file in files)
            {'path': file.file.path, 'archivePath': file.archivePath},
        ],
      }, onError: events.sendPort);
      await completion.future;
    } finally {
      cancellationToken?.removeListener(cancellationListener);
      await subscription.cancel();
      events.close();
    }
  }

  Future<Map<String, bool>> _extractBackupArchiveInWorker({
    required String sourcePath,
    required String outputDirectory,
    RestoreProgressCallback? onProgress,
  }) async {
    final events = ReceivePort();
    final completion = Completer<Map<String, bool>>();
    final subscription = events.listen((message) {
      if (message is List) {
        if (!completion.isCompleted) {
          completion.completeError(
            StateError('Archive extraction worker failed: $message'),
          );
        }
        return;
      }
      if (message is! Map) return;
      final event = Map<String, dynamic>.from(message);
      switch (event['type']) {
        case 'progress':
          onProgress?.call(
            RestoreProgress(
              stage: RestoreStage.extracting,
              completedFiles: event['completedFiles'] as int,
              totalFiles: event['totalFiles'] as int,
              currentFileName: event['currentFileName'] as String,
            ),
          );
          break;
        case 'complete':
          if (!completion.isCompleted) {
            completion.complete(
              Map<String, bool>.from(event['extracted'] as Map),
            );
          }
          break;
        case 'error':
          if (!completion.isCompleted) {
            completion.completeError(
              FormatException(event['message'] as String),
            );
          }
          break;
      }
    });
    try {
      await Isolate.spawn(_extractBackupArchiveWorker, {
        'events': events.sendPort,
        'sourcePath': sourcePath,
        'outputDirectory': outputDirectory,
      }, onError: events.sendPort);
      return await completion.future;
    } finally {
      await subscription.cancel();
      events.close();
    }
  }

  Future<void> _replaceMediaDirectory(Directory stagedMediaDirectory) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final mediaDirectory = Directory(
      p.join(supportDirectory.path, mediaDirectoryName),
    );

    if (await mediaDirectory.exists()) {
      await mediaDirectory.delete(recursive: true);
    }
    await mediaDirectory.create(recursive: true);
    if (!await stagedMediaDirectory.exists()) return;

    await for (final entity in stagedMediaDirectory.list(recursive: true)) {
      if (entity is! File) continue;
      final relativePath = p.relative(
        entity.path,
        from: stagedMediaDirectory.path,
      );
      final target = File(p.join(mediaDirectory.path, relativePath));
      await target.parent.create(recursive: true);
      await entity.copy(target.path);
    }
  }

  Future<void> _restoreDatabaseFile(
    File sourceFile, {
    bool skipValidation = false,
    void Function()? onBeforeImport,
  }) async {
    if (!skipValidation) await _validateDatabaseFile(sourceFile);
    onBeforeImport?.call();
    await _database.customStatement('ATTACH DATABASE ? AS restore_source', [
      sourceFile.path,
    ]);
    try {
      await _database.customStatement('PRAGMA foreign_keys = OFF');
      await _database.transaction(() async {
        // Child tables must be cleared before their referenced account rows.
        for (final table in _databaseTables.reversed) {
          await _database.customStatement('DELETE FROM $table');
        }
        for (final table in _databaseTables) {
          await _database.customStatement(
            'INSERT INTO $table SELECT * FROM restore_source.$table',
          );
        }
      });
    } finally {
      await _database.customStatement('PRAGMA foreign_keys = ON');
      await _database.customStatement('DETACH DATABASE restore_source');
    }
  }

  Future<void> _validateDatabaseFile(File sourceFile) async {
    await _database.customStatement('ATTACH DATABASE ? AS validation_source', [
      sourceFile.path,
    ]);
    try {
      final rows = await _database
          .customSelect(
            "SELECT name FROM validation_source.sqlite_master WHERE type = 'table'",
          )
          .get();
      final tables = rows.map((row) => row.read<String>('name')).toSet();
      if (!_databaseTables.every(tables.contains)) {
        throw const FormatException(
          'The selected database is not an Autonitor backup.',
        );
      }
      for (final table in _databaseTables) {
        final currentColumns = await _tableColumns('main', table);
        final sourceColumns = await _tableColumns('validation_source', table);
        if (currentColumns.length != sourceColumns.length ||
            !currentColumns.toSet().containsAll(sourceColumns)) {
          throw const FormatException(
            'The selected database is incompatible with this app version.',
          );
        }
      }
    } finally {
      await _database.customStatement('DETACH DATABASE validation_source');
    }
  }

  Future<List<String>> _tableColumns(String database, String table) async {
    final rows = await _database
        .customSelect('PRAGMA $database.table_info($table)')
        .get();
    return rows.map((row) => row.read<String>('name')).toList();
  }
}

/// Extracts only the files used by Autonitor. This runs in a dedicated isolate
/// so ZIP decompression neither blocks rendering nor retains every media entry
/// in the UI isolate's heap.
Map<String, bool> _extractBackupArchiveToDirectory(
  String sourcePath,
  String outputDirectory,
  void Function(int completedFiles, int totalFiles, String currentFileName)?
  onProgress,
) {
  final sourceFile = File(sourcePath);
  if (!sourceFile.existsSync()) {
    throw const FileSystemException('The selected backup file is unavailable.');
  }

  final outputRoot = Directory(outputDirectory)..createSync(recursive: true);
  final input = InputFileStream(sourcePath);
  Archive? archive;
  final extracted = <String, bool>{
    'hasManifest': false,
    'hasConfig': false,
    'hasDatabase': false,
  };

  try {
    archive = ZipDecoder().decodeStream(input, verify: true);
    final files = <(ArchiveFile, String)>[];
    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      final relativePath = _archiveEntryRelativePath(entry.name);
      if (relativePath != null) files.add((entry, relativePath));
    }

    for (var index = 0; index < files.length; index++) {
      final (entry, relativePath) = files[index];
      onProgress?.call(index, files.length, relativePath);
      if (relativePath == BackupRestoreService.manifestEntryName) {
        extracted['hasManifest'] = true;
      } else if (relativePath == BackupRestoreService.configEntryName) {
        extracted['hasConfig'] = true;
      } else if (relativePath == BackupRestoreService.databaseEntryName) {
        extracted['hasDatabase'] = true;
      }

      final target = File(p.join(outputRoot.path, relativePath));
      target.parent.createSync(recursive: true);
      final output = OutputFileStream(target.path);
      try {
        entry.writeContent(output);
      } finally {
        output.closeSync();
        entry.clear();
      }
      onProgress?.call(index + 1, files.length, relativePath);
    }
    return extracted;
  } catch (error) {
    if (error is FormatException || error is FileSystemException) rethrow;
    throw const FormatException('Invalid or corrupted ZIP backup.');
  } finally {
    for (final entry in archive?.files ?? const <ArchiveFile>[]) {
      entry.closeSync();
    }
    input.closeSync();
  }
}

String? _archiveEntryRelativePath(String entryName) {
  if (entryName == BackupRestoreService.manifestEntryName ||
      entryName == BackupRestoreService.configEntryName ||
      entryName == BackupRestoreService.databaseEntryName) {
    return entryName;
  }

  final normalized = p.posix.normalize(entryName);
  final claimedMediaPath = entryName.startsWith(
    '${BackupRestoreService.mediaDirectoryName}/',
  );
  final isSafeMediaPath =
      normalized.startsWith('${BackupRestoreService.mediaDirectoryName}/') &&
      !normalized.contains('../') &&
      !p.posix.isAbsolute(normalized) &&
      !entryName.contains('\\\\');
  if (claimedMediaPath && !isSafeMediaPath) {
    throw const FormatException('Unsafe media file path in backup.');
  }
  return isSafeMediaPath ? normalized : null;
}

void _extractBackupArchiveWorker(Map<String, dynamic> request) {
  final events = request['events'] as SendPort;
  try {
    final extracted = _extractBackupArchiveToDirectory(
      request['sourcePath'] as String,
      request['outputDirectory'] as String,
      (completedFiles, totalFiles, currentFileName) => events.send({
        'type': 'progress',
        'completedFiles': completedFiles,
        'totalFiles': totalFiles,
        'currentFileName': currentFileName,
      }),
    );
    events.send({'type': 'complete', 'extracted': extracted});
  } catch (error) {
    events.send({'type': 'error', 'message': error.toString()});
  }
}

/// Runs outside Flutter's UI isolate so ZIP compression cannot block progress
/// rendering or cancellation taps. The worker checks for cancellation between
/// files, which also keeps its archive output in a valid state until discarded.
Future<void> _zipBackupWorker(Map<String, dynamic> request) async {
  final events = request['events'] as SendPort;
  final commandPort = ReceivePort();
  var cancelled = false;
  final commandSubscription = commandPort.listen((message) {
    if (message == 'cancel') cancelled = true;
  });
  events.send({'type': 'ready', 'commands': commandPort.sendPort});

  final outputPath = request['outputPath'] as String;
  final files = (request['files'] as List)
      .map((file) => Map<String, String>.from(file as Map))
      .toList();
  final encoder = ZipFileEncoder();
  var encoderCreated = false;
  var encoderClosed = false;

  try {
    encoder.create(outputPath);
    encoderCreated = true;
    for (var index = 0; index < files.length; index++) {
      if (cancelled) {
        events.send({'type': 'cancelled'});
        return;
      }
      final file = files[index];
      events.send({
        'type': 'progress',
        'completedFiles': index,
        'totalFiles': files.length,
        'currentFileName': file['archivePath']!,
      });
      await encoder.addFile(File(file['path']!), file['archivePath']);
      await Future<void>.delayed(Duration.zero);
    }
    if (cancelled) {
      events.send({'type': 'cancelled'});
      return;
    }
    await encoder.close();
    encoderClosed = true;
    events.send({'type': 'complete'});
  } catch (error, stackTrace) {
    events.send({'type': 'error', 'message': '$error\n$stackTrace'});
  } finally {
    if (encoderCreated && !encoderClosed) {
      try {
        await encoder.close();
      } catch (_) {
        // The incomplete temporary ZIP is removed by the caller.
      }
    }
    await commandSubscription.cancel();
    commandPort.close();
  }
}

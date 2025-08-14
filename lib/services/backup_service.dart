import 'dart:async';
import 'dart:developer' as developer;
import '../models/backup_settings.dart';
import '../models/backup_info.dart';
import 'backup_exceptions.dart';
import 'restore_service.dart';
import 'json_export_service.dart';
import 'auto_backup_service.dart';
import 'sql_export_service.dart';
import 'file_management_service.dart';

/// Main service class for managing backup operations
class BackupService {
  static BackupService? _instance;
  static BackupService get instance => _instance ??= BackupService._();
  
  /// Reset the singleton instance (for testing purposes)
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  BackupService._() {
    _restoreService = RestoreService();
    _jsonExportService = JsonExportService();
    _autoBackupService = AutoBackupService();
    _sqlExportService = SqlExportService();
    _fileManagementService = FileManagementService();
  }

  // Internal state
  BackupSettings? _currentSettings;
  final StreamController<String> _progressController =
      StreamController<String>.broadcast();
  final StreamController<double> _progressPercentController =
      StreamController<double>.broadcast();

  // Service dependencies
  late final RestoreService _restoreService;
  late final JsonExportService _jsonExportService;
  late final AutoBackupService _autoBackupService;
  late final SqlExportService _sqlExportService;
  late final FileManagementService _fileManagementService;

  /// Stream for progress updates during backup operations
  Stream<String> get progressStream => _progressController.stream;
  
  /// Stream for progress percentage updates (0.0 to 1.0)
  Stream<double> get progressPercentStream => _progressPercentController.stream;

  // JSON Export Methods

  /// Export all database data to JSON format
  /// Returns the file path of the created JSON backup
  Future<String> exportToJson() async {
    try {
      _logOperation('Starting JSON export');
      _progressController.add('Starting JSON export...');
      _progressPercentController.add(0.0);

      // Check permissions first
      _progressController.add('Checking file permissions...');
      _progressPercentController.add(0.1);
      
      if (!await _fileManagementService.hasWritePermission()) {
        await _fileManagementService.requestWritePermission();
      }

      _progressController.add('Collecting data from all tables...');
      _progressPercentController.add(0.3);

      final filePath = await _jsonExportService.exportAllTablesToJson();

      _progressController.add('JSON export completed successfully');
      _progressController.add('File saved to: $filePath');
      _progressPercentController.add(1.0);

      _logOperation('JSON export completed successfully: $filePath');
      return filePath;
    } on BackupException catch (e) {
      _logError('JSON export failed', e);
      _progressController.add('JSON export failed: ${e.message}');
      _progressPercentController.add(0.0);
      rethrow;
    } catch (e) {
      final backupException = BackupException(
        'Failed to export data to JSON',
        code: 'JSON_EXPORT_ERROR',
        originalError: e,
      );
      _logError('JSON export failed', backupException);
      _progressController.add('JSON export failed: ${e.toString()}');
      _progressPercentController.add(0.0);
      throw backupException;
    }
  }

  /// Export all database data to SQL format
  /// Returns the file path of the created SQL backup
  Future<String> exportToSql() async {
    try {
      _logOperation('Starting SQL export');
      _progressController.add('Starting SQL export...');
      _progressPercentController.add(0.0);

      // Check permissions first
      _progressController.add('Checking file permissions...');
      _progressPercentController.add(0.1);
      
      if (!await _fileManagementService.hasWritePermission()) {
        await _fileManagementService.requestWritePermission();
      }

      _progressController.add('Generating SQL statements...');
      _progressPercentController.add(0.3);

      final filePath = await _sqlExportService.exportTimestampedBackup();

      _progressController.add('SQL export completed successfully');
      _progressController.add('File saved to: $filePath');
      _progressPercentController.add(1.0);

      _logOperation('SQL export completed successfully: $filePath');
      return filePath;
    } on BackupException catch (e) {
      _logError('SQL export failed', e);
      _progressController.add('SQL export failed: ${e.message}');
      _progressPercentController.add(0.0);
      rethrow;
    } catch (e) {
      final backupException = BackupException(
        'Failed to export data to SQL',
        code: 'SQL_EXPORT_ERROR',
        originalError: e,
      );
      _logError('SQL export failed', backupException);
      _progressController.add('SQL export failed: ${e.toString()}');
      _progressPercentController.add(0.0);
      throw backupException;
    }
  }

  // Auto Backup Methods

  /// Enable automatic daily backup
  Future<void> enableAutoBackup() async {
    try {
      _logOperation('Enabling auto backup');
      _progressController.add('Enabling auto backup...');
      
      final settings = await getBackupSettings();
      final updatedSettings = settings.copyWith(autoBackupEnabled: true);
      await saveBackupSettings(updatedSettings);

      _progressController.add('Auto backup enabled');
      _logOperation('Auto backup enabled successfully');
    } on BackupException catch (e) {
      _logError('Failed to enable auto backup', e);
      rethrow;
    } catch (e) {
      final backupException = BackupException(
        'Failed to enable auto backup',
        code: 'AUTO_BACKUP_ENABLE_ERROR',
        originalError: e,
      );
      _logError('Failed to enable auto backup', backupException);
      throw backupException;
    }
  }

  /// Disable automatic daily backup
  Future<void> disableAutoBackup() async {
    try {
      _logOperation('Disabling auto backup');
      _progressController.add('Disabling auto backup...');
      
      final settings = await getBackupSettings();
      final updatedSettings = settings.copyWith(autoBackupEnabled: false);
      await saveBackupSettings(updatedSettings);

      _progressController.add('Auto backup disabled');
      _logOperation('Auto backup disabled successfully');
    } on BackupException catch (e) {
      _logError('Failed to disable auto backup', e);
      rethrow;
    } catch (e) {
      final backupException = BackupException(
        'Failed to disable auto backup',
        code: 'AUTO_BACKUP_DISABLE_ERROR',
        originalError: e,
      );
      _logError('Failed to disable auto backup', backupException);
      throw backupException;
    }
  }

  /// Perform daily backup if needed
  Future<void> performDailyBackup() async {
    try {
      _logOperation('Starting daily backup check');
      _progressController.add('Checking daily backup...');
      _progressPercentController.add(0.0);

      final settings = await getBackupSettings();
      if (!settings.autoBackupEnabled) {
        _progressController.add('Auto backup is disabled');
        _logOperation('Daily backup skipped - auto backup disabled');
        return;
      }

      _progressController.add('Checking if backup needed...');
      _progressPercentController.add(0.2);

      // Check if backup already exists for today
      final fileName = _sqlExportService.generateDailyBackupFileName();
      final backupExists = await _fileManagementService.backupFileExists(fileName);
      
      if (backupExists) {
        _progressController.add('Daily backup skipped - already exists for today');
        _logOperation('Daily backup skipped - file already exists: $fileName');
        return;
      }

      _progressController.add('Performing daily backup...');
      _progressPercentController.add(0.4);

      final filePath = await _autoBackupService.performAutoBackup(settings);

      if (filePath != null) {
        _progressController.add('Updating backup settings...');
        _progressPercentController.add(0.8);

        // Update last backup time
        final updatedSettings = settings.copyWith(
          lastBackupTime: DateTime.now(),
        );
        await saveBackupSettings(updatedSettings);

        _progressController.add('Daily backup completed: $filePath');
        _progressPercentController.add(1.0);
        _logOperation('Daily backup completed successfully: $filePath');

        // Clean old backups
        await _cleanOldBackupsInternal();
      } else {
        _progressController.add('Daily backup failed - no file created');
        _logError('Daily backup failed - no file created', null);
      }
    } on BackupException catch (e) {
      _logError('Daily backup failed', e);
      _progressController.add('Daily backup failed: ${e.message}');
      _progressPercentController.add(0.0);
      rethrow;
    } catch (e) {
      final backupException = BackupException(
        'Failed to perform daily backup',
        code: 'DAILY_BACKUP_ERROR',
        originalError: e,
      );
      _logError('Daily backup failed', backupException);
      _progressController.add('Daily backup failed: ${e.toString()}');
      _progressPercentController.add(0.0);
      throw backupException;
    }
  }

  /// Check if auto backup is enabled
  bool isAutoBackupEnabled() {
    return _currentSettings?.autoBackupEnabled ?? false;
  }

  /// Get the last backup time
  DateTime? getLastBackupTime() {
    return _currentSettings?.lastBackupTime;
  }

  // Restore Methods

  /// Restore data from a backup file
  Future<void> restoreFromFile(String filePath) async {
    try {
      _logOperation('Starting restore from file: $filePath');
      _progressController.add('Starting restore from file...');
      _progressPercentController.add(0.0);

      _progressController.add('Validating backup file...');
      _progressPercentController.add(0.1);

      // Validate file exists and is readable
      if (!await _fileManagementService.backupFileExists(filePath.split('/').last)) {
        throw RestoreException(
          'Backup file not found: $filePath',
          code: 'FILE_NOT_FOUND',
        );
      }

      _progressController.add('Creating emergency backup...');
      _progressPercentController.add(0.2);

      // Create emergency backup before restore
      await _createEmergencyBackup();

      _progressController.add('Restoring data from backup...');
      _progressPercentController.add(0.4);

      await _restoreService.restoreFromSqlFile(filePath);

      _progressController.add('Verifying restored data...');
      _progressPercentController.add(0.8);

      // Verify restore integrity
      final isValid = await _restoreService.verifyRestoreIntegrity();
      if (!isValid) {
        throw RestoreException(
          'Restore verification failed - data integrity check failed',
          code: 'VERIFICATION_FAILED',
        );
      }

      _progressController.add('Restore completed successfully');
      _progressPercentController.add(1.0);
      _logOperation('Restore completed successfully from: $filePath');
    } on BackupException catch (e) {
      _logError('Restore failed', e);
      _progressController.add('Restore failed: ${e.message}');
      _progressPercentController.add(0.0);
      rethrow;
    } catch (e) {
      final restoreException = RestoreException(
        'Failed to restore from file: $filePath',
        code: 'RESTORE_ERROR',
        originalError: e,
      );
      _logError('Restore failed', restoreException);
      _progressController.add('Restore failed: ${e.toString()}');
      _progressPercentController.add(0.0);
      throw restoreException;
    }
  }

  // File Management Methods

  /// Clean old backup files (older than maxBackupDays)
  Future<void> cleanOldBackups() async {
    try {
      _logOperation('Starting cleanup of old backup files');
      _progressController.add('Cleaning old backup files...');
      _progressPercentController.add(0.0);

      await _cleanOldBackupsInternal();

      _progressController.add('Old backup files cleaned successfully');
      _progressPercentController.add(1.0);
      _logOperation('Old backup files cleaned successfully');
    } on BackupException catch (e) {
      _logError('Failed to clean old backups', e);
      _progressController.add('Failed to clean old backups: ${e.message}');
      _progressPercentController.add(0.0);
      rethrow;
    } catch (e) {
      final backupException = BackupException(
        'Failed to clean old backups',
        code: 'CLEANUP_ERROR',
        originalError: e,
      );
      _logError('Failed to clean old backups', backupException);
      _progressController.add('Failed to clean old backups: ${e.toString()}');
      _progressPercentController.add(0.0);
      throw backupException;
    }
  }

  /// Get list of available backup files
  Future<List<BackupInfo>> getBackupFiles() async {
    try {
      _logOperation('Getting list of backup files');
      
      final filePaths = await _fileManagementService.getBackupFiles();
      final backupInfoList = <BackupInfo>[];

      for (final filePath in filePaths) {
        final fileName = filePath.split('/').last;
        final fileSize = await _fileManagementService.getBackupFileSize(fileName);
        
        // Determine backup type from file extension
        BackupType type;
        if (fileName.endsWith('.json')) {
          type = BackupType.json;
        } else if (fileName.endsWith('.sql')) {
          type = BackupType.sql;
        } else {
          continue; // Skip unknown file types
        }

        // Parse creation date from filename or file system
        DateTime createdAt;
        try {
          // Try to parse timestamp from filename
          if (fileName.contains('backup_')) {
            final timestampPart = fileName.split('backup_')[1].split('.')[0];
            final parts = timestampPart.split('_');
            if (parts.length == 2) {
              final datePart = parts[0];
              final timePart = parts[1];
              final dateComponents = datePart.split('-');
              final timeComponents = timePart.split('-');
              
              if (dateComponents.length == 3 && timeComponents.length == 3) {
                createdAt = DateTime(
                  int.parse(dateComponents[0]),
                  int.parse(dateComponents[1]),
                  int.parse(dateComponents[2]),
                  int.parse(timeComponents[0]),
                  int.parse(timeComponents[1]),
                  int.parse(timeComponents[2]),
                );
              } else {
                createdAt = DateTime.now(); // Fallback
              }
            } else {
              createdAt = DateTime.now(); // Fallback
            }
          } else {
            createdAt = DateTime.now(); // Fallback for daily backups
          }
        } catch (e) {
          createdAt = DateTime.now(); // Fallback
        }

        final backupInfo = BackupInfo(
          fileName: fileName,
          createdAt: createdAt,
          fileSize: fileSize,
          type: type,
          isValid: true, // Assume valid for now, could add validation
        );

        backupInfoList.add(backupInfo);
      }

      // Sort by creation date (newest first)
      backupInfoList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _logOperation('Found ${backupInfoList.length} backup files');
      return backupInfoList;
    } on BackupException catch (e) {
      _logError('Failed to get backup files', e);
      rethrow;
    } catch (e) {
      final backupException = BackupException(
        'Failed to get backup files',
        code: 'FILE_LIST_ERROR',
        originalError: e,
      );
      _logError('Failed to get backup files', backupException);
      throw backupException;
    }
  }

  // Settings Methods

  /// Save backup settings to persistent storage
  Future<void> saveBackupSettings(BackupSettings settings) async {
    try {
      _logOperation('Saving backup settings');
      
      // Get the actual backup directory from file management service
      final backupDir = await _fileManagementService.getBackupDirectory();
      final updatedSettings = settings.copyWith(backupDirectory: backupDir);
      
      // Store in memory (in a real app, this would be persisted to SharedPreferences or database)
      _currentSettings = updatedSettings;

      _progressController.add('Backup settings saved');
      _logOperation('Backup settings saved successfully');
    } on BackupException catch (e) {
      _logError('Failed to save backup settings', e);
      rethrow;
    } catch (e) {
      final backupException = BackupException(
        'Failed to save backup settings',
        code: 'SETTINGS_SAVE_ERROR',
        originalError: e,
      );
      _logError('Failed to save backup settings', backupException);
      throw backupException;
    }
  }

  /// Get backup settings from persistent storage
  Future<BackupSettings> getBackupSettings() async {
    try {
      // Return cached settings if available
      if (_currentSettings != null) {
        return _currentSettings!;
      }

      // Load default settings (in a real app, this would load from SharedPreferences or database)
      final backupDir = await _fileManagementService.getBackupDirectory();
      _currentSettings = BackupSettings(
        autoBackupEnabled: false,
        backupDirectory: backupDir,
      );

      _logOperation('Loaded default backup settings');
      return _currentSettings!;
    } on BackupException catch (e) {
      _logError('Failed to get backup settings', e);
      rethrow;
    } catch (e) {
      final backupException = BackupException(
        'Failed to get backup settings',
        code: 'SETTINGS_LOAD_ERROR',
        originalError: e,
      );
      _logError('Failed to get backup settings', backupException);
      throw backupException;
    }
  }

  /// Validate backup file format and integrity
  Future<bool> validateBackupFile(String filePath) async {
    try {
      return await _restoreService.validateBackupFile(filePath);
    } catch (e) {
      throw BackupException(
        'Failed to validate backup file',
        code: 'VALIDATION_ERROR',
        originalError: e,
      );
    }
  }

  /// Get backup directory path
  Future<String> getBackupDirectory() async {
    try {
      return await _fileManagementService.getBackupDirectory();
    } on BackupException catch (e) {
      _logError('Failed to get backup directory', e);
      rethrow;
    } catch (e) {
      final backupException = BackupException(
        'Failed to get backup directory',
        code: 'DIRECTORY_ERROR',
        originalError: e,
      );
      _logError('Failed to get backup directory', backupException);
      throw backupException;
    }
  }

  /// Get storage information
  Future<int> getAvailableStorageSpace() async {
    try {
      return await _fileManagementService.getAvailableStorageSpace();
    } on BackupException catch (e) {
      _logError('Failed to get storage space', e);
      rethrow;
    } catch (e) {
      final backupException = BackupException(
        'Failed to get storage space',
        code: 'STORAGE_ERROR',
        originalError: e,
      );
      _logError('Failed to get storage space', backupException);
      throw backupException;
    }
  }

  /// Delete a specific backup file
  Future<void> deleteBackupFile(String fileName) async {
    try {
      _logOperation('Deleting backup file: $fileName');
      _progressController.add('Deleting backup file: $fileName');
      
      await _fileManagementService.deleteBackupFile(fileName);
      
      _progressController.add('Backup file deleted successfully');
      _logOperation('Backup file deleted successfully: $fileName');
    } on BackupException catch (e) {
      _logError('Failed to delete backup file', e);
      _progressController.add('Failed to delete backup file: ${e.message}');
      rethrow;
    } catch (e) {
      final backupException = BackupException(
        'Failed to delete backup file: $fileName',
        code: 'FILE_DELETE_ERROR',
        originalError: e,
      );
      _logError('Failed to delete backup file', backupException);
      _progressController.add('Failed to delete backup file: ${e.toString()}');
      throw backupException;
    }
  }

  // Private helper methods

  /// Internal method to clean old backups without progress reporting
  Future<void> _cleanOldBackupsInternal() async {
    final settings = await getBackupSettings();
    await _fileManagementService.deleteOldBackups(maxDays: settings.maxBackupDays);
  }

  /// Create emergency backup before destructive operations
  Future<void> _createEmergencyBackup() async {
    try {
      _logOperation('Creating emergency backup');
      final emergencyFileName = 'emergency_backup_${DateTime.now().millisecondsSinceEpoch}.sql';
      final sqlContent = await _sqlExportService.exportToSql();
      await _fileManagementService.createBackupFile(emergencyFileName, sqlContent);
      _logOperation('Emergency backup created: $emergencyFileName');
    } catch (e) {
      _logError('Failed to create emergency backup', e);
      // Don't throw here - emergency backup failure shouldn't stop the main operation
    }
  }

  /// Log operation for debugging
  void _logOperation(String message) {
    developer.log(
      message,
      name: 'BackupService',
      level: 800, // INFO level
    );
  }

  /// Log error for debugging
  void _logError(String message, dynamic error) {
    developer.log(
      message,
      name: 'BackupService',
      level: 1000, // ERROR level
      error: error,
      stackTrace: error is Error ? error.stackTrace : null,
    );
  }

  /// Dispose resources
  void dispose() {
    if (!_progressController.isClosed) {
      _progressController.close();
    }
    if (!_progressPercentController.isClosed) {
      _progressPercentController.close();
    }
  }
}

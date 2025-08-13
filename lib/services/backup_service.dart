import 'dart:async';
import '../models/backup_settings.dart';
import '../models/backup_info.dart';
import 'backup_exceptions.dart';
import 'restore_service.dart';
import 'json_export_service.dart';

/// Main service class for managing backup operations
class BackupService {
  static BackupService? _instance;
  static BackupService get instance => _instance ??= BackupService._();
  
  BackupService._() {
    _restoreService = RestoreService();
    _jsonExportService = JsonExportService();
  }
  
  // Internal state
  BackupSettings? _currentSettings;
  final StreamController<String> _progressController = StreamController<String>.broadcast();
  
  // Service dependencies
  late final RestoreService _restoreService;
  late final JsonExportService _jsonExportService;
  
  /// Stream for progress updates during backup operations
  Stream<String> get progressStream => _progressController.stream;
  
  // JSON Export Methods
  
  /// Export all database data to JSON format
  /// Returns the file path of the created JSON backup
  Future<String> exportToJson() async {
    try {
      _progressController.add('Starting JSON export...');
      _progressController.add('Collecting data from all tables...');
      
      final filePath = await _jsonExportService.exportAllTablesToJson();
      
      _progressController.add('JSON export completed successfully');
      _progressController.add('File saved to: $filePath');
      
      return filePath;
      
    } on BackupException {
      rethrow;
    } catch (e) {
      throw BackupException(
        'Failed to export data to JSON',
        code: 'JSON_EXPORT_ERROR',
        originalError: e,
      );
    }
  }
  
  // Auto Backup Methods
  
  /// Enable automatic daily backup
  Future<void> enableAutoBackup() async {
    try {
      final settings = await getBackupSettings();
      final updatedSettings = settings.copyWith(autoBackupEnabled: true);
      await saveBackupSettings(updatedSettings);
      
      // TODO: Schedule auto backup in task 5
      _progressController.add('Auto backup enabled');
      
    } catch (e) {
      throw BackupException(
        'Failed to enable auto backup',
        code: 'AUTO_BACKUP_ENABLE_ERROR',
        originalError: e,
      );
    }
  }
  
  /// Disable automatic daily backup
  Future<void> disableAutoBackup() async {
    try {
      final settings = await getBackupSettings();
      final updatedSettings = settings.copyWith(autoBackupEnabled: false);
      await saveBackupSettings(updatedSettings);
      
      _progressController.add('Auto backup disabled');
      
    } catch (e) {
      throw BackupException(
        'Failed to disable auto backup',
        code: 'AUTO_BACKUP_DISABLE_ERROR',
        originalError: e,
      );
    }
  }
  
  /// Perform daily backup if needed
  Future<void> performDailyBackup() async {
    try {
      _progressController.add('Checking daily backup...');
      
      // TODO: Implement daily backup logic in task 5
      throw UnimplementedError('Daily backup will be implemented in task 5');
      
    } on BackupException {
      rethrow;
    } catch (e) {
      throw BackupException(
        'Failed to perform daily backup',
        code: 'DAILY_BACKUP_ERROR',
        originalError: e,
      );
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
      _progressController.add('Starting restore from file...');
      _progressController.add('Validating backup file...');
      
      await _restoreService.restoreFromSqlFile(filePath);
      
      _progressController.add('Restore completed successfully');
      
    } on BackupException {
      rethrow;
    } catch (e) {
      throw RestoreException(
        'Failed to restore from file: $filePath',
        code: 'RESTORE_ERROR',
        originalError: e,
      );
    }
  }
  
  // File Management Methods
  
  /// Clean old backup files (older than maxBackupDays)
  Future<void> cleanOldBackups() async {
    try {
      _progressController.add('Cleaning old backup files...');
      
      // TODO: Implement file cleanup in task 2
      throw UnimplementedError('File cleanup will be implemented in task 2');
      
    } on BackupException {
      rethrow;
    } catch (e) {
      throw BackupException(
        'Failed to clean old backups',
        code: 'CLEANUP_ERROR',
        originalError: e,
      );
    }
  }
  
  /// Get list of available backup files
  Future<List<BackupInfo>> getBackupFiles() async {
    try {
      // TODO: Implement file listing in task 2
      throw UnimplementedError('File listing will be implemented in task 2');
      
    } catch (e) {
      throw BackupException(
        'Failed to get backup files',
        code: 'FILE_LIST_ERROR',
        originalError: e,
      );
    }
  }
  
  // Settings Methods
  
  /// Save backup settings to persistent storage
  Future<void> saveBackupSettings(BackupSettings settings) async {
    try {
      // TODO: Implement settings persistence
      // For now, just store in memory
      _currentSettings = settings;
      
      _progressController.add('Backup settings saved');
      
    } catch (e) {
      throw BackupException(
        'Failed to save backup settings',
        code: 'SETTINGS_SAVE_ERROR',
        originalError: e,
      );
    }
  }
  
  /// Get backup settings from persistent storage
  Future<BackupSettings> getBackupSettings() async {
    try {
      // TODO: Implement settings loading from persistent storage
      // For now, return default settings if none exist
      if (_currentSettings == null) {
        _currentSettings = BackupSettings(
          autoBackupEnabled: false,
          backupDirectory: '/default/backup/path', // Will be updated in task 2
        );
      }
      
      return _currentSettings!;
      
    } catch (e) {
      throw BackupException(
        'Failed to get backup settings',
        code: 'SETTINGS_LOAD_ERROR',
        originalError: e,
      );
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
      final settings = await getBackupSettings();
      return settings.backupDirectory;
      
    } catch (e) {
      throw BackupException(
        'Failed to get backup directory',
        code: 'DIRECTORY_ERROR',
        originalError: e,
      );
    }
  }
  
  /// Dispose resources
  void dispose() {
    _progressController.close();
  }
}
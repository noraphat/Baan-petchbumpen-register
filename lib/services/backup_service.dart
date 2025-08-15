import 'dart:async';
import '../models/backup_settings.dart';
import '../models/backup_info.dart';
import 'backup_exceptions.dart';
import 'backup_logger.dart';
import 'backup_notification_service.dart';
import 'backup_security_service.dart';
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
    _securityService = BackupSecurityService();
    _restoreService = RestoreService(securityService: _securityService);
    _jsonExportService = JsonExportService();
    _autoBackupService = AutoBackupService();
    _sqlExportService = SqlExportService();
    _fileManagementService = FileManagementService();
    _logger = BackupLogger.instance;
    _notificationService = BackupNotificationService.instance;
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
  late final BackupSecurityService _securityService;
  late final BackupLogger _logger;
  late final BackupNotificationService _notificationService;

  /// Stream for progress updates during backup operations
  Stream<String> get progressStream => _progressController.stream;
  
  /// Stream for progress percentage updates (0.0 to 1.0)
  Stream<double> get progressPercentStream => _progressPercentController.stream;

  // JSON Export Methods

  /// Export all database data to JSON format
  /// Returns the file path of the created JSON backup
  Future<String> exportToJson() async {
    return await _logger.measureOperation('JSON Export', () async {
      try {
        _logger.startOperation('JSON Export');
        _notificationService.showProgress(
          operation: 'JSON Export',
          message: 'เริ่มต้นการส่งออกข้อมูล JSON...',
          progress: 0.0,
        );
        _progressController.add('Starting JSON export...');
        _progressPercentController.add(0.0);

        // Check permissions first
        _notificationService.showProgress(
          operation: 'JSON Export',
          message: 'ตรวจสอบสิทธิ์การเข้าถึงไฟล์...',
          progress: 0.1,
        );
        _progressController.add('Checking file permissions...');
        _progressPercentController.add(0.1);
        
        if (!await _fileManagementService.hasWritePermission()) {
          _logger.warning('Write permission not granted, requesting permission');
          await _fileManagementService.requestWritePermission();
        }

        _notificationService.showProgress(
          operation: 'JSON Export',
          message: 'รวบรวมข้อมูลจากทุกตาราง...',
          progress: 0.3,
        );
        _progressController.add('Collecting data from all tables...');
        _progressPercentController.add(0.3);

        final filePath = await _jsonExportService.exportAllTablesToJson();

        _notificationService.showSuccess(
          operation: 'JSON Export',
          message: 'ส่งออกข้อมูล JSON เรียบร้อยแล้ว',
          details: 'บันทึกที่: $filePath',
        );
        _progressController.add('JSON export completed successfully');
        _progressController.add('File saved to: $filePath');
        _progressPercentController.add(1.0);

        _logger.completeOperation('JSON Export', data: {'filePath': filePath});
        return filePath;
      } on BackupException catch (e) {
        _logger.error('JSON export failed', operation: 'JSON Export', error: e);
        _notificationService.showError(
          operation: 'JSON Export',
          message: 'การส่งออกข้อมูล JSON ล้มเหลว',
          details: e.message,
          error: e,
        );
        _progressController.add('JSON export failed: ${e.message}');
        _progressPercentController.add(0.0);
        rethrow;
      } catch (e, stackTrace) {
        final backupException = BackupException(
          'Failed to export data to JSON',
          code: 'JSON_EXPORT_ERROR',
          originalError: e,
        );
        _logger.error(
          'JSON export failed with unexpected error',
          operation: 'JSON Export',
          error: backupException,
          stackTrace: stackTrace,
        );
        _notificationService.showError(
          operation: 'JSON Export',
          message: 'เกิดข้อผิดพลาดที่ไม่คาดคิดในการส่งออกข้อมูล',
          details: e.toString(),
          error: backupException,
        );
        _progressController.add('JSON export failed: ${e.toString()}');
        _progressPercentController.add(0.0);
        throw backupException;
      }
    });
  }

  /// Export all database data to SQL format
  /// Returns the file path of the created SQL backup
  Future<String> exportToSql() async {
    return await _logger.measureOperation('SQL Export', () async {
      try {
        _logger.startOperation('SQL Export');
        _notificationService.showProgress(
          operation: 'SQL Export',
          message: 'เริ่มต้นการส่งออกข้อมูล SQL...',
          progress: 0.0,
        );
        _progressController.add('Starting SQL export...');
        _progressPercentController.add(0.0);

        // Check permissions first
        _notificationService.showProgress(
          operation: 'SQL Export',
          message: 'ตรวจสอบสิทธิ์การเข้าถึงไฟล์...',
          progress: 0.1,
        );
        _progressController.add('Checking file permissions...');
        _progressPercentController.add(0.1);
        
        if (!await _fileManagementService.hasWritePermission()) {
          _logger.warning('Write permission not granted, requesting permission');
          await _fileManagementService.requestWritePermission();
        }

        _notificationService.showProgress(
          operation: 'SQL Export',
          message: 'สร้างคำสั่ง SQL...',
          progress: 0.3,
        );
        _progressController.add('Generating SQL statements...');
        _progressPercentController.add(0.3);

        final filePath = await _sqlExportService.exportTimestampedBackup();

        _notificationService.showSuccess(
          operation: 'SQL Export',
          message: 'ส่งออกข้อมูล SQL เรียบร้อยแล้ว',
          details: 'บันทึกที่: $filePath',
        );
        _progressController.add('SQL export completed successfully');
        _progressController.add('File saved to: $filePath');
        _progressPercentController.add(1.0);

        _logger.completeOperation('SQL Export', data: {'filePath': filePath});
        return filePath;
      } on BackupException catch (e) {
        _logger.error('SQL export failed', operation: 'SQL Export', error: e);
        _notificationService.showError(
          operation: 'SQL Export',
          message: 'การส่งออกข้อมูล SQL ล้มเหลว',
          details: e.message,
          error: e,
        );
        _progressController.add('SQL export failed: ${e.message}');
        _progressPercentController.add(0.0);
        rethrow;
      } catch (e, stackTrace) {
        final backupException = BackupException(
          'Failed to export data to SQL',
          code: 'SQL_EXPORT_ERROR',
          originalError: e,
        );
        _logger.error(
          'SQL export failed with unexpected error',
          operation: 'SQL Export',
          error: backupException,
          stackTrace: stackTrace,
        );
        _notificationService.showError(
          operation: 'SQL Export',
          message: 'เกิดข้อผิดพลาดที่ไม่คาดคิดในการส่งออกข้อมูล',
          details: e.toString(),
          error: backupException,
        );
        _progressController.add('SQL export failed: ${e.toString()}');
        _progressPercentController.add(0.0);
        throw backupException;
      }
    });
  }

  // Auto Backup Methods

  /// Enable automatic daily backup
  Future<void> enableAutoBackup() async {
    try {
      _logger.startOperation('Enable Auto Backup');
      _progressController.add('Enabling auto backup...');
      
      final settings = await getBackupSettings();
      final updatedSettings = settings.copyWith(autoBackupEnabled: true);
      await saveBackupSettings(updatedSettings);

      _progressController.add('Auto backup enabled');
      _logger.completeOperation('Enable Auto Backup');
    } on BackupException catch (e) {
      _logger.error('Failed to enable auto backup', operation: 'Enable Auto Backup', error: e);
      rethrow;
    } catch (e, stackTrace) {
      final backupException = BackupException(
        'Failed to enable auto backup',
        code: 'AUTO_BACKUP_ENABLE_ERROR',
        originalError: e,
      );
      _logger.error('Failed to enable auto backup', operation: 'Enable Auto Backup', error: backupException, stackTrace: stackTrace);
      throw backupException;
    }
  }

  /// Disable automatic daily backup
  Future<void> disableAutoBackup() async {
    try {
      _logger.startOperation('Disable Auto Backup');
      _progressController.add('Disabling auto backup...');
      
      final settings = await getBackupSettings();
      final updatedSettings = settings.copyWith(autoBackupEnabled: false);
      await saveBackupSettings(updatedSettings);

      _progressController.add('Auto backup disabled');
      _logger.completeOperation('Disable Auto Backup');
    } on BackupException catch (e) {
      _logger.error('Failed to disable auto backup', operation: 'Disable Auto Backup', error: e);
      rethrow;
    } catch (e, stackTrace) {
      final backupException = BackupException(
        'Failed to disable auto backup',
        code: 'AUTO_BACKUP_DISABLE_ERROR',
        originalError: e,
      );
      _logger.error('Failed to disable auto backup', operation: 'Disable Auto Backup', error: backupException, stackTrace: stackTrace);
      throw backupException;
    }
  }

  /// Perform daily backup if needed
  Future<void> performDailyBackup() async {
    return await _logger.measureOperation('Daily Backup', () async {
      try {
        _logger.startOperation('Daily Backup');
        _notificationService.showProgress(
          operation: 'Daily Backup',
          message: 'ตรวจสอบการสำรองข้อมูลรายวัน...',
          progress: 0.0,
        );
        _progressController.add('Checking daily backup...');
        _progressPercentController.add(0.0);

        final settings = await getBackupSettings();
        if (!settings.autoBackupEnabled) {
          _logger.info('Daily backup skipped - auto backup disabled');
          _notificationService.showInfo(
            operation: 'Daily Backup',
            message: 'การสำรองข้อมูลอัตโนมัติถูกปิดใช้งาน',
          );
          _progressController.add('Auto backup is disabled');
          return;
        }

        _notificationService.showProgress(
          operation: 'Daily Backup',
          message: 'ตรวจสอบว่าต้องสำรองข้อมูลหรือไม่...',
          progress: 0.2,
        );
        _progressController.add('Checking if backup needed...');
        _progressPercentController.add(0.2);

        // Check if backup already exists for today
        final fileName = _sqlExportService.generateDailyBackupFileName();
        final backupExists = await _fileManagementService.backupFileExists(fileName);
        
        if (backupExists) {
          _logger.info('Daily backup skipped - file already exists: $fileName');
          _notificationService.showInfo(
            operation: 'Daily Backup',
            message: 'ข้ามการสำรองข้อมูล - มีไฟล์สำรองวันนี้แล้ว',
            details: fileName,
          );
          _progressController.add('Daily backup skipped - already exists for today');
          return;
        }

        _notificationService.showProgress(
          operation: 'Daily Backup',
          message: 'กำลังสำรองข้อมูลรายวัน...',
          progress: 0.4,
        );
        _progressController.add('Performing daily backup...');
        _progressPercentController.add(0.4);

        final filePath = await _autoBackupService.performAutoBackup(settings);

        if (filePath != null) {
          _notificationService.showProgress(
            operation: 'Daily Backup',
            message: 'อัปเดตการตั้งค่าการสำรองข้อมูล...',
            progress: 0.8,
          );
          _progressController.add('Updating backup settings...');
          _progressPercentController.add(0.8);

          // Update last backup time
          final updatedSettings = settings.copyWith(
            lastBackupTime: DateTime.now(),
          );
          await saveBackupSettings(updatedSettings);

          _notificationService.showSuccess(
            operation: 'Daily Backup',
            message: 'สำรองข้อมูลรายวันเรียบร้อยแล้ว',
            details: 'บันทึกที่: $filePath',
          );
          _progressController.add('Daily backup completed: $filePath');
          _progressPercentController.add(1.0);
          _logger.completeOperation('Daily Backup', data: {'filePath': filePath});

          // Clean old backups
          try {
            await _cleanOldBackupsInternal();
            _logger.info('Old backup cleanup completed');
          } catch (cleanupError) {
            _logger.warning('Old backup cleanup failed', 
                          operation: 'Daily Backup', 
                          data: {'error': cleanupError.toString()});
          }
        } else {
          final errorMsg = 'Daily backup failed - no file created';
          _logger.error(errorMsg, operation: 'Daily Backup');
          _notificationService.showError(
            operation: 'Daily Backup',
            message: 'การสำรองข้อมูลรายวันล้มเหลว',
            details: 'ไม่สามารถสร้างไฟล์สำรองข้อมูลได้',
          );
          _progressController.add('Daily backup failed - no file created');
          throw BackupException(errorMsg, code: 'NO_FILE_CREATED');
        }
      } on BackupException catch (e) {
        _logger.error('Daily backup failed', operation: 'Daily Backup', error: e);
        _notificationService.showError(
          operation: 'Daily Backup',
          message: 'การสำรองข้อมูลรายวันล้มเหลว',
          details: e.message,
          error: e,
        );
        _progressController.add('Daily backup failed: ${e.message}');
        _progressPercentController.add(0.0);
        rethrow;
      } catch (e, stackTrace) {
        final backupException = BackupException(
          'Failed to perform daily backup',
          code: 'DAILY_BACKUP_ERROR',
          originalError: e,
        );
        _logger.error(
          'Daily backup failed with unexpected error',
          operation: 'Daily Backup',
          error: backupException,
          stackTrace: stackTrace,
        );
        _notificationService.showError(
          operation: 'Daily Backup',
          message: 'เกิดข้อผิดพลาดที่ไม่คาดคิดในการสำรองข้อมูล',
          details: e.toString(),
          error: backupException,
        );
        _progressController.add('Daily backup failed: ${e.toString()}');
        _progressPercentController.add(0.0);
        throw backupException;
      }
    });
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
    return await _logger.measureOperation('Restore', () async {
      try {
        _logger.startOperation('Restore', data: {'filePath': filePath});
        _notificationService.showProgress(
          operation: 'Restore',
          message: 'เริ่มต้นการกู้คืนข้อมูลจากไฟล์...',
          progress: 0.0,
        );
        _progressController.add('Starting restore from file...');
        _progressPercentController.add(0.0);

        _notificationService.showProgress(
          operation: 'Restore',
          message: 'ตรวจสอบไฟล์สำรองข้อมูล...',
          progress: 0.1,
        );
        _progressController.add('Validating backup file...');
        _progressPercentController.add(0.1);

        // Validate file path for security
        try {
          await _securityService.validateFilePath(filePath);
        } on SecurityException catch (e) {
          _logger.error('File path security validation failed', operation: 'Restore', error: e);
          throw e;
        }

        // Validate file exists and is readable
        final fileName = filePath.split('/').last;
        if (!await _fileManagementService.backupFileExists(fileName)) {
          final error = RestoreException(
            'Backup file not found: $filePath',
            code: 'FILE_NOT_FOUND',
          );
          _logger.error('Backup file not found', operation: 'Restore', error: error);
          throw error;
        }

        // Comprehensive backup file validation including security checks
        try {
          final isValid = await _securityService.validateBackupFile(filePath);
          if (!isValid) {
            final error = InvalidBackupFileException(
              'Backup file failed security validation: $filePath'
            );
            _logger.error('Backup file security validation failed', operation: 'Restore', error: error);
            throw error;
          }
        } on SecurityException catch (e) {
          _logger.error('Backup file contains security violations', operation: 'Restore', error: e);
          throw e;
        }

        _notificationService.showProgress(
          operation: 'Restore',
          message: 'สร้างไฟล์สำรองข้อมูลฉุกเฉิน...',
          progress: 0.2,
        );
        _progressController.add('Creating emergency backup...');
        _progressPercentController.add(0.2);

        // Create emergency backup before restore
        await _createEmergencyBackup();

        _notificationService.showProgress(
          operation: 'Restore',
          message: 'กำลังกู้คืนข้อมูลจากไฟล์สำรอง...',
          progress: 0.4,
        );
        _progressController.add('Restoring data from backup...');
        _progressPercentController.add(0.4);

        await _restoreService.restoreFromSqlFile(filePath);

        _notificationService.showProgress(
          operation: 'Restore',
          message: 'ตรวจสอบความถูกต้องของข้อมูลที่กู้คืน...',
          progress: 0.8,
        );
        _progressController.add('Verifying restored data...');
        _progressPercentController.add(0.8);

        // Verify restore integrity
        final isIntegrityValid = await _restoreService.verifyRestoreIntegrity();
        if (!isIntegrityValid) {
          final error = RestoreException(
            'Restore verification failed - data integrity check failed',
            code: 'VERIFICATION_FAILED',
          );
          _logger.error('Restore verification failed', operation: 'Restore', error: error);
          throw error;
        }

        _notificationService.showSuccess(
          operation: 'Restore',
          message: 'กู้คืนข้อมูลเรียบร้อยแล้ว',
          details: 'ข้อมูลถูกกู้คืนจาก: $fileName',
        );
        _progressController.add('Restore completed successfully');
        _progressPercentController.add(1.0);
        _logger.completeOperation('Restore', data: {'filePath': filePath});
      } on BackupException catch (e) {
        _logger.error('Restore failed', operation: 'Restore', error: e);
        _notificationService.showError(
          operation: 'Restore',
          message: 'การกู้คืนข้อมูลล้มเหลว',
          details: e.message,
          error: e,
        );
        _progressController.add('Restore failed: ${e.message}');
        _progressPercentController.add(0.0);
        rethrow;
      } catch (e, stackTrace) {
        final restoreException = RestoreException(
          'Failed to restore from file: $filePath',
          code: 'RESTORE_ERROR',
          originalError: e,
        );
        _logger.error(
          'Restore failed with unexpected error',
          operation: 'Restore',
          error: restoreException,
          stackTrace: stackTrace,
        );
        _notificationService.showError(
          operation: 'Restore',
          message: 'เกิดข้อผิดพลาดที่ไม่คาดคิดในการกู้คืนข้อมูล',
          details: e.toString(),
          error: restoreException,
        );
        _progressController.add('Restore failed: ${e.toString()}');
        _progressPercentController.add(0.0);
        throw restoreException;
      }
    });
  }

  // File Management Methods

  /// Clean old backup files (older than maxBackupDays)
  Future<void> cleanOldBackups() async {
    return await _logger.measureOperation('Clean Old Backups', () async {
      try {
        _logger.startOperation('Clean Old Backups');
        _progressController.add('Cleaning old backup files...');
        _progressPercentController.add(0.0);

        await _cleanOldBackupsInternal();

        _progressController.add('Old backup files cleaned successfully');
        _progressPercentController.add(1.0);
        _logger.completeOperation('Clean Old Backups');
      } on BackupException catch (e) {
        _logger.error('Failed to clean old backups', operation: 'Clean Old Backups', error: e);
        _progressController.add('Failed to clean old backups: ${e.message}');
        _progressPercentController.add(0.0);
        rethrow;
      } catch (e, stackTrace) {
        final backupException = BackupException(
          'Failed to clean old backups',
          code: 'CLEANUP_ERROR',
          originalError: e,
        );
        _logger.error('Failed to clean old backups', operation: 'Clean Old Backups', error: backupException, stackTrace: stackTrace);
        _progressController.add('Failed to clean old backups: ${e.toString()}');
        _progressPercentController.add(0.0);
        throw backupException;
      }
    });
  }

  /// Get list of available backup files
  Future<List<BackupInfo>> getBackupFiles() async {
    return await _logger.measureOperation('Get Backup Files', () async {
      try {
        _logger.startOperation('Get Backup Files');
        
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

        _logger.completeOperation('Get Backup Files', data: {'fileCount': backupInfoList.length});
        return backupInfoList;
      } on BackupException catch (e) {
        _logger.error('Failed to get backup files', operation: 'Get Backup Files', error: e);
        rethrow;
      } catch (e, stackTrace) {
        final backupException = BackupException(
          'Failed to get backup files',
          code: 'FILE_LIST_ERROR',
          originalError: e,
        );
        _logger.error('Failed to get backup files', operation: 'Get Backup Files', error: backupException, stackTrace: stackTrace);
        throw backupException;
      }
    });
  }

  // Settings Methods

  /// Save backup settings to persistent storage
  Future<void> saveBackupSettings(BackupSettings settings) async {
    try {
      _logger.startOperation('Save Backup Settings');
      
      // Get the actual backup directory from file management service
      final backupDir = await _fileManagementService.getBackupDirectory();
      final updatedSettings = settings.copyWith(backupDirectory: backupDir);
      
      // Store in memory (in a real app, this would be persisted to SharedPreferences or database)
      _currentSettings = updatedSettings;

      _progressController.add('Backup settings saved');
      _logger.completeOperation('Save Backup Settings');
    } on BackupException catch (e) {
      _logger.error('Failed to save backup settings', operation: 'Save Backup Settings', error: e);
      rethrow;
    } catch (e, stackTrace) {
      final backupException = BackupException(
        'Failed to save backup settings',
        code: 'SETTINGS_SAVE_ERROR',
        originalError: e,
      );
      _logger.error('Failed to save backup settings', operation: 'Save Backup Settings', error: backupException, stackTrace: stackTrace);
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

      _logger.info('Loaded default backup settings');
      return _currentSettings!;
    } on BackupException catch (e) {
      _logger.error('Failed to get backup settings', operation: 'Get Backup Settings', error: e);
      rethrow;
    } catch (e, stackTrace) {
      final backupException = BackupException(
        'Failed to get backup settings',
        code: 'SETTINGS_LOAD_ERROR',
        originalError: e,
      );
      _logger.error('Failed to get backup settings', operation: 'Get Backup Settings', error: backupException, stackTrace: stackTrace);
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
      _logger.error('Failed to get backup directory', operation: 'Get Backup Directory', error: e);
      rethrow;
    } catch (e, stackTrace) {
      final backupException = BackupException(
        'Failed to get backup directory',
        code: 'DIRECTORY_ERROR',
        originalError: e,
      );
      _logger.error('Failed to get backup directory', operation: 'Get Backup Directory', error: backupException, stackTrace: stackTrace);
      throw backupException;
    }
  }

  /// Get storage information
  Future<int> getAvailableStorageSpace() async {
    try {
      return await _fileManagementService.getAvailableStorageSpace();
    } on BackupException catch (e) {
      _logger.error('Failed to get storage space', operation: 'Get Storage Space', error: e);
      rethrow;
    } catch (e, stackTrace) {
      final backupException = BackupException(
        'Failed to get storage space',
        code: 'STORAGE_ERROR',
        originalError: e,
      );
      _logger.error('Failed to get storage space', operation: 'Get Storage Space', error: backupException, stackTrace: stackTrace);
      throw backupException;
    }
  }

  /// Delete a specific backup file
  Future<void> deleteBackupFile(String fileName) async {
    return await _logger.measureOperation('Delete Backup File', () async {
      try {
        _logger.startOperation('Delete Backup File', data: {'fileName': fileName});
        _progressController.add('Deleting backup file: $fileName');
        
        await _fileManagementService.deleteBackupFile(fileName);
        
        _progressController.add('Backup file deleted successfully');
        _logger.completeOperation('Delete Backup File', data: {'fileName': fileName});
      } on BackupException catch (e) {
        _logger.error('Failed to delete backup file', operation: 'Delete Backup File', error: e);
        _progressController.add('Failed to delete backup file: ${e.message}');
        rethrow;
      } catch (e, stackTrace) {
        final backupException = BackupException(
          'Failed to delete backup file: $fileName',
          code: 'FILE_DELETE_ERROR',
          originalError: e,
        );
        _logger.error('Failed to delete backup file', operation: 'Delete Backup File', error: backupException, stackTrace: stackTrace);
        _progressController.add('Failed to delete backup file: ${e.toString()}');
        throw backupException;
      }
    });
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
      _logger.startOperation('Create Emergency Backup');
      final emergencyFileName = 'emergency_backup_${DateTime.now().millisecondsSinceEpoch}.sql';
      final sqlContent = await _sqlExportService.exportToSql();
      await _fileManagementService.createBackupFile(emergencyFileName, sqlContent);
      _logger.completeOperation('Create Emergency Backup', data: {'fileName': emergencyFileName});
    } catch (e, stackTrace) {
      _logger.error('Failed to create emergency backup', operation: 'Create Emergency Backup', error: e, stackTrace: stackTrace);
      // Don't throw here - emergency backup failure shouldn't stop the main operation
    }
  }

  /// Get logger instance for external access
  BackupLogger get logger => _logger;

  /// Get notification service instance for external access
  BackupNotificationService get notificationService => _notificationService;

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

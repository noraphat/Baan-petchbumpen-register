import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'backup_exceptions.dart';
import 'platform_file_service.dart';

/// Service for managing backup files and storage operations
class FileManagementService {
  static const String _backupDirectoryName = 'backups';
  static const int _defaultMaxBackupDays = 31;
  
  final PlatformFileService _platformService = PlatformFileService();

  /// Get the backup directory path using platform-specific logic
  Future<String> getBackupDirectory() async {
    return await _platformService.getBackupDirectory();
  }

  /// Ensure backup directory exists, create if it doesn't
  Future<void> ensureBackupDirectoryExists() async {
    try {
      final backupDir = await getBackupDirectory();
      final directory = Directory(backupDir);
      
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    } catch (e) {
      throw BackupException(
        'Failed to create backup directory: ${e.toString()}',
        code: 'DIRECTORY_CREATION_FAILED',
        originalError: e,
      );
    }
  }

  /// Get list of all backup files in the backup directory
  Future<List<String>> getBackupFiles() async {
    try {
      await ensureBackupDirectoryExists();
      final backupDir = await getBackupDirectory();
      final directory = Directory(backupDir);
      
      final files = await directory
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .where((file) => 
              file.path.endsWith('.json') || 
              file.path.endsWith('.sql'))
          .map((file) => file.path)
          .toList();
      
      return files;
    } catch (e) {
      throw BackupException(
        'Failed to get backup files: ${e.toString()}',
        code: 'FILE_LIST_FAILED',
        originalError: e,
      );
    }
  }

  /// Delete backup files older than specified number of days
  Future<void> deleteOldBackups({int maxDays = _defaultMaxBackupDays}) async {
    try {
      final backupFiles = await getBackupFiles();
      final cutoffDate = DateTime.now().subtract(Duration(days: maxDays));
      
      for (final filePath in backupFiles) {
        final file = File(filePath);
        if (await file.exists()) {
          final lastModified = await file.lastModified();
          if (lastModified.isBefore(cutoffDate)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      throw BackupException(
        'Failed to delete old backups: ${e.toString()}',
        code: 'OLD_BACKUP_DELETION_FAILED',
        originalError: e,
      );
    }
  }

  /// Check if the app has write permission for storage
  Future<bool> hasWritePermission() async {
    try {
      // Use platform-specific permission checking
      final hasPermission = await _platformService.hasStoragePermission();
      if (!hasPermission) {
        return false;
      }
      
      // Also test actual write capability
      return await _platformService.canWriteToBackupDirectory();
    } catch (e) {
      return false;
    }
  }

  /// Request write permission from user
  Future<void> requestWritePermission() async {
    try {
      // Request platform-specific permissions
      final granted = await _platformService.requestStoragePermission();
      if (!granted) {
        throw FilePermissionException(
          'Storage permission denied by user'
        );
      }
      
      // Verify we can actually write to the backup directory
      if (!await _platformService.canWriteToBackupDirectory()) {
        throw FilePermissionException(
          'Cannot write to backup directory even with permission'
        );
      }
    } catch (e) {
      if (e is FilePermissionException) {
        rethrow;
      }
      throw FilePermissionException(
        'Failed to request write permission: ${e.toString()}'
      );
    }
  }

  /// Get available storage space in bytes
  Future<int> getAvailableStorageSpace() async {
    try {
      return await _platformService.getAvailableStorageSpace();
    } catch (e) {
      throw BackupException(
        'Failed to get storage space: ${e.toString()}',
        code: 'STORAGE_SPACE_CHECK_FAILED',
        originalError: e,
      );
    }
  }

  /// Create a backup file with the given content
  Future<String> createBackupFile(String fileName, String content) async {
    try {
      await ensureBackupDirectoryExists();
      
      if (!await hasWritePermission()) {
        await requestWritePermission();
      }
      
      final backupDir = await getBackupDirectory();
      final filePath = '$backupDir/$fileName';
      final file = File(filePath);
      
      await file.writeAsString(content);
      return filePath;
    } catch (e) {
      if (e is BackupException || e is FilePermissionException) {
        rethrow;
      }
      throw BackupException(
        'Failed to create backup file: ${e.toString()}',
        code: 'FILE_CREATION_FAILED',
        originalError: e,
      );
    }
  }

  /// Check if a backup file exists for the given filename
  Future<bool> backupFileExists(String fileName) async {
    try {
      final backupDir = await getBackupDirectory();
      final filePath = '$backupDir/$fileName';
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get the size of a backup file in bytes
  Future<int> getBackupFileSize(String fileName) async {
    try {
      final backupDir = await getBackupDirectory();
      final filePath = '$backupDir/$fileName';
      final file = File(filePath);
      
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Delete a specific backup file
  Future<void> deleteBackupFile(String fileName) async {
    try {
      final backupDir = await getBackupDirectory();
      final filePath = '$backupDir/$fileName';
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw BackupException(
        'Failed to delete backup file: ${e.toString()}',
        code: 'FILE_DELETION_FAILED',
        originalError: e,
      );
    }
  }

  /// Check if external storage is available (Android only)
  Future<bool> isExternalStorageAvailable() async {
    return await _platformService.isExternalStorageAvailable();
  }

  /// Get platform-specific shareable directory for backup files
  Future<String?> getShareableDirectory() async {
    return await _platformService.getShareableDirectory();
  }

  /// Get supported backup file extensions for current platform
  List<String> getSupportedBackupExtensions() {
    return _platformService.getSupportedBackupExtensions();
  }

  /// Get maximum recommended backup file size for current platform
  int getMaxBackupFileSize() {
    return _platformService.getMaxBackupFileSize();
  }

  /// Check if platform supports background backup operations
  bool supportsBackgroundBackup() {
    return _platformService.supportsBackgroundBackup();
  }

  /// Get recommended backup frequency for current platform
  Duration getRecommendedBackupFrequency() {
    return _platformService.getRecommendedBackupFrequency();
  }

  /// Copy backup file to shareable location (for sharing with other apps)
  Future<String?> copyBackupToShareableLocation(String fileName) async {
    try {
      final shareableDir = await getShareableDirectory();
      if (shareableDir == null) {
        return null;
      }

      final backupDir = await getBackupDirectory();
      final sourceFile = File('$backupDir/$fileName');
      
      if (!await sourceFile.exists()) {
        throw BackupException(
          'Source backup file not found: $fileName',
          code: 'SOURCE_FILE_NOT_FOUND',
        );
      }

      final targetPath = '$shareableDir/$fileName';
      final targetFile = await sourceFile.copy(targetPath);
      
      return targetFile.path;
    } catch (e) {
      throw BackupException(
        'Failed to copy backup to shareable location: ${e.toString()}',
        code: 'COPY_TO_SHAREABLE_FAILED',
        originalError: e,
      );
    }
  }

  /// Validate backup file size against platform limits
  Future<bool> isBackupFileSizeValid(String fileName) async {
    try {
      final fileSize = await getBackupFileSize(fileName);
      final maxSize = getMaxBackupFileSize();
      return fileSize <= maxSize;
    } catch (e) {
      return false;
    }
  }

  /// Private method to test if we can write to app directory
  Future<bool> _canWriteToAppDirectory() async {
    return await _platformService.canWriteToBackupDirectory();
  }
}
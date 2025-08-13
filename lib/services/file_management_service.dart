import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'backup_exceptions.dart';

/// Service for managing backup files and storage operations
class FileManagementService {
  static const String _backupDirectoryName = 'backups';
  static const int _defaultMaxBackupDays = 31;

  /// Get the backup directory path
  Future<String> getBackupDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return '${appDocDir.path}/$_backupDirectoryName';
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
      // For modern Android and iOS, apps can always write to their app-specific directories
      // We'll test this by attempting to write to the app directory
      return await _canWriteToAppDirectory();
    } catch (e) {
      return false;
    }
  }

  /// Request write permission from user
  Future<void> requestWritePermission() async {
    try {
      // For app-specific directories, no explicit permission is needed on modern platforms
      // We'll verify we can write to the app directory
      if (!await _canWriteToAppDirectory()) {
        throw FilePermissionException(
          'Cannot write to app documents directory'
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
      final backupDir = await getBackupDirectory();
      final directory = Directory(backupDir);
      
      // This is a simplified implementation
      // In a real app, you might want to use a plugin like device_info_plus
      // to get actual storage information
      final stat = await directory.stat();
      
      // Return a large number as placeholder since we can't easily get
      // actual available space without additional plugins
      return 1024 * 1024 * 1024; // 1GB placeholder
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

  /// Private method to test if we can write to app directory
  Future<bool> _canWriteToAppDirectory() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final testFile = File('${appDocDir.path}/test_write.tmp');
      
      await testFile.writeAsString('test');
      await testFile.delete();
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
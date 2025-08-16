import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'backup_exceptions.dart';

/// Platform-specific file management service for backup operations
class PlatformFileService {
  static const String _backupDirectoryName = 'backups';
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Get platform-appropriate backup directory
  Future<String> getBackupDirectory() async {
    if (Platform.isAndroid) {
      return await _getAndroidBackupDirectory();
    } else if (Platform.isIOS) {
      return await _getIOSBackupDirectory();
    } else {
      // Fallback for other platforms (desktop, web)
      final appDocDir = await getApplicationDocumentsDirectory();
      return '${appDocDir.path}/$_backupDirectoryName';
    }
  }

  /// Check if storage permission is required and granted
  Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      return await _hasAndroidStoragePermission();
    } else if (Platform.isIOS) {
      return await _hasIOSStoragePermission();
    }
    return true; // Other platforms don't need explicit permission
  }

  /// Request storage permission from user
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      return await _requestAndroidStoragePermission();
    } else if (Platform.isIOS) {
      return await _requestIOSStoragePermission();
    }
    return true; // Other platforms don't need explicit permission
  }

  /// Get available storage space in bytes
  Future<int> getAvailableStorageSpace() async {
    try {
      if (Platform.isAndroid) {
        return await _getAndroidStorageSpace();
      } else if (Platform.isIOS) {
        return await _getIOSStorageSpace();
      }
      
      // Fallback for other platforms
      return 1024 * 1024 * 1024; // 1GB placeholder
    } catch (e) {
      throw BackupException(
        'Failed to get storage space: ${e.toString()}',
        code: 'STORAGE_SPACE_CHECK_FAILED',
        originalError: e,
      );
    }
  }

  /// Check if external storage is available (Android only)
  Future<bool> isExternalStorageAvailable() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final externalDir = await getExternalStorageDirectory();
      return externalDir != null;
    } catch (e) {
      return false;
    }
  }

  /// Get platform-specific file sharing directory
  Future<String?> getShareableDirectory() async {
    if (Platform.isAndroid) {
      return await _getAndroidShareableDirectory();
    } else if (Platform.isIOS) {
      return await _getIOSShareableDirectory();
    }
    return null;
  }

  // Android-specific implementations
  Future<String> _getAndroidBackupDirectory() async {
    final androidInfo = await _deviceInfo.androidInfo;
    
    // For Android 10+ (API 29+), use scoped storage
    if (androidInfo.version.sdkInt >= 29) {
      // Use app-specific directory that doesn't require permissions
      final appDocDir = await getApplicationDocumentsDirectory();
      return '${appDocDir.path}/$_backupDirectoryName';
    } else {
      // For older Android versions, try external storage first
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          return '${externalDir.path}/$_backupDirectoryName';
        }
      } catch (e) {
        // Fall back to app documents directory
      }
      
      final appDocDir = await getApplicationDocumentsDirectory();
      return '${appDocDir.path}/$_backupDirectoryName';
    }
  }

  Future<bool> _hasAndroidStoragePermission() async {
    final androidInfo = await _deviceInfo.androidInfo;
    
    // Android 10+ (API 29+) with scoped storage doesn't need explicit permission
    // for app-specific directories
    if (androidInfo.version.sdkInt >= 29) {
      return true;
    }
    
    // For older versions, check WRITE_EXTERNAL_STORAGE permission
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  Future<bool> _requestAndroidStoragePermission() async {
    final androidInfo = await _deviceInfo.androidInfo;
    
    // Android 10+ with scoped storage
    if (androidInfo.version.sdkInt >= 29) {
      return true;
    }
    
    // For older versions, request WRITE_EXTERNAL_STORAGE
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<int> _getAndroidStorageSpace() async {
    try {
      final backupDir = await _getAndroidBackupDirectory();
      final directory = Directory(backupDir);
      
      // Create directory if it doesn't exist to test space
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Try to get actual storage info using StatFs (would need platform channel)
      // For now, return a reasonable estimate
      return 1024 * 1024 * 1024; // 1GB
    } catch (e) {
      return 512 * 1024 * 1024; // 512MB fallback
    }
  }

  Future<String?> _getAndroidShareableDirectory() async {
    try {
      // Try to get Downloads directory for sharing
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        // Navigate to Downloads folder
        final downloadsPath = externalDir.path.replaceAll('/Android/data/${await _getPackageName()}/files', '/Download');
        return downloadsPath;
      }
    } catch (e) {
      debugPrint('Failed to get Android shareable directory: $e');
    }
    return null;
  }

  // iOS-specific implementations
  Future<String> _getIOSBackupDirectory() async {
    // Use app documents directory for iOS
    final appDocDir = await getApplicationDocumentsDirectory();
    return '${appDocDir.path}/$_backupDirectoryName';
  }

  Future<bool> _hasIOSStoragePermission() async {
    // iOS apps can always write to their documents directory
    return true;
  }

  Future<bool> _requestIOSStoragePermission() async {
    // No explicit permission needed for iOS app documents directory
    return true;
  }

  Future<int> _getIOSStorageSpace() async {
    try {
      // iOS doesn't provide easy access to storage info
      // Return a reasonable estimate
      return 2 * 1024 * 1024 * 1024; // 2GB
    } catch (e) {
      return 1024 * 1024 * 1024; // 1GB fallback
    }
  }

  Future<String?> _getIOSShareableDirectory() async {
    try {
      // Use app documents directory for iOS sharing
      final appDocDir = await getApplicationDocumentsDirectory();
      return appDocDir.path;
    } catch (e) {
      debugPrint('Failed to get iOS shareable directory: $e');
      return null;
    }
  }

  // Helper methods
  Future<String> _getPackageName() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      // Use package name from build info or fallback
      return androidInfo.data['packageName'] as String? ?? 'com.example.app';
    }
    return 'com.example.app';
  }

  /// Test if we can write to the backup directory
  Future<bool> canWriteToBackupDirectory() async {
    try {
      final backupDir = await getBackupDirectory();
      final directory = Directory(backupDir);
      
      // Create directory if it doesn't exist
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Test write by creating a temporary file
      final testFile = File('$backupDir/test_write_${DateTime.now().millisecondsSinceEpoch}.tmp');
      await testFile.writeAsString('test');
      
      // Clean up test file
      if (await testFile.exists()) {
        await testFile.delete();
      }
      
      return true;
    } catch (e) {
      debugPrint('Cannot write to backup directory: $e');
      return false;
    }
  }

  /// Get platform-specific backup file extension recommendations
  List<String> getSupportedBackupExtensions() {
    if (Platform.isAndroid) {
      return ['.sql', '.json', '.db', '.backup'];
    } else if (Platform.isIOS) {
      return ['.sql', '.json', '.backup'];
    }
    return ['.sql', '.json'];
  }

  /// Get platform-specific maximum file size for backups
  int getMaxBackupFileSize() {
    if (Platform.isAndroid) {
      return 100 * 1024 * 1024; // 100MB for Android
    } else if (Platform.isIOS) {
      return 50 * 1024 * 1024; // 50MB for iOS
    }
    return 25 * 1024 * 1024; // 25MB for other platforms
  }

  /// Check if the platform supports background backup operations
  bool supportsBackgroundBackup() {
    // Both Android and iOS support background tasks with limitations
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Get platform-specific backup frequency recommendations
  Duration getRecommendedBackupFrequency() {
    if (Platform.isAndroid) {
      return const Duration(hours: 24); // Daily for Android
    } else if (Platform.isIOS) {
      return const Duration(hours: 12); // Twice daily for iOS (more restrictive background)
    }
    return const Duration(hours: 24); // Daily for other platforms
  }
}
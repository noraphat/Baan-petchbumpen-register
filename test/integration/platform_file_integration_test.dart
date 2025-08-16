import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/services.dart';
import '../../lib/services/platform_file_service.dart';
import '../../lib/services/file_management_service.dart';
import '../../lib/services/backup_exceptions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Platform File Integration Tests', () {
    late PlatformFileService platformService;
    late FileManagementService fileService;

    setUp(() {
      platformService = PlatformFileService();
      fileService = FileManagementService();
    });

    group('Directory Creation and Access', () {
      testWidgets('can create and access backup directory', (tester) async {
        final backupDir = await platformService.getBackupDirectory();
        expect(backupDir, isNotEmpty);

        final directory = Directory(backupDir);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        expect(await directory.exists(), isTrue);
      });

      testWidgets('can write to backup directory', (tester) async {
        final canWrite = await platformService.canWriteToBackupDirectory();
        expect(canWrite, isTrue);
      });

      testWidgets('backup directory is platform-appropriate', (tester) async {
        final backupDir = await platformService.getBackupDirectory();
        
        if (Platform.isAndroid) {
          // Should be in app-specific directory for Android
          expect(backupDir, anyOf(
            contains('/data/data/'),
            contains('/storage/emulated/0/Android/data/'),
          ));
        } else if (Platform.isIOS) {
          // Should be in app documents directory for iOS
          expect(backupDir, contains('/Documents/'));
        }
      });
    });

    group('Permission Handling', () {
      testWidgets('can check storage permissions', (tester) async {
        final hasPermission = await platformService.hasStoragePermission();
        expect(hasPermission, isA<bool>());
      });

      testWidgets('can request storage permissions', (tester) async {
        final granted = await platformService.requestStoragePermission();
        expect(granted, isA<bool>());
      });

      testWidgets('file management service uses platform permissions', (tester) async {
        final hasPermission = await fileService.hasWritePermission();
        expect(hasPermission, isA<bool>());

        if (!hasPermission) {
          try {
            await fileService.requestWritePermission();
          } catch (e) {
            expect(e, isA<FilePermissionException>());
          }
        }
      });
    });

    group('File Operations', () {
      testWidgets('can create backup files', (tester) async {
        await fileService.ensureBackupDirectoryExists();
        
        final testFileName = 'test_backup_${DateTime.now().millisecondsSinceEpoch}.json';
        final testContent = '{"test": "data"}';
        
        final filePath = await fileService.createBackupFile(testFileName, testContent);
        expect(filePath, isNotEmpty);
        
        final file = File(filePath);
        expect(await file.exists(), isTrue);
        
        final content = await file.readAsString();
        expect(content, equals(testContent));
        
        // Clean up
        await file.delete();
      });

      testWidgets('can list backup files', (tester) async {
        await fileService.ensureBackupDirectoryExists();
        
        // Create a test file
        final testFileName = 'test_list_${DateTime.now().millisecondsSinceEpoch}.sql';
        await fileService.createBackupFile(testFileName, 'SELECT 1;');
        
        final backupFiles = await fileService.getBackupFiles();
        expect(backupFiles, isNotEmpty);
        expect(backupFiles.any((path) => path.contains(testFileName)), isTrue);
        
        // Clean up
        await fileService.deleteBackupFile(testFileName);
      });

      testWidgets('can delete backup files', (tester) async {
        await fileService.ensureBackupDirectoryExists();
        
        final testFileName = 'test_delete_${DateTime.now().millisecondsSinceEpoch}.json';
        await fileService.createBackupFile(testFileName, '{}');
        
        expect(await fileService.backupFileExists(testFileName), isTrue);
        
        await fileService.deleteBackupFile(testFileName);
        expect(await fileService.backupFileExists(testFileName), isFalse);
      });
    });

    group('Storage Information', () {
      testWidgets('can get available storage space', (tester) async {
        final space = await platformService.getAvailableStorageSpace();
        expect(space, greaterThan(0));
      });

      testWidgets('can check file sizes', (tester) async {
        await fileService.ensureBackupDirectoryExists();
        
        final testFileName = 'test_size_${DateTime.now().millisecondsSinceEpoch}.json';
        final testContent = '{"test": "data with some content"}';
        
        await fileService.createBackupFile(testFileName, testContent);
        
        final fileSize = await fileService.getBackupFileSize(testFileName);
        expect(fileSize, greaterThan(0));
        expect(fileSize, equals(testContent.length));
        
        // Clean up
        await fileService.deleteBackupFile(testFileName);
      });
    });

    group('Platform-Specific Features', () {
      testWidgets('Android external storage check', (tester) async {
        if (Platform.isAndroid) {
          final hasExternal = await platformService.isExternalStorageAvailable();
          expect(hasExternal, isA<bool>());
        }
      });

      testWidgets('shareable directory access', (tester) async {
        final shareableDir = await platformService.getShareableDirectory();
        expect(shareableDir, anyOf(isNull, isA<String>()));
        
        if (shareableDir != null) {
          expect(shareableDir, isNotEmpty);
        }
      });

      testWidgets('copy to shareable location', (tester) async {
        await fileService.ensureBackupDirectoryExists();
        
        final testFileName = 'test_share_${DateTime.now().millisecondsSinceEpoch}.json';
        await fileService.createBackupFile(testFileName, '{"shareable": true}');
        
        try {
          final sharedPath = await fileService.copyBackupToShareableLocation(testFileName);
          if (sharedPath != null) {
            expect(sharedPath, isNotEmpty);
            final sharedFile = File(sharedPath);
            expect(await sharedFile.exists(), isTrue);
            
            // Clean up shared file
            await sharedFile.delete();
          }
        } catch (e) {
          // It's okay if sharing is not available on test environment
          expect(e, isA<BackupException>());
        }
        
        // Clean up original file
        await fileService.deleteBackupFile(testFileName);
      });
    });

    group('Platform Configuration', () {
      test('supported extensions are platform-appropriate', () {
        final extensions = platformService.getSupportedBackupExtensions();
        expect(extensions, contains('.sql'));
        expect(extensions, contains('.json'));
        
        if (Platform.isAndroid) {
          expect(extensions, contains('.db'));
        }
      });

      test('max file size is reasonable', () {
        final maxSize = platformService.getMaxBackupFileSize();
        expect(maxSize, greaterThan(10 * 1024 * 1024)); // At least 10MB
        expect(maxSize, lessThanOrEqualTo(100 * 1024 * 1024)); // At most 100MB
      });

      test('backup frequency is appropriate', () {
        final frequency = platformService.getRecommendedBackupFrequency();
        expect(frequency.inHours, greaterThanOrEqualTo(12));
        expect(frequency.inHours, lessThanOrEqualTo(24));
      });

      test('background backup support is correct', () {
        final supports = platformService.supportsBackgroundBackup();
        if (Platform.isAndroid || Platform.isIOS) {
          expect(supports, isTrue);
        } else {
          expect(supports, isA<bool>());
        }
      });
    });

    group('Error Handling', () {
      testWidgets('handles invalid file operations gracefully', (tester) async {
        // Try to delete non-existent file
        expect(() async => await fileService.deleteBackupFile('non_existent.json'), 
               returnsNormally);
        
        // Try to get size of non-existent file
        final size = await fileService.getBackupFileSize('non_existent.json');
        expect(size, equals(0));
        
        // Try to check existence of non-existent file
        final exists = await fileService.backupFileExists('non_existent.json');
        expect(exists, isFalse);
      });

      testWidgets('handles permission errors appropriately', (tester) async {
        // These tests depend on the actual device permissions
        // We mainly test that methods don't crash
        expect(() async => await platformService.hasStoragePermission(), 
               returnsNormally);
        expect(() async => await platformService.requestStoragePermission(), 
               returnsNormally);
      });
    });

    group('File Validation', () {
      testWidgets('validates backup file sizes', (tester) async {
        await fileService.ensureBackupDirectoryExists();
        
        final testFileName = 'test_validation_${DateTime.now().millisecondsSinceEpoch}.json';
        final smallContent = '{"small": "file"}';
        
        await fileService.createBackupFile(testFileName, smallContent);
        
        final isValid = await fileService.isBackupFileSizeValid(testFileName);
        expect(isValid, isTrue);
        
        // Clean up
        await fileService.deleteBackupFile(testFileName);
      });
    });

    group('Cleanup Operations', () {
      testWidgets('can clean old backup files', (tester) async {
        await fileService.ensureBackupDirectoryExists();
        
        // Create a test file
        final testFileName = 'test_cleanup_${DateTime.now().millisecondsSinceEpoch}.json';
        await fileService.createBackupFile(testFileName, '{"cleanup": "test"}');
        
        // Delete old backups (should not delete recent file)
        await fileService.deleteOldBackups(maxDays: 1);
        
        // File should still exist since it's recent
        expect(await fileService.backupFileExists(testFileName), isTrue);
        
        // Clean up
        await fileService.deleteBackupFile(testFileName);
      });
    });
  });
}
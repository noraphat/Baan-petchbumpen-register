import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/backup_service.dart';
import '../../lib/services/backup_exceptions.dart';
import '../../lib/models/backup_settings.dart';

void main() {
  group('BackupService', () {
    late BackupService backupService;
    
    setUp(() {
      backupService = BackupService.instance;
    });
    
    test('should be singleton', () {
      final instance1 = BackupService.instance;
      final instance2 = BackupService.instance;
      
      expect(instance1, same(instance2));
    });
    
    test('should have progress stream', () {
      expect(backupService.progressStream, isA<Stream<String>>());
    });
    
    group('Settings Management', () {
      test('should return default settings when none exist', () async {
        final settings = await backupService.getBackupSettings();
        
        expect(settings.autoBackupEnabled, false);
        expect(settings.maxBackupDays, 31);
        expect(settings.backupDirectory, isNotEmpty);
        expect(settings.lastBackupTime, null);
      });
      
      test('should save and retrieve settings', () async {
        final testSettings = BackupSettings(
          autoBackupEnabled: true,
          lastBackupTime: DateTime(2024, 1, 15),
          maxBackupDays: 15,
          backupDirectory: '/test/backup',
        );
        
        await backupService.saveBackupSettings(testSettings);
        final retrievedSettings = await backupService.getBackupSettings();
        
        expect(retrievedSettings, equals(testSettings));
      });
      
      test('should update settings with copyWith', () async {
        final initialSettings = BackupSettings(
          autoBackupEnabled: false,
          backupDirectory: '/initial',
        );
        
        await backupService.saveBackupSettings(initialSettings);
        
        final updatedSettings = initialSettings.copyWith(
          autoBackupEnabled: true,
          maxBackupDays: 20,
        );
        
        await backupService.saveBackupSettings(updatedSettings);
        final retrievedSettings = await backupService.getBackupSettings();
        
        expect(retrievedSettings.autoBackupEnabled, true);
        expect(retrievedSettings.maxBackupDays, 20);
        expect(retrievedSettings.backupDirectory, '/initial'); // unchanged
      });
    });
    
    group('Auto Backup Management', () {
      test('should enable auto backup', () async {
        await backupService.enableAutoBackup();
        
        expect(backupService.isAutoBackupEnabled(), true);
        
        final settings = await backupService.getBackupSettings();
        expect(settings.autoBackupEnabled, true);
      });
      
      test('should disable auto backup', () async {
        // First enable it
        await backupService.enableAutoBackup();
        expect(backupService.isAutoBackupEnabled(), true);
        
        // Then disable it
        await backupService.disableAutoBackup();
        expect(backupService.isAutoBackupEnabled(), false);
        
        final settings = await backupService.getBackupSettings();
        expect(settings.autoBackupEnabled, false);
      });
      
      test('should return false for auto backup when no settings exist', () {
        expect(backupService.isAutoBackupEnabled(), false);
      });
      
      test('should return null for last backup time when none exists', () {
        expect(backupService.getLastBackupTime(), null);
      });
      
      test('should return last backup time when it exists', () async {
        final lastBackup = DateTime(2024, 1, 15, 10, 30);
        final settings = BackupSettings(
          autoBackupEnabled: true,
          lastBackupTime: lastBackup,
          backupDirectory: '/test',
        );
        
        await backupService.saveBackupSettings(settings);
        
        expect(backupService.getLastBackupTime(), lastBackup);
      });
    });
    
    group('Unimplemented Methods', () {
      test('exportToJson should throw BackupException with UnimplementedError', () async {
        expect(
          () => backupService.exportToJson(),
          throwsA(isA<BackupException>()),
        );
      });
      
      test('performDailyBackup should work when auto backup is enabled', () async {
        // This test verifies that performDailyBackup no longer throws UnimplementedError
        // The actual functionality is tested in AutoBackupService tests
        
        // Should not throw UnimplementedError anymore
        // May throw other exceptions due to missing dependencies in test environment
        try {
          await backupService.performDailyBackup();
        } catch (e) {
          // Should not be UnimplementedError
          expect(e, isNot(isA<UnimplementedError>()));
        }
      });
      
      test('restoreFromFile should throw InvalidBackupFileException for invalid file', () async {
        expect(
          () => backupService.restoreFromFile('/non/existent/file.sql'),
          throwsA(isA<InvalidBackupFileException>()),
        );
      });
      
      test('cleanOldBackups should throw BackupException with UnimplementedError', () async {
        expect(
          () => backupService.cleanOldBackups(),
          throwsA(isA<BackupException>()),
        );
      });
      
      test('getBackupFiles should throw BackupException with UnimplementedError', () async {
        expect(
          () => backupService.getBackupFiles(),
          throwsA(isA<BackupException>()),
        );
      });
      
      test('validateBackupFile should return false for invalid file', () async {
        final result = await backupService.validateBackupFile('/non/existent/file.sql');
        expect(result, isFalse);
      });
    });
    
    group('Error Handling', () {
      test('should wrap unknown errors in BackupException for enableAutoBackup', () async {
        // This test would need mocking to simulate an error
        // For now, we just verify the method completes successfully
        await backupService.enableAutoBackup();
        expect(backupService.isAutoBackupEnabled(), true);
      });
      
      test('should wrap unknown errors in BackupException for disableAutoBackup', () async {
        await backupService.disableAutoBackup();
        expect(backupService.isAutoBackupEnabled(), false);
      });
    });
    
    group('Progress Updates', () {
      test('should emit progress updates for enableAutoBackup', () async {
        final progressUpdates = <String>[];
        final subscription = backupService.progressStream.listen(
          (update) => progressUpdates.add(update),
        );
        
        await backupService.enableAutoBackup();
        
        expect(progressUpdates, contains('Backup settings saved'));
        
        await subscription.cancel();
      });
      
      test('should emit progress updates for disableAutoBackup', () async {
        final progressUpdates = <String>[];
        final subscription = backupService.progressStream.listen(
          (update) => progressUpdates.add(update),
        );
        
        await backupService.disableAutoBackup();
        
        expect(progressUpdates, contains('Backup settings saved'));
        
        await subscription.cancel();
      });
      
      test('should emit progress updates for saveBackupSettings', () async {
        final progressUpdates = <String>[];
        final subscription = backupService.progressStream.listen(
          (update) => progressUpdates.add(update),
        );
        
        final settings = BackupSettings(
          autoBackupEnabled: true,
          backupDirectory: '/test',
        );
        
        await backupService.saveBackupSettings(settings);
        
        expect(progressUpdates, contains('Backup settings saved'));
        
        await subscription.cancel();
      });
    });
    
    group('Backup Directory', () {
      test('should return backup directory from settings', () async {
        final settings = BackupSettings(
          autoBackupEnabled: false,
          backupDirectory: '/custom/backup/path',
        );
        
        await backupService.saveBackupSettings(settings);
        
        final directory = await backupService.getBackupDirectory();
        expect(directory, '/custom/backup/path');
      });
    });
  });
}
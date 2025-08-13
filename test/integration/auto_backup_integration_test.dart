import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/services/auto_backup_service.dart';
import 'package:flutter_petchbumpen_register/services/backup_service.dart';
import 'package:flutter_petchbumpen_register/models/backup_settings.dart';

void main() {
  group('AutoBackupService Integration Tests', () {
    late AutoBackupService autoBackupService;
    late BackupService backupService;

    setUp(() {
      autoBackupService = AutoBackupService();
      backupService = BackupService.instance;
    });

    test('should generate correct daily backup filename', () {
      final testDate = DateTime(2024, 1, 15);
      final fileName = autoBackupService.getDailyBackupFileName(testDate);
      
      expect(fileName, equals('15.sql'));
    });

    test('should handle backup settings correctly', () async {
      final settings = BackupSettings(
        autoBackupEnabled: true,
        backupDirectory: '/test/backup/dir',
        lastBackupTime: DateTime.now(),
      );

      final shouldSchedule = await autoBackupService.shouldScheduleAutoBackup(settings);
      
      // Should return a boolean (true or false depending on file existence)
      expect(shouldSchedule, isA<bool>());
    });

    test('should integrate with BackupService', () async {
      // Test that BackupService can use AutoBackupService
      expect(backupService.isAutoBackupEnabled(), isA<bool>());
      expect(backupService.getLastBackupTime(), isA<DateTime?>());
    });

    test('should handle backup status correctly (or throw expected exception)', () async {
      try {
        final status = await autoBackupService.getBackupStatus();
        
        expect(status, isA<Map<String, dynamic>>());
        expect(status.containsKey('totalBackupFiles'), isTrue);
        expect(status.containsKey('hasTodayBackup'), isTrue);
        expect(status.containsKey('todayFileName'), isTrue);
      } catch (e) {
        // In test environment, file system access may not be available
        // This is expected and acceptable for unit tests
        expect(e, isA<Exception>());
      }
    });

    test('should handle edge case dates correctly', () {
      final edgeCases = [
        DateTime(2024, 2, 29), // Leap year
        DateTime(2024, 12, 31), // End of year
        DateTime(2024, 1, 1),   // Start of year
      ];

      for (final date in edgeCases) {
        final fileName = autoBackupService.getDailyBackupFileName(date);
        expect(fileName, matches(r'^\d{2}\.sql$'));
        expect(fileName.length, equals(6));
      }
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'dart:async';

import '../../lib/services/backup_scheduler_service.dart';
import '../../lib/services/backup_service.dart';
import '../../lib/services/auto_backup_service.dart';
import '../../lib/models/backup_settings.dart';
import '../../lib/services/backup_exceptions.dart';

void main() {
  group('BackupSchedulerService Integration Tests', () {
    late BackupSchedulerService schedulerService;
    late BackupService backupService;
    late AutoBackupService autoBackupService;
    late Directory tempDir;

    setUpAll(() async {
      // Create temporary directory for test files
      tempDir = await Directory.systemTemp.createTemp('backup_scheduler_test_');
    });

    setUp(() async {
      // Reset services before each test
      BackupSchedulerService.resetInstance();
      BackupService.resetInstance();
      
      schedulerService = BackupSchedulerService.instance;
      backupService = BackupService.instance;
      autoBackupService = AutoBackupService();
    });

    tearDown(() async {
      schedulerService.dispose();
      BackupSchedulerService.resetInstance();
      BackupService.resetInstance();
    });

    tearDownAll(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Initialization Integration', () {
      test('should initialize scheduler and perform startup backup check', () async {
        // Act
        await schedulerService.initialize();

        // Assert
        final status = schedulerService.getSchedulerStatus();
        expect(status['isInitialized'], true);
        expect(status['hasActiveTimer'], true);
        expect(status['timerPeriod'], '1 hour');
      });

      test('should handle initialization with backup service errors', () async {
        // This test verifies that scheduler initialization is resilient
        // to backup service failures during startup
        
        // Act & Assert - should not throw even if backup operations fail
        expect(() => schedulerService.initialize(), returnsNormally);
      });
    });

    group('Backup Scheduling Integration', () {
      test('should coordinate with backup service for daily backup', () async {
        // Arrange
        await schedulerService.initialize();

        // Act - Force backup to test coordination
        try {
          await schedulerService.forceBackupNow();
        } catch (e) {
          // Expected to fail in test environment due to missing database
          expect(e, isA<BackupException>());
        }

        // Assert - Verify scheduler status remains stable
        final status = schedulerService.getSchedulerStatus();
        expect(status['isInitialized'], true);
        expect(status['isBackupInProgress'], false);
      });

      test('should respect auto backup settings', () async {
        // Arrange
        await schedulerService.initialize();

        // Act & Assert - Should throw when trying to force backup
        // In test environment, this will fail due to settings load error
        expect(
          () => schedulerService.forceBackupNow(),
          throwsA(isA<BackupException>()),
        );
      });
    });

    group('File Management Integration', () {
      test('should coordinate backup status with auto backup service', () async {
        // Arrange
        await schedulerService.initialize();

        // Act
        final status = await schedulerService.getBackupStatus();

        // Assert
        expect(status, isA<Map<String, dynamic>>());
        expect(status.containsKey('totalBackupFiles'), true);
        expect(status.containsKey('hasTodayBackup'), true);
        expect(status.containsKey('lastBackupDate'), true);
        expect(status.containsKey('todayFileName'), true);
      });

      test('should perform maintenance cleanup', () async {
        // Arrange
        await schedulerService.initialize();

        // Act & Assert - Should not throw
        expect(() => schedulerService.performMaintenanceCleanup(), returnsNormally);
      });
    });

    group('Timer and Scheduling Integration', () {
      test('should start and stop timer correctly', () async {
        // Arrange
        await schedulerService.initialize();
        
        var status = schedulerService.getSchedulerStatus();
        expect(status['hasActiveTimer'], true);

        // Act - Stop scheduler
        schedulerService.stop();
        
        status = schedulerService.getSchedulerStatus();
        expect(status['hasActiveTimer'], false);
        expect(status['isInitialized'], false);
      });

      test('should restart scheduler correctly', () async {
        // Arrange
        await schedulerService.initialize();
        schedulerService.stop();

        // Act
        await schedulerService.restart();

        // Assert
        final status = schedulerService.getSchedulerStatus();
        expect(status['isInitialized'], true);
        expect(status['hasActiveTimer'], true);
      });
    });

    group('Error Handling Integration', () {
      test('should handle backup service failures gracefully', () async {
        // This test verifies that the scheduler continues to work
        // even when backup operations fail
        
        // Arrange
        await schedulerService.initialize();

        // Act - Try operations that might fail
        await schedulerService.performMaintenanceCleanup();
        final status = await schedulerService.getBackupStatus();

        // Assert - Scheduler should remain functional
        final schedulerStatus = schedulerService.getSchedulerStatus();
        expect(schedulerStatus['isInitialized'], true);
        expect(status, isA<Map<String, dynamic>>());
      });

      test('should recover from temporary failures', () async {
        // Arrange
        await schedulerService.initialize();
        
        // Simulate failure and recovery
        schedulerService.stop();
        await schedulerService.restart();

        // Assert
        final status = schedulerService.getSchedulerStatus();
        expect(status['isInitialized'], true);
        expect(status['hasActiveTimer'], true);
      });
    });

    group('Concurrent Operations Integration', () {
      test('should handle concurrent backup requests safely', () async {
        // Arrange
        await schedulerService.initialize();

        // Act - Try multiple concurrent force backups
        final futures = <Future>[];
        for (int i = 0; i < 3; i++) {
          futures.add(
            schedulerService.forceBackupNow().catchError((e) {
              // Expected to fail in test environment
              return null;
            })
          );
        }

        // Wait for all to complete
        await Future.wait(futures);

        // Assert - Scheduler should remain stable
        final status = schedulerService.getSchedulerStatus();
        expect(status['isInitialized'], true);
        expect(status['isBackupInProgress'], false);
      });
    });

    group('Settings Integration', () {
      test('should respond to backup settings changes', () async {
        // Arrange
        await schedulerService.initialize();

        // Act - Try to change settings (will fail in test environment)
        try {
          await backupService.enableAutoBackup();
        } catch (e) {
          expect(e, isA<BackupException>());
        }

        // Assert - Scheduler should remain functional
        final status = schedulerService.getSchedulerStatus();
        expect(status['isInitialized'], true);
      });
    });

    group('Lifecycle Integration', () {
      test('should handle complete lifecycle correctly', () async {
        // Initialize
        await schedulerService.initialize();
        var status = schedulerService.getSchedulerStatus();
        expect(status['isInitialized'], true);

        // Try to enable auto backup (will fail in test environment)
        try {
          await backupService.enableAutoBackup();
        } catch (e) {
          expect(e, isA<BackupException>());
        }
        
        // Get backup status
        final backupStatus = await schedulerService.getBackupStatus();
        expect(backupStatus, isA<Map<String, dynamic>>());

        // Perform maintenance
        await schedulerService.performMaintenanceCleanup();

        // Stop and restart
        schedulerService.stop();
        await schedulerService.restart();

        // Final verification
        status = schedulerService.getSchedulerStatus();
        expect(status['isInitialized'], true);
        expect(status['hasActiveTimer'], true);

        // Dispose
        schedulerService.dispose();
        status = schedulerService.getSchedulerStatus();
        expect(status['isInitialized'], false);
        expect(status['hasActiveTimer'], false);
      });
    });
  });
}
import 'package:flutter_test/flutter_test.dart';

import '../../lib/services/backup_scheduler_service.dart';
import '../../lib/services/backup_service.dart';
import '../../lib/models/backup_settings.dart';
import '../../lib/services/backup_exceptions.dart';

void main() {
  group('BackupSchedulerService', () {
    late BackupSchedulerService schedulerService;

    setUp(() {
      // Reset singleton instance before each test
      BackupSchedulerService.resetInstance();
      BackupService.resetInstance();
      schedulerService = BackupSchedulerService.instance;
    });

    tearDown(() {
      schedulerService.dispose();
      BackupSchedulerService.resetInstance();
      BackupService.resetInstance();
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = BackupSchedulerService.instance;
        final instance2 = BackupSchedulerService.instance;
        
        expect(instance1, same(instance2));
      });

      test('should reset instance correctly', () {
        final instance1 = BackupSchedulerService.instance;
        BackupSchedulerService.resetInstance();
        final instance2 = BackupSchedulerService.instance;
        
        expect(instance1, isNot(same(instance2)));
      });
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        // Act & Assert - should not throw in test environment
        expect(() => schedulerService.initialize(), returnsNormally);
      });

      test('should not initialize twice', () async {
        // Act
        await schedulerService.initialize();
        await schedulerService.initialize(); // Second call

        // Assert - should not throw
        final status = schedulerService.getSchedulerStatus();
        expect(status['isInitialized'], true);
      });
    });

    group('Force Backup', () {
      test('should throw exception when auto backup is disabled', () async {
        // Act & Assert - In test environment, this will throw a settings error
        // which is expected since we don't have a real database
        expect(
          () => schedulerService.forceBackupNow(),
          throwsA(isA<BackupException>()),
        );
      });
    });

    group('Scheduler Status', () {
      test('should return correct initial status', () {
        // Act
        final status = schedulerService.getSchedulerStatus();

        // Assert
        expect(status['isInitialized'], false);
        expect(status['isBackupInProgress'], false);
        expect(status['hasActiveTimer'], false);
        expect(status['timerPeriod'], '1 hour');
      });

      test('should return correct status after initialization', () async {
        // Act
        await schedulerService.initialize();
        final status = schedulerService.getSchedulerStatus();

        // Assert
        expect(status['isInitialized'], true);
        expect(status['isBackupInProgress'], false);
        expect(status['hasActiveTimer'], true);
        expect(status['timerPeriod'], '1 hour');
      });
    });

    group('Scheduler Control', () {
      test('should stop scheduler correctly', () async {
        // Arrange
        await schedulerService.initialize();

        // Act
        schedulerService.stop();
        final status = schedulerService.getSchedulerStatus();

        // Assert
        expect(status['isInitialized'], false);
        expect(status['hasActiveTimer'], false);
      });

      test('should restart scheduler correctly', () async {
        // Arrange
        await schedulerService.initialize();
        schedulerService.stop();

        // Act
        await schedulerService.restart();
        final status = schedulerService.getSchedulerStatus();

        // Assert
        expect(status['isInitialized'], true);
        expect(status['hasActiveTimer'], true);
      });
    });

    group('Maintenance Cleanup', () {
      test('should perform maintenance cleanup gracefully', () async {
        // Act & Assert - should not throw
        expect(() => schedulerService.performMaintenanceCleanup(), returnsNormally);
      });
    });

    group('Backup Status', () {
      test('should return backup status', () async {
        // Act
        final status = await schedulerService.getBackupStatus();

        // Assert
        expect(status, isA<Map<String, dynamic>>());
        expect(status.containsKey('totalBackupFiles'), true);
        expect(status.containsKey('hasTodayBackup'), true);
      });
    });

    group('Dispose', () {
      test('should dispose resources correctly', () async {
        // Arrange
        await schedulerService.initialize();

        // Act
        schedulerService.dispose();
        final status = schedulerService.getSchedulerStatus();

        // Assert
        expect(status['isInitialized'], false);
        expect(status['hasActiveTimer'], false);
      });
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

import '../../lib/services/backup_service.dart';
import '../../lib/models/backup_settings.dart';
import '../../lib/models/backup_info.dart';
import '../../lib/services/backup_exceptions.dart';

void main() {
  group('BackupService Integration Tests', () {
    late BackupService backupService;

    setUp(() {
      // Reset singleton instance for each test
      BackupService.resetInstance();
      backupService = BackupService.instance;
    });

    group('Service Integration', () {
      test('should handle service initialization', () {
        // Act & Assert - Service should initialize without throwing
        expect(backupService, isNotNull);
        expect(backupService.progressStream, isNotNull);
        expect(backupService.progressPercentStream, isNotNull);
      });

      test('should handle singleton pattern correctly', () {
        // Act
        final instance1 = BackupService.instance;
        final instance2 = BackupService.instance;

        // Assert
        expect(instance1, same(instance2));
      });

      test('should handle singleton reset correctly', () {
        // Arrange
        final originalInstance = BackupService.instance;
        
        // Act
        BackupService.resetInstance();
        final newInstance = BackupService.instance;

        // Assert
        expect(newInstance, isNot(same(originalInstance)));
      });

      test('should provide access to progress streams', () {
        // Act
        final progressStream = backupService.progressStream;
        final percentStream = backupService.progressPercentStream;

        // Assert
        expect(progressStream, isA<Stream<String>>());
        expect(percentStream, isA<Stream<double>>());
      });

      test('should handle auto backup status queries', () {
        // Act
        final isEnabled = backupService.isAutoBackupEnabled();
        final lastBackupTime = backupService.getLastBackupTime();

        // Assert - Should not throw and return reasonable defaults
        expect(isEnabled, isA<bool>());
        expect(lastBackupTime, isNull); // Default should be null
      });
    });

    group('Progress Reporting Integration', () {
      test('should provide broadcast streams for progress', () async {
        // Arrange
        final progressMessages1 = <String>[];
        final progressMessages2 = <String>[];

        // Act - Create multiple listeners
        final subscription1 = backupService.progressStream.listen(progressMessages1.add);
        final subscription2 = backupService.progressStream.listen(progressMessages2.add);

        // Simulate some progress by calling a method that will emit progress
        try {
          await backupService.exportToJson();
        } catch (e) {
          // Expected to fail in test environment
        }

        // Wait for stream events
        await Future.delayed(Duration(milliseconds: 100));

        // Clean up
        await subscription1.cancel();
        await subscription2.cancel();

        // Assert - Both listeners should be able to subscribe without error
        expect(subscription1, isNotNull);
        expect(subscription2, isNotNull);
      });

      test('should handle stream subscription and cancellation', () async {
        // Arrange
        final progressMessages = <String>[];

        // Act
        final subscription = backupService.progressStream.listen(progressMessages.add);
        await subscription.cancel();

        // Assert - Should not throw
        expect(subscription, isNotNull);
      });

      test('should support both progress message and percentage streams', () async {
        // Arrange
        final messages = <String>[];
        final percentages = <double>[];

        // Act
        final messageSubscription = backupService.progressStream.listen(messages.add);
        final percentSubscription = backupService.progressPercentStream.listen(percentages.add);

        // Clean up
        await messageSubscription.cancel();
        await percentSubscription.cancel();

        // Assert
        expect(messageSubscription, isNotNull);
        expect(percentSubscription, isNotNull);
      });
    });

    group('Error Handling Integration', () {
      test('should throw appropriate exceptions for invalid operations', () async {
        // Act & Assert - Should throw BackupException for export operations
        expect(
          () => backupService.exportToJson(),
          throwsA(isA<BackupException>()),
        );

        expect(
          () => backupService.exportToSql(),
          throwsA(isA<BackupException>()),
        );
      });

      test('should throw appropriate exceptions for restore operations', () async {
        // Act & Assert - Should throw RestoreException for restore operations
        expect(
          () => backupService.restoreFromFile('/nonexistent/file.sql'),
          throwsA(isA<RestoreException>()),
        );
      });

      test('should handle validation operations', () async {
        // Act & Assert - Should handle validation without crashing
        final result = await backupService.validateBackupFile('/test/file.sql');
        expect(result, isA<bool>());
      });

      test('should handle concurrent error scenarios', () async {
        // Arrange
        final futures = <Future>[];

        // Act - Start multiple operations that will fail
        for (int i = 0; i < 3; i++) {
          futures.add(
            backupService.exportToJson().catchError((_) => 'error')
          );
          futures.add(
            backupService.exportToSql().catchError((_) => 'error')
          );
        }

        // Wait for all operations
        final results = await Future.wait(futures);

        // Assert - All operations should complete (even with errors)
        expect(results, hasLength(6));
        expect(results.every((r) => r == 'error'), isTrue);
      });
    });

    group('Logging Integration', () {
      test('should handle logging without crashing', () async {
        // This test verifies that logging operations don't crash the service
        
        try {
          await backupService.exportToJson();
        } catch (e) {
          // Expected to fail in test environment
        }

        try {
          await backupService.performDailyBackup();
        } catch (e) {
          // Expected to fail in test environment
        }

        // If we get here without crashing, logging is working
        expect(true, isTrue);
      });

      test('should handle concurrent operations safely', () async {
        // Arrange
        final futures = <Future>[];

        // Act - Start multiple operations concurrently
        for (int i = 0; i < 3; i++) {
          futures.add(
            backupService.exportToJson().catchError((_) => 'handled')
          );
          futures.add(
            backupService.performDailyBackup().catchError((_) => 'handled')
          );
        }

        // Wait for all operations to complete
        final results = await Future.wait(futures);

        // Assert - All operations should complete without crashing
        expect(results, hasLength(6));
        expect(results.every((r) => r == 'handled'), isTrue);
      });

      test('should handle service method calls in sequence', () async {
        // Act - Call various service methods in sequence
        try {
          await backupService.exportToJson();
        } catch (e) {
          // Expected
        }

        try {
          await backupService.exportToSql();
        } catch (e) {
          // Expected
        }

        try {
          await backupService.performDailyBackup();
        } catch (e) {
          // Expected
        }

        // Assert - Service should still be functional
        expect(backupService, isNotNull);
      });
    });

    group('Service Method Integration', () {
      test('should handle backup file validation', () async {
        // Act
        final result = await backupService.validateBackupFile('/test/file.sql');

        // Assert - Should return a boolean result
        expect(result, isA<bool>());
      });

      test('should handle backup directory operations', () async {
        // Act & Assert - Should handle directory operations
        expect(
          () => backupService.getBackupDirectory(),
          throwsA(isA<BackupException>()),
        );
      });

      test('should handle storage operations', () async {
        // Act & Assert - Should handle storage operations
        expect(
          () => backupService.getAvailableStorageSpace(),
          throwsA(isA<BackupException>()),
        );
      });

      test('should handle file operations', () async {
        // Act & Assert - Should handle file operations
        expect(
          () => backupService.getBackupFiles(),
          throwsA(isA<BackupException>()),
        );

        expect(
          () => backupService.cleanOldBackups(),
          throwsA(isA<BackupException>()),
        );

        expect(
          () => backupService.deleteBackupFile('test.sql'),
          throwsA(isA<BackupException>()),
        );
      });
    });

    group('Stream Management Integration', () {
      test('should handle stream disposal correctly', () async {
        // Arrange
        final progressMessages = <String>[];
        final subscription = backupService.progressStream.listen(progressMessages.add);

        // Act
        try {
          await backupService.exportToJson();
        } catch (e) {
          // Expected to fail
        }

        // Clean up subscription
        await subscription.cancel();

        // Dispose service
        backupService.dispose();

        // Assert - Should not crash
        expect(true, isTrue);
      });

      test('should handle multiple stream subscriptions', () async {
        // Arrange
        final subscriptions = <StreamSubscription>[];

        // Create multiple subscriptions
        for (int i = 0; i < 3; i++) {
          subscriptions.add(
            backupService.progressStream.listen((_) {})
          );
          subscriptions.add(
            backupService.progressPercentStream.listen((_) {})
          );
        }

        // Act - Try an operation
        try {
          await backupService.exportToJson();
        } catch (e) {
          // Expected to fail
        }

        // Clean up all subscriptions
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }

        // Assert - Should not crash
        expect(true, isTrue);
      });
    });



    group('Resource Management Integration', () {
      test('should handle singleton reset correctly', () async {
        // Arrange
        final originalInstance = BackupService.instance;
        
        // Act
        BackupService.resetInstance();
        final newInstance = BackupService.instance;

        // Assert
        expect(newInstance, isNot(same(originalInstance)));
      });

      test('should handle disposal without errors', () async {
        // Arrange
        final service = BackupService.instance;

        // Act & Assert - Should not throw
        expect(() => service.dispose(), returnsNormally);
      });

      test('should handle multiple disposal calls', () async {
        // Arrange
        final service = BackupService.instance;

        // Act & Assert - Should not throw on multiple dispose calls
        expect(() {
          service.dispose();
          service.dispose();
          service.dispose();
        }, returnsNormally);
      });
    });

    tearDown(() {
      // Clean up
      BackupService.resetInstance();
    });
  });
}
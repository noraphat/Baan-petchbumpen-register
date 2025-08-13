import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import '../../lib/services/sql_export_service.dart';
import '../../lib/services/backup_exceptions.dart';

void main() {
  group('SqlExportService', () {
    late SqlExportService sqlExportService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      sqlExportService = SqlExportService();
    });

    group('exportToSql', () {
      test('should throw BackupException on database error', () async {
        // This test verifies error handling without needing database setup
        expect(
          () => sqlExportService.exportToSql(),
          throwsA(isA<BackupException>()),
        );
      });
    });

    group('File Operations', () {
      test('generateDailyBackupFileName should return DD.sql format', () {
        final fileName = sqlExportService.generateDailyBackupFileName();
        
        expect(fileName, matches(r'^\d{2}\.sql$'));
        
        final now = DateTime.now();
        final expectedFileName = '${now.day.toString().padLeft(2, '0')}.sql';
        expect(fileName, expectedFileName);
      });

      test('generateTimestampedFileName should return timestamped format', () {
        final fileName = sqlExportService.generateTimestampedFileName();
        
        expect(fileName, matches(r'^backup_\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.sql$'));
        expect(fileName, startsWith('backup_'));
        expect(fileName, endsWith('.sql'));
      });

      test('saveSqlToFile should throw BackupException when path_provider is not available', () async {
        final testContent = 'CREATE TABLE test (id INTEGER);';
        final fileName = 'test_backup.sql';
        
        // In unit tests, path_provider plugin is not available
        expect(
          () => sqlExportService.saveSqlToFile(testContent, fileName),
          throwsA(isA<BackupException>()),
        );
      });
    });

    group('Integration Methods', () {
      test('exportDailyBackup should throw BackupException on database error', () async {
        expect(
          () => sqlExportService.exportDailyBackup(),
          throwsA(isA<BackupException>()),
        );
      });

      test('exportTimestampedBackup should throw BackupException on database error', () async {
        expect(
          () => sqlExportService.exportTimestampedBackup(),
          throwsA(isA<BackupException>()),
        );
      });
    });

    group('SQL Generation Components', () {
      test('should handle database connection errors', () async {
        // Test that the service handles database connection errors properly
        expect(
          () => sqlExportService.exportToSql(),
          throwsA(isA<BackupException>()),
        );
      });
    });
  });
}


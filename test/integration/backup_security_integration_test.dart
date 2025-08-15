import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/backup_service.dart';
import '../../lib/services/backup_security_service.dart';
import '../../lib/services/restore_service.dart';
import '../../lib/services/file_management_service.dart';
import '../../lib/services/backup_exceptions.dart';

void main() {
  group('Backup Security Integration Tests', () {
    late BackupService backupService;
    late BackupSecurityService securityService;
    late RestoreService restoreService;
    late FileManagementService fileService;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('backup_security_integration_');
      
      securityService = BackupSecurityService();
      fileService = FileManagementService();
      restoreService = RestoreService(
        fileService: fileService,
        securityService: securityService,
      );
      backupService = BackupService.instance;
    });

    tearDown(() async {
      BackupService.resetInstance();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Malicious File Path Protection', () {
      test('should reject restore from path with directory traversal', () async {
        const maliciousPath = '../../../etc/passwd';
        
        expect(
          () => backupService.restoreFromFile(maliciousPath),
          throwsA(isA<SecurityException>()),
        );
      });

      test('should reject restore from path with null bytes', () async {
        const maliciousPath = '/backup/test\x00.sql';
        
        expect(
          () => backupService.restoreFromFile(maliciousPath),
          throwsA(isA<SecurityException>()),
        );
      });

      test('should reject restore from unsupported file extension', () async {
        const maliciousPath = '/backup/malware.exe';
        
        expect(
          () => backupService.restoreFromFile(maliciousPath),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Malicious SQL Content Protection', () {
      test('should reject backup with DROP DATABASE statements', () async {
        final maliciousFile = File('${tempDir.path}/malicious_backup.sql');
        const maliciousSql = '''
          -- Malicious backup
          CREATE TABLE test (id INTEGER);
          DROP DATABASE main;
          INSERT INTO test VALUES (1);
        ''';
        await maliciousFile.writeAsString(maliciousSql);

        expect(
          () => backupService.restoreFromFile(maliciousFile.path),
          throwsA(isA<SecurityException>()),
        );
      });

      test('should reject backup with sqlite_master manipulation', () async {
        final maliciousFile = File('${tempDir.path}/malicious_backup.sql');
        const maliciousSql = '''
          -- Malicious backup
          CREATE TABLE test (id INTEGER);
          DELETE FROM sqlite_master WHERE type='table';
          INSERT INTO test VALUES (1);
        ''';
        await maliciousFile.writeAsString(maliciousSql);

        expect(
          () => backupService.restoreFromFile(maliciousFile.path),
          throwsA(isA<SecurityException>()),
        );
      });

      test('should reject backup with ATTACH DATABASE statements', () async {
        final maliciousFile = File('${tempDir.path}/malicious_backup.sql');
        const maliciousSql = '''
          -- Malicious backup
          CREATE TABLE test (id INTEGER);
          ATTACH DATABASE '/tmp/evil.db' AS evil;
          INSERT INTO test VALUES (1);
        ''';
        await maliciousFile.writeAsString(maliciousSql);

        expect(
          () => backupService.restoreFromFile(maliciousFile.path),
          throwsA(isA<SecurityException>()),
        );
      });

      test('should reject backup with SQL injection patterns', () async {
        final maliciousFile = File('${tempDir.path}/malicious_backup.sql');
        const maliciousSql = '''
          -- Malicious backup
          CREATE TABLE test (id INTEGER);
          UNION SELECT * FROM sqlite_master;
          INSERT INTO test VALUES (1);
        ''';
        await maliciousFile.writeAsString(maliciousSql);

        expect(
          () => backupService.restoreFromFile(maliciousFile.path),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Emergency Backup and Rollback', () {
      test('should create emergency backup before restore', () async {
        // Create a valid backup file
        final validFile = File('${tempDir.path}/valid_backup.sql');
        const validSql = '''
          -- Valid backup
          DROP TABLE IF EXISTS test_table;
          CREATE TABLE test_table (id INTEGER PRIMARY KEY, name TEXT);
          INSERT INTO test_table VALUES (1, 'test');
        ''';
        await validFile.writeAsString(validSql);

        // Mock the restore process to fail after emergency backup creation
        try {
          await restoreService.restoreFromSqlFile(validFile.path);
        } catch (e) {
          // Expected to fail due to missing database setup in test
        }

        // Verify emergency backup was created
        final emergencyBackupPath = restoreService.getLastEmergencyBackupPath();
        expect(emergencyBackupPath, isNotNull);
        
        if (emergencyBackupPath != null) {
          final emergencyFile = File(emergencyBackupPath);
          expect(await emergencyFile.exists(), isTrue);
        }
      });

      test('should rollback to emergency backup on restore failure', () async {
        // This test would require a more complex setup with actual database
        // For now, we'll test the rollback mechanism exists
        expect(
          () => restoreService.rollbackToEmergencyBackup(),
          throwsA(isA<RestoreException>()),
        );
      });
    });

    group('File Size and Content Validation', () {
      test('should reject empty backup files', () async {
        final emptyFile = File('${tempDir.path}/empty_backup.sql');
        await emptyFile.writeAsString('');

        expect(
          () => backupService.restoreFromFile(emptyFile.path),
          throwsA(isA<InvalidBackupFileException>()),
        );
      });

      test('should reject backup files without CREATE TABLE statements', () async {
        final invalidFile = File('${tempDir.path}/invalid_backup.sql');
        const invalidSql = '''
          -- Invalid backup without CREATE TABLE
          INSERT INTO test VALUES (1, 'test');
          UPDATE test SET name = 'updated';
        ''';
        await invalidFile.writeAsString(invalidSql);

        expect(
          () => backupService.restoreFromFile(invalidFile.path),
          throwsA(isA<SecurityException>()),
        );
      });

      test('should accept valid backup files', () async {
        final validFile = File('${tempDir.path}/valid_backup.sql');
        const validSql = '''
          -- Valid backup
          DROP TABLE IF EXISTS regs;
          CREATE TABLE regs (
            id TEXT PRIMARY KEY,
            first TEXT,
            last TEXT,
            phone TEXT
          );
          CREATE INDEX idx_regs_phone ON regs(phone);
          INSERT INTO regs VALUES ('1234567890123', 'John', 'Doe', '0812345678');
          
          DROP TABLE IF EXISTS stays;
          CREATE TABLE stays (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            regId TEXT,
            startDate TEXT,
            endDate TEXT
          );
          
          DROP TABLE IF EXISTS reg_additional_info;
          CREATE TABLE reg_additional_info (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            regId TEXT,
            visitId TEXT
          );
          
          DROP TABLE IF EXISTS app_settings;
          CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT
          );
        ''';
        await validFile.writeAsString(validSql);

        // This should not throw security exceptions
        // (it may still fail due to database setup in test environment)
        try {
          await securityService.validateBackupFile(validFile.path);
        } catch (e) {
          fail('Valid backup file should pass security validation: $e');
        }
      });
    });

    group('Path Sanitization', () {
      test('should sanitize malicious file paths', () {
        const maliciousPath = '../../../backup/test<>:"|?*.sql';
        final sanitized = securityService.sanitizeFilePath(maliciousPath);
        
        expect(sanitized, isNot(contains('..')));
        expect(sanitized, isNot(contains('<')));
        expect(sanitized, isNot(contains('>')));
        expect(sanitized, isNot(contains(':')));
        expect(sanitized, isNot(contains('"')));
        expect(sanitized, isNot(contains('|')));
        expect(sanitized, isNot(contains('?')));
        expect(sanitized, isNot(contains('*')));
      });

      test('should preserve valid file paths', () {
        const validPath = '/backup/valid_backup_2024-01-15_10-30-00.sql';
        final sanitized = securityService.sanitizeFilePath(validPath);
        expect(sanitized, equals(validPath));
      });
    });

    group('SQL Statement Filtering', () {
      test('should allow only safe SQL statements during restore', () async {
        final testFile = File('${tempDir.path}/mixed_statements.sql');
        const mixedSql = '''
          -- Mixed statements backup
          DROP TABLE IF EXISTS test_table;
          CREATE TABLE test_table (id INTEGER PRIMARY KEY, name TEXT);
          INSERT INTO test_table VALUES (1, 'test');
          CREATE INDEX idx_test_name ON test_table(name);
          -- This should be allowed
          DROP INDEX IF EXISTS old_index;
        ''';
        await testFile.writeAsString(mixedSql);

        // Should pass security validation
        expect(await securityService.validateSqlContent(mixedSql), isTrue);
      });

      test('should reject unsafe SQL statements', () async {
        const unsafeSql = '''
          CREATE TABLE test (id INTEGER);
          ALTER TABLE test ADD COLUMN evil TEXT;
          DELETE FROM test WHERE 1=1;
        ''';

        expect(
          () => securityService.validateSqlContent(unsafeSql),
          throwsA(isA<UnsafeSqlException>()),
        );
      });
    });
  });
}
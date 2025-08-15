import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/backup_security_service.dart';
import '../../lib/services/backup_exceptions.dart';

void main() {
  group('BackupSecurityService', () {
    late BackupSecurityService securityService;
    late Directory tempDir;

    setUp(() async {
      securityService = BackupSecurityService();
      tempDir = await Directory.systemTemp.createTemp('backup_security_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('validateFilePath', () {
      test('should accept valid SQL file path', () async {
        const validPath = '/backup/test_backup.sql';
        expect(await securityService.validateFilePath(validPath), isTrue);
      });

      test('should accept valid JSON file path', () async {
        const validPath = '/backup/test_backup.json';
        expect(await securityService.validateFilePath(validPath), isTrue);
      });

      test('should reject empty file path', () async {
        expect(
          () => securityService.validateFilePath(''),
          throwsA(isA<InvalidFilePathException>()),
        );
      });

      test('should reject directory traversal attempts', () async {
        const maliciousPath = '../../../etc/passwd';
        expect(
          () => securityService.validateFilePath(maliciousPath),
          throwsA(isA<InvalidFilePathException>()),
        );
      });

      test('should reject paths with null bytes', () async {
        const maliciousPath = '/backup/test\x00.sql';
        expect(
          () => securityService.validateFilePath(maliciousPath),
          throwsA(isA<InvalidFilePathException>()),
        );
      });

      test('should reject unsupported file extensions', () async {
        const invalidPath = '/backup/test.exe';
        expect(
          () => securityService.validateFilePath(invalidPath),
          throwsA(isA<InvalidFilePathException>()),
        );
      });

      test('should reject paths with suspicious characters', () async {
        const suspiciousPath = '/backup/test<script>.sql';
        expect(
          () => securityService.validateFilePath(suspiciousPath),
          throwsA(isA<InvalidFilePathException>()),
        );
      });

      test('should reject excessively long filenames', () async {
        final longName = 'a' * 300;
        final longPath = '/backup/$longName.sql';
        expect(
          () => securityService.validateFilePath(longPath),
          throwsA(isA<InvalidFilePathException>()),
        );
      });
    });

    group('validateSqlContent', () {
      test('should accept valid backup SQL', () async {
        const validSql = '''
          -- Backup created on 2024-01-15
          DROP TABLE IF EXISTS test_table;
          CREATE TABLE test_table (id INTEGER PRIMARY KEY, name TEXT);
          INSERT INTO test_table VALUES (1, 'test');
          CREATE INDEX idx_test_name ON test_table(name);
        ''';
        expect(await securityService.validateSqlContent(validSql), isTrue);
      });

      test('should reject empty SQL content', () async {
        expect(
          () => securityService.validateSqlContent(''),
          throwsA(isA<UnsafeSqlException>()),
        );
      });

      test('should reject dangerous DROP DATABASE statements', () async {
        const dangerousSql = '''
          CREATE TABLE test (id INTEGER);
          DROP DATABASE main;
        ''';
        expect(
          () => securityService.validateSqlContent(dangerousSql),
          throwsA(isA<UnsafeSqlException>()),
        );
      });

      test('should reject sqlite_master manipulation', () async {
        const dangerousSql = '''
          CREATE TABLE test (id INTEGER);
          DELETE FROM sqlite_master WHERE name='test';
        ''';
        expect(
          () => securityService.validateSqlContent(dangerousSql),
          throwsA(isA<UnsafeSqlException>()),
        );
      });

      test('should reject ATTACH DATABASE statements', () async {
        const dangerousSql = '''
          CREATE TABLE test (id INTEGER);
          ATTACH DATABASE '/tmp/malicious.db' AS evil;
        ''';
        expect(
          () => securityService.validateSqlContent(dangerousSql),
          throwsA(isA<UnsafeSqlException>()),
        );
      });

      test('should reject PRAGMA writable_schema', () async {
        const dangerousSql = '''
          CREATE TABLE test (id INTEGER);
          PRAGMA writable_schema = ON;
        ''';
        expect(
          () => securityService.validateSqlContent(dangerousSql),
          throwsA(isA<UnsafeSqlException>()),
        );
      });

      test('should reject SQL injection patterns', () async {
        const injectionSql = '''
          CREATE TABLE test (id INTEGER);
          UNION SELECT * FROM sqlite_master;
        ''';
        expect(
          () => securityService.validateSqlContent(injectionSql),
          throwsA(isA<UnsafeSqlException>()),
        );
      });

      test('should reject SQL without CREATE TABLE statements', () async {
        const invalidSql = '''
          INSERT INTO test VALUES (1, 'test');
          UPDATE test SET name = 'updated';
        ''';
        expect(
          () => securityService.validateSqlContent(invalidSql),
          throwsA(isA<UnsafeSqlException>()),
        );
      });

      test('should reject SQL with unbalanced parentheses', () async {
        const invalidSql = '''
          CREATE TABLE test (id INTEGER, name TEXT;
          INSERT INTO test VALUES (1, 'test');
        ''';
        expect(
          () => securityService.validateSqlContent(invalidSql),
          throwsA(isA<UnsafeSqlException>()),
        );
      });

      test('should reject excessively large SQL content', () async {
        final largeSql = 'CREATE TABLE test (id INTEGER); ' * 2000000; // Make it larger to exceed limit
        expect(
          () => securityService.validateSqlContent(largeSql),
          throwsA(isA<UnsafeSqlException>()),
        );
      });
    });

    group('validateBackupFile', () {
      test('should validate existing SQL backup file', () async {
        final testFile = File('${tempDir.path}/test_backup.sql');
        const validSql = '''
          -- Test backup
          DROP TABLE IF EXISTS test_table;
          CREATE TABLE test_table (id INTEGER PRIMARY KEY, name TEXT);
          INSERT INTO test_table VALUES (1, 'test');
        ''';
        await testFile.writeAsString(validSql);

        expect(await securityService.validateBackupFile(testFile.path), isTrue);
      });

      test('should reject non-existent file', () async {
        const nonExistentPath = '/tmp/non_existent_backup.sql';
        expect(
          () => securityService.validateBackupFile(nonExistentPath),
          throwsA(isA<InvalidBackupFileException>()),
        );
      });

      test('should reject empty backup file', () async {
        final testFile = File('${tempDir.path}/empty_backup.sql');
        await testFile.writeAsString('');

        expect(
          () => securityService.validateBackupFile(testFile.path),
          throwsA(isA<InvalidBackupFileException>()),
        );
      });

      test('should reject backup file with dangerous SQL', () async {
        final testFile = File('${tempDir.path}/dangerous_backup.sql');
        const dangerousSql = '''
          CREATE TABLE test (id INTEGER);
          DROP DATABASE main;
        ''';
        await testFile.writeAsString(dangerousSql);

        expect(
          () => securityService.validateBackupFile(testFile.path),
          throwsA(isA<SecurityException>()),
        );
      });

      test('should validate JSON backup file', () async {
        final testFile = File('${tempDir.path}/test_backup.json');
        const validJson = '''
          {
            "export_info": {
              "timestamp": "2024-01-15T10:30:00Z",
              "version": "1.0"
            },
            "tables": {
              "test": []
            }
          }
        ''';
        await testFile.writeAsString(validJson);

        expect(await securityService.validateBackupFile(testFile.path), isTrue);
      });

      test('should reject invalid JSON backup file', () async {
        final testFile = File('${tempDir.path}/invalid_backup.json');
        const invalidJson = 'not valid json content';
        await testFile.writeAsString(invalidJson);

        expect(
          () => securityService.validateBackupFile(testFile.path),
          throwsA(isA<InvalidBackupFileException>()),
        );
      });
    });

    group('sanitizeFilePath', () {
      test('should remove directory traversal attempts', () {
        const maliciousPath = '../../../backup/test.sql';
        final sanitized = securityService.sanitizeFilePath(maliciousPath);
        expect(sanitized, equals('backup/test.sql'));
      });

      test('should remove null bytes', () {
        const maliciousPath = '/backup/test\x00.sql';
        final sanitized = securityService.sanitizeFilePath(maliciousPath);
        expect(sanitized, equals('/backup/test.sql'));
      });

      test('should replace suspicious characters', () {
        const suspiciousPath = '/backup/test<>:"|?*.sql';
        final sanitized = securityService.sanitizeFilePath(suspiciousPath);
        expect(sanitized, equals('/backup/test_______.sql')); // Fixed expected result
      });

      test('should truncate excessively long filenames', () {
        final longName = 'a' * 300;
        final longPath = '/backup/$longName.sql';
        final sanitized = securityService.sanitizeFilePath(longPath);
        
        final sanitizedFileName = sanitized.split('/').last;
        expect(sanitizedFileName.length, lessThanOrEqualTo(255));
        expect(sanitizedFileName.endsWith('.sql'), isTrue);
      });

      test('should preserve valid paths unchanged', () {
        const validPath = '/backup/valid_backup_2024-01-15.sql';
        final sanitized = securityService.sanitizeFilePath(validPath);
        expect(sanitized, equals(validPath));
      });
    });
  });
}
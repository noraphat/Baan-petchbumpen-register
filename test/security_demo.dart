import 'dart:io';
import '../lib/services/backup_security_service.dart';
import '../lib/services/backup_exceptions.dart';

/// Demonstration script showing the security features in action
void main() async {
  final securityService = BackupSecurityService();
  
  print('=== Backup Security Service Demo ===\n');
  
  // Test 1: File Path Validation
  print('1. File Path Security Validation:');
  await testFilePaths(securityService);
  
  // Test 2: SQL Content Validation
  print('\n2. SQL Content Security Validation:');
  await testSqlContent(securityService);
  
  // Test 3: Path Sanitization
  print('\n3. Path Sanitization:');
  testPathSanitization(securityService);
  
  print('\n=== Demo Complete ===');
}

Future<void> testFilePaths(BackupSecurityService service) async {
  final testPaths = [
    '/backup/valid_backup.sql',
    '../../../etc/passwd',
    '/backup/test\x00.sql',
    '/backup/malware.exe',
    '/backup/test<script>.sql',
  ];
  
  for (final path in testPaths) {
    try {
      await service.validateFilePath(path);
      print('  ✅ SAFE: $path');
    } on SecurityException catch (e) {
      print('  ❌ BLOCKED: $path - ${e.message}');
    }
  }
}

Future<void> testSqlContent(BackupSecurityService service) async {
  final testSqlStatements = [
    {
      'name': 'Valid backup SQL',
      'sql': '''
        DROP TABLE IF EXISTS test_table;
        CREATE TABLE test_table (id INTEGER PRIMARY KEY, name TEXT);
        INSERT INTO test_table VALUES (1, 'test');
      '''
    },
    {
      'name': 'Dangerous DROP DATABASE',
      'sql': '''
        CREATE TABLE test (id INTEGER);
        DROP DATABASE main;
      '''
    },
    {
      'name': 'sqlite_master manipulation',
      'sql': '''
        CREATE TABLE test (id INTEGER);
        DELETE FROM sqlite_master WHERE name='test';
      '''
    },
    {
      'name': 'SQL injection pattern',
      'sql': '''
        CREATE TABLE test (id INTEGER);
        UNION SELECT * FROM sqlite_master;
      '''
    },
  ];
  
  for (final test in testSqlStatements) {
    try {
      await service.validateSqlContent(test['sql'] as String);
      print('  ✅ SAFE: ${test['name']}');
    } on SecurityException catch (e) {
      print('  ❌ BLOCKED: ${test['name']} - ${e.message}');
    }
  }
}

void testPathSanitization(BackupSecurityService service) {
  final testPaths = [
    '../../../backup/test.sql',
    '/backup/test\x00.sql',
    '/backup/test<>:"|?*.sql',
    '/backup/valid_backup_2024-01-15.sql',
  ];
  
  for (final path in testPaths) {
    final sanitized = service.sanitizeFilePath(path);
    print('  Original: $path');
    print('  Sanitized: $sanitized');
    print('');
  }
}
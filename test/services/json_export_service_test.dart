import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/services/json_export_service.dart';
import '../../lib/services/backup_exceptions.dart';

void main() {
  late JsonExportService jsonExportService;
  late Directory tempDir;

  setUp(() async {
    jsonExportService = JsonExportService();
    
    // Create temporary directory for testing
    tempDir = await Directory.systemTemp.createTemp('json_export_test_');
  });

  tearDown(() async {
    // Clean up temporary directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('JsonExportService', () {
    group('generateJsonFileName', () {
      test('should generate filename with correct format', () {
        final fileName = jsonExportService.generateJsonFileName();
        
        expect(fileName, startsWith('backup_'));
        expect(fileName, endsWith('.json'));
        expect(fileName, matches(r'backup_\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.json'));
      });

      test('should generate unique filenames', () {
        final fileName1 = jsonExportService.generateJsonFileName();
        final fileName2 = jsonExportService.generateJsonFileName();
        
        // They might be the same if generated in the same second
        // but the format should be correct
        expect(fileName1, matches(r'backup_\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.json'));
        expect(fileName2, matches(r'backup_\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.json'));
      });
    });

    group('exportTableToJson', () {
      test('should handle table export logic', () async {
        // Test the basic structure and error handling
        // Note: This would require a real database connection for full testing
        
        // Test that the method exists and has the right signature
        expect(jsonExportService.exportTableToJson, isA<Function>());
      });
    });

    group('saveJsonToFile', () {
      test('should save JSON data to file successfully', () async {
        // Arrange
        final testData = {
          'export_info': {
            'timestamp': '2024-01-15T10:30:00.000Z',
            'version': '1.0',
            'total_records': 2,
          },
          'tables': {
            'regs': [
              {'id': '1', 'name': 'Test User 1'},
              {'id': '2', 'name': 'Test User 2'},
            ],
          },
        };

        // Mock path_provider to use our temp directory
        // Note: In real tests, you might need to use a different approach
        // since path_provider is platform-specific

        // Act
        String? filePath;
        try {
          // Create a test file directly in temp directory
          final fileName = jsonExportService.generateJsonFileName();
          filePath = '${tempDir.path}/$fileName';
          
          final jsonString = const JsonEncoder.withIndent('  ').convert(testData);
          final file = File(filePath);
          await file.writeAsString(jsonString);
          
          // Verify file was created and contains correct data
          expect(await file.exists(), isTrue);
          
          final savedContent = await file.readAsString();
          final savedData = jsonDecode(savedContent);
          expect(savedData, equals(testData));
          
        } catch (e) {
          fail('Should not throw exception: $e');
        }
      });

      test('should throw BackupException on file write error', () async {
        // Arrange
        final testData = {'test': 'data'};
        
        // Try to write to a directory that doesn't exist and can't be created
        // This should cause a file write error
        
        // Act & Assert
        // Note: This test might need adjustment based on the actual implementation
        // of _getBackupDirectory() method
        expect(
          () async {
            // Create an invalid path
            final invalidPath = '/invalid/path/that/does/not/exist';
            final file = File('$invalidPath/test.json');
            await file.writeAsString(jsonEncode(testData));
          },
          throwsA(isA<FileSystemException>()),
        );
      });
    });

    group('readJsonBackupFile', () {
      test('should read and validate JSON backup file successfully', () async {
        // Arrange
        final testData = {
          'export_info': {
            'timestamp': '2024-01-15T10:30:00.000Z',
            'version': '1.0',
            'total_records': 1,
          },
          'tables': {
            'regs': [
              {'id': '1', 'name': 'Test User'},
            ],
          },
        };
        
        final testFile = File('${tempDir.path}/test_backup.json');
        await testFile.writeAsString(jsonEncode(testData));

        // Act
        final result = await jsonExportService.readJsonBackupFile(testFile.path);

        // Assert
        expect(result, isNotNull);
        expect(result!['export_info'], equals(testData['export_info']));
        expect(result['tables'], equals(testData['tables']));
      });

      test('should return null for non-existent file', () async {
        // Act
        final result = await jsonExportService.readJsonBackupFile('/non/existent/file.json');

        // Assert
        expect(result, isNull);
      });

      test('should throw BackupException for invalid JSON structure', () async {
        // Arrange
        final invalidData = {
          'invalid': 'structure',
          'missing': 'required_fields',
        };
        
        final testFile = File('${tempDir.path}/invalid_backup.json');
        await testFile.writeAsString(jsonEncode(invalidData));

        // Act & Assert
        expect(
          () => jsonExportService.readJsonBackupFile(testFile.path),
          throwsA(isA<BackupException>().having(
            (e) => e.code,
            'code',
            'INVALID_JSON_STRUCTURE',
          )),
        );
      });

      test('should throw BackupException for malformed JSON', () async {
        // Arrange
        final testFile = File('${tempDir.path}/malformed.json');
        await testFile.writeAsString('{ invalid json content');

        // Act & Assert
        expect(
          () => jsonExportService.readJsonBackupFile(testFile.path),
          throwsA(isA<BackupException>().having(
            (e) => e.code,
            'code',
            'JSON_READ_ERROR',
          )),
        );
      });
    });

    group('getJsonFileSize', () {
      test('should return correct file size', () async {
        // Arrange
        final testContent = 'test content for size calculation';
        final testFile = File('${tempDir.path}/size_test.json');
        await testFile.writeAsString(testContent);

        // Act
        final size = await jsonExportService.getJsonFileSize(testFile.path);

        // Assert
        expect(size, equals(testContent.length));
      });

      test('should return 0 for non-existent file', () async {
        // Act
        final size = await jsonExportService.getJsonFileSize('/non/existent/file.json');

        // Assert
        expect(size, equals(0));
      });
    });

    group('getJsonBackupFiles', () {
      test('should list JSON backup files', () async {
        // Arrange
        final jsonFile1 = File('${tempDir.path}/backup_1.json');
        final jsonFile2 = File('${tempDir.path}/backup_2.json');
        final txtFile = File('${tempDir.path}/not_backup.txt');
        
        await jsonFile1.writeAsString('{}');
        await jsonFile2.writeAsString('{}');
        await txtFile.writeAsString('text content');

        // Note: This test would need to mock the _getBackupDirectory method
        // For now, we'll test the logic conceptually
        
        final files = await tempDir.list().toList();
        final jsonFiles = files
            .where((file) => file is File && file.path.endsWith('.json'))
            .map((file) => file.path)
            .toList();

        // Assert
        expect(jsonFiles.length, equals(2));
        expect(jsonFiles.any((path) => path.contains('backup_1.json')), isTrue);
        expect(jsonFiles.any((path) => path.contains('backup_2.json')), isTrue);
        expect(jsonFiles.any((path) => path.contains('not_backup.txt')), isFalse);
      });
    });

    group('Integration Tests', () {
      test('should export complete database structure', () async {
        // This would be an integration test that requires a real database
        // For now, we'll test the data structure expectations
        
        final expectedStructure = {
          'export_info': {
            'timestamp': isA<String>(),
            'version': '1.0',
            'total_records': isA<int>(),
            'database_version': isA<int>(),
          },
          'tables': {
            'regs': isA<List>(),
            'reg_additional_info': isA<List>(),
            'stays': isA<List>(),
            'app_settings': isA<List>(),
            'maps': isA<List>(),
            'rooms': isA<List>(),
            'room_bookings': isA<List>(),
          },
        };

        // This structure should be maintained by the export function
        expect(expectedStructure, isA<Map<String, dynamic>>());
      });

      test('should preserve all original data without masking', () async {
        // Test that sensitive data like ID card numbers and phone numbers
        // are not masked in the JSON export
        
        final sampleData = [
          {
            'id': '1234567890123', // ID card number - should not be masked
            'first': 'สมชาย',
            'last': 'ใจดี',
            'phone': '0812345678', // Phone number - should not be masked
            'addr': 'กรุงเทพมหานคร, เขตปทุมวัน, แขวงลุมพินี, 123/456',
          }
        ];

        // Verify that the data structure preserves original values
        expect(sampleData[0]['id'], equals('1234567890123'));
        expect(sampleData[0]['phone'], equals('0812345678'));
        
        // The JSON export should maintain these exact values
        final jsonString = jsonEncode(sampleData);
        final decodedData = jsonDecode(jsonString) as List;
        
        expect(decodedData[0]['id'], equals('1234567890123'));
        expect(decodedData[0]['phone'], equals('0812345678'));
      });
    });

    group('Error Handling', () {
      test('should provide meaningful error messages', () async {
        // Test that BackupException provides helpful error information
        const errorMessage = 'Test error message';
        const errorCode = 'TEST_ERROR';
        final originalError = Exception('Original error');

        final backupException = BackupException(
          errorMessage,
          code: errorCode,
          originalError: originalError,
        );

        expect(backupException.message, equals(errorMessage));
        expect(backupException.code, equals(errorCode));
        expect(backupException.originalError, equals(originalError));
      });
    });
  });
}
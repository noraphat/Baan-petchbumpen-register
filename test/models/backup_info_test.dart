import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/backup_info.dart';

void main() {
  group('BackupInfo', () {
    test('should create BackupInfo with all parameters', () {
      final createdAt = DateTime(2024, 1, 15, 10, 30);
      final info = BackupInfo(
        fileName: 'backup_2024-01-15.json',
        createdAt: createdAt,
        fileSize: 1024,
        type: BackupType.json,
        isValid: true,
      );
      
      expect(info.fileName, 'backup_2024-01-15.json');
      expect(info.createdAt, createdAt);
      expect(info.fileSize, 1024);
      expect(info.type, BackupType.json);
      expect(info.isValid, true);
    });
    
    test('should convert to JSON correctly', () {
      final createdAt = DateTime(2024, 1, 15, 10, 30);
      final info = BackupInfo(
        fileName: 'test.sql',
        createdAt: createdAt,
        fileSize: 2048,
        type: BackupType.sql,
        isValid: false,
      );
      
      final json = info.toJson();
      
      expect(json['fileName'], 'test.sql');
      expect(json['createdAt'], createdAt.toIso8601String());
      expect(json['fileSize'], 2048);
      expect(json['type'], 'sql');
      expect(json['isValid'], false);
    });
    
    test('should create from JSON correctly', () {
      final createdAt = DateTime(2024, 1, 15, 10, 30);
      final json = {
        'fileName': 'backup.json',
        'createdAt': createdAt.toIso8601String(),
        'fileSize': 512,
        'type': 'json',
        'isValid': true,
      };
      
      final info = BackupInfo.fromJson(json);
      
      expect(info.fileName, 'backup.json');
      expect(info.createdAt, createdAt);
      expect(info.fileSize, 512);
      expect(info.type, BackupType.json);
      expect(info.isValid, true);
    });
    
    test('should handle unknown backup type in fromJson', () {
      final createdAt = DateTime(2024, 1, 15, 10, 30);
      final json = {
        'fileName': 'backup.unknown',
        'createdAt': createdAt.toIso8601String(),
        'fileSize': 256,
        'type': 'unknown_type',
        'isValid': true,
      };
      
      final info = BackupInfo.fromJson(json);
      
      expect(info.type, BackupType.json); // defaults to json
    });
    
    test('should create copy with updated values', () {
      final original = BackupInfo(
        fileName: 'original.json',
        createdAt: DateTime(2024, 1, 15),
        fileSize: 100,
        type: BackupType.json,
        isValid: true,
      );
      
      final updated = original.copyWith(
        fileName: 'updated.sql',
        type: BackupType.sql,
        isValid: false,
      );
      
      expect(updated.fileName, 'updated.sql');
      expect(updated.type, BackupType.sql);
      expect(updated.isValid, false);
      expect(updated.createdAt, DateTime(2024, 1, 15)); // unchanged
      expect(updated.fileSize, 100); // unchanged
    });
    
    test('should return correct file extension', () {
      final jsonInfo = BackupInfo(
        fileName: 'test.json',
        createdAt: DateTime.now(),
        fileSize: 100,
        type: BackupType.json,
        isValid: true,
      );
      
      final sqlInfo = BackupInfo(
        fileName: 'test.sql',
        createdAt: DateTime.now(),
        fileSize: 100,
        type: BackupType.sql,
        isValid: true,
      );
      
      expect(jsonInfo.fileExtension, '.json');
      expect(sqlInfo.fileExtension, '.sql');
    });
    
    test('should format file size correctly', () {
      final smallFile = BackupInfo(
        fileName: 'small.json',
        createdAt: DateTime.now(),
        fileSize: 512,
        type: BackupType.json,
        isValid: true,
      );
      
      final mediumFile = BackupInfo(
        fileName: 'medium.json',
        createdAt: DateTime.now(),
        fileSize: 1536, // 1.5 KB
        type: BackupType.json,
        isValid: true,
      );
      
      final largeFile = BackupInfo(
        fileName: 'large.json',
        createdAt: DateTime.now(),
        fileSize: 2097152, // 2 MB
        type: BackupType.json,
        isValid: true,
      );
      
      expect(smallFile.formattedFileSize, '512 B');
      expect(mediumFile.formattedFileSize, '1.5 KB');
      expect(largeFile.formattedFileSize, '2.0 MB');
    });
    
    test('should handle equality correctly', () {
      final createdAt = DateTime(2024, 1, 15, 10, 30);
      
      final info1 = BackupInfo(
        fileName: 'test.json',
        createdAt: createdAt,
        fileSize: 1024,
        type: BackupType.json,
        isValid: true,
      );
      
      final info2 = BackupInfo(
        fileName: 'test.json',
        createdAt: createdAt,
        fileSize: 1024,
        type: BackupType.json,
        isValid: true,
      );
      
      final info3 = BackupInfo(
        fileName: 'different.json',
        createdAt: createdAt,
        fileSize: 1024,
        type: BackupType.json,
        isValid: true,
      );
      
      expect(info1, equals(info2));
      expect(info1, isNot(equals(info3)));
      expect(info1.hashCode, equals(info2.hashCode));
    });
    
    test('should have meaningful toString', () {
      final info = BackupInfo(
        fileName: 'test.json',
        createdAt: DateTime(2024, 1, 15),
        fileSize: 1024,
        type: BackupType.json,
        isValid: true,
      );
      
      final string = info.toString();
      
      expect(string, contains('BackupInfo'));
      expect(string, contains('fileName: test.json'));
      expect(string, contains('type: BackupType.json'));
      expect(string, contains('isValid: true'));
    });
  });
  
  group('BackupType', () {
    test('should have correct enum values', () {
      expect(BackupType.values.length, 2);
      expect(BackupType.values, contains(BackupType.json));
      expect(BackupType.values, contains(BackupType.sql));
    });
    
    test('should have correct names', () {
      expect(BackupType.json.name, 'json');
      expect(BackupType.sql.name, 'sql');
    });
  });
}
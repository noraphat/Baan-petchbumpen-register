import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/backup_settings.dart';

void main() {
  group('BackupSettings', () {
    test('should create BackupSettings with required parameters', () {
      final settings = BackupSettings(
        autoBackupEnabled: true,
        backupDirectory: '/test/backup',
      );
      
      expect(settings.autoBackupEnabled, true);
      expect(settings.backupDirectory, '/test/backup');
      expect(settings.maxBackupDays, 31); // default value
      expect(settings.lastBackupTime, null);
    });
    
    test('should create BackupSettings with all parameters', () {
      final lastBackup = DateTime(2024, 1, 15, 10, 30);
      final settings = BackupSettings(
        autoBackupEnabled: false,
        lastBackupTime: lastBackup,
        maxBackupDays: 15,
        backupDirectory: '/custom/backup',
      );
      
      expect(settings.autoBackupEnabled, false);
      expect(settings.lastBackupTime, lastBackup);
      expect(settings.maxBackupDays, 15);
      expect(settings.backupDirectory, '/custom/backup');
    });
    
    test('should convert to JSON correctly', () {
      final lastBackup = DateTime(2024, 1, 15, 10, 30);
      final settings = BackupSettings(
        autoBackupEnabled: true,
        lastBackupTime: lastBackup,
        maxBackupDays: 20,
        backupDirectory: '/test/backup',
      );
      
      final json = settings.toJson();
      
      expect(json['autoBackupEnabled'], true);
      expect(json['lastBackupTime'], lastBackup.toIso8601String());
      expect(json['maxBackupDays'], 20);
      expect(json['backupDirectory'], '/test/backup');
    });
    
    test('should convert to JSON with null lastBackupTime', () {
      final settings = BackupSettings(
        autoBackupEnabled: false,
        backupDirectory: '/test/backup',
      );
      
      final json = settings.toJson();
      
      expect(json['autoBackupEnabled'], false);
      expect(json['lastBackupTime'], null);
      expect(json['maxBackupDays'], 31);
      expect(json['backupDirectory'], '/test/backup');
    });
    
    test('should create from JSON correctly', () {
      final lastBackup = DateTime(2024, 1, 15, 10, 30);
      final json = {
        'autoBackupEnabled': true,
        'lastBackupTime': lastBackup.toIso8601String(),
        'maxBackupDays': 25,
        'backupDirectory': '/json/backup',
      };
      
      final settings = BackupSettings.fromJson(json);
      
      expect(settings.autoBackupEnabled, true);
      expect(settings.lastBackupTime, lastBackup);
      expect(settings.maxBackupDays, 25);
      expect(settings.backupDirectory, '/json/backup');
    });
    
    test('should create from JSON with null lastBackupTime', () {
      final json = {
        'autoBackupEnabled': false,
        'lastBackupTime': null,
        'maxBackupDays': 31,
        'backupDirectory': '/json/backup',
      };
      
      final settings = BackupSettings.fromJson(json);
      
      expect(settings.autoBackupEnabled, false);
      expect(settings.lastBackupTime, null);
      expect(settings.maxBackupDays, 31);
      expect(settings.backupDirectory, '/json/backup');
    });
    
    test('should create from JSON with missing maxBackupDays (use default)', () {
      final json = {
        'autoBackupEnabled': true,
        'backupDirectory': '/json/backup',
      };
      
      final settings = BackupSettings.fromJson(json);
      
      expect(settings.autoBackupEnabled, true);
      expect(settings.maxBackupDays, 31); // default value
      expect(settings.backupDirectory, '/json/backup');
    });
    
    test('should create copy with updated values', () {
      final original = BackupSettings(
        autoBackupEnabled: false,
        maxBackupDays: 10,
        backupDirectory: '/original',
      );
      
      final updated = original.copyWith(
        autoBackupEnabled: true,
        maxBackupDays: 20,
      );
      
      expect(updated.autoBackupEnabled, true);
      expect(updated.maxBackupDays, 20);
      expect(updated.backupDirectory, '/original'); // unchanged
      expect(updated.lastBackupTime, null); // unchanged
    });
    
    test('should handle equality correctly', () {
      final settings1 = BackupSettings(
        autoBackupEnabled: true,
        maxBackupDays: 15,
        backupDirectory: '/test',
      );
      
      final settings2 = BackupSettings(
        autoBackupEnabled: true,
        maxBackupDays: 15,
        backupDirectory: '/test',
      );
      
      final settings3 = BackupSettings(
        autoBackupEnabled: false,
        maxBackupDays: 15,
        backupDirectory: '/test',
      );
      
      expect(settings1, equals(settings2));
      expect(settings1, isNot(equals(settings3)));
      expect(settings1.hashCode, equals(settings2.hashCode));
    });
    
    test('should have meaningful toString', () {
      final settings = BackupSettings(
        autoBackupEnabled: true,
        maxBackupDays: 15,
        backupDirectory: '/test',
      );
      
      final string = settings.toString();
      
      expect(string, contains('BackupSettings'));
      expect(string, contains('autoBackupEnabled: true'));
      expect(string, contains('maxBackupDays: 15'));
      expect(string, contains('backupDirectory: /test'));
    });
  });
}
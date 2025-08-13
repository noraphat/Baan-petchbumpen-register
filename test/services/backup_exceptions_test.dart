import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/backup_exceptions.dart';

void main() {
  group('BackupException', () {
    test('should create with message only', () {
      const exception = BackupException('Test error message');
      
      expect(exception.message, 'Test error message');
      expect(exception.code, null);
      expect(exception.originalError, null);
    });
    
    test('should create with message and code', () {
      const exception = BackupException(
        'Test error message',
        code: 'TEST_ERROR',
      );
      
      expect(exception.message, 'Test error message');
      expect(exception.code, 'TEST_ERROR');
      expect(exception.originalError, null);
    });
    
    test('should create with all parameters', () {
      final originalError = Exception('Original error');
      final exception = BackupException(
        'Test error message',
        code: 'TEST_ERROR',
        originalError: originalError,
      );
      
      expect(exception.message, 'Test error message');
      expect(exception.code, 'TEST_ERROR');
      expect(exception.originalError, originalError);
    });
    
    test('should have correct toString without code', () {
      const exception = BackupException('Test error message');
      
      expect(exception.toString(), 'BackupException: Test error message');
    });
    
    test('should have correct toString with code', () {
      const exception = BackupException(
        'Test error message',
        code: 'TEST_ERROR',
      );
      
      expect(exception.toString(), 'BackupException(TEST_ERROR): Test error message');
    });
  });
  
  group('RestoreException', () {
    test('should create with message only', () {
      const exception = RestoreException('Restore failed');
      
      expect(exception.message, 'Restore failed');
      expect(exception.code, null);
      expect(exception.originalError, null);
    });
    
    test('should create with all parameters', () {
      final originalError = Exception('Database error');
      final exception = RestoreException(
        'Restore failed',
        code: 'RESTORE_ERROR',
        originalError: originalError,
      );
      
      expect(exception.message, 'Restore failed');
      expect(exception.code, 'RESTORE_ERROR');
      expect(exception.originalError, originalError);
    });
    
    test('should have correct toString without code', () {
      const exception = RestoreException('Restore failed');
      
      expect(exception.toString(), 'RestoreException: Restore failed');
    });
    
    test('should have correct toString with code', () {
      const exception = RestoreException(
        'Restore failed',
        code: 'RESTORE_ERROR',
      );
      
      expect(exception.toString(), 'RestoreException(RESTORE_ERROR): Restore failed');
    });
    
    test('should be instance of BackupException', () {
      const exception = RestoreException('Restore failed');
      
      expect(exception, isA<BackupException>());
    });
  });
  
  group('FilePermissionException', () {
    test('should create with message and default code', () {
      const exception = FilePermissionException('Permission denied');
      
      expect(exception.message, 'Permission denied');
      expect(exception.code, 'PERMISSION_DENIED');
    });
    
    test('should have correct toString', () {
      const exception = FilePermissionException('Permission denied');
      
      expect(exception.toString(), 'FilePermissionException: Permission denied');
    });
    
    test('should be instance of BackupException', () {
      const exception = FilePermissionException('Permission denied');
      
      expect(exception, isA<BackupException>());
    });
  });
  
  group('InvalidBackupFileException', () {
    test('should create with message and default code', () {
      const exception = InvalidBackupFileException('Invalid backup file');
      
      expect(exception.message, 'Invalid backup file');
      expect(exception.code, 'INVALID_BACKUP_FILE');
    });
    
    test('should have correct toString', () {
      const exception = InvalidBackupFileException('Invalid backup file');
      
      expect(exception.toString(), 'InvalidBackupFileException: Invalid backup file');
    });
    
    test('should be instance of BackupException', () {
      const exception = InvalidBackupFileException('Invalid backup file');
      
      expect(exception, isA<BackupException>());
    });
  });
  
  group('StorageException', () {
    test('should create with message and default code', () {
      const exception = StorageException('Storage full');
      
      expect(exception.message, 'Storage full');
      expect(exception.code, 'STORAGE_ERROR');
    });
    
    test('should have correct toString', () {
      const exception = StorageException('Storage full');
      
      expect(exception.toString(), 'StorageException: Storage full');
    });
    
    test('should be instance of BackupException', () {
      const exception = StorageException('Storage full');
      
      expect(exception, isA<BackupException>());
    });
  });
  
  group('DatabaseBackupException', () {
    test('should create with message only', () {
      const exception = DatabaseBackupException('Database error');
      
      expect(exception.message, 'Database error');
      expect(exception.code, 'DATABASE_ERROR');
      expect(exception.originalError, null);
    });
    
    test('should create with original error', () {
      final originalError = Exception('SQL error');
      final exception = DatabaseBackupException(
        'Database error',
        originalError: originalError,
      );
      
      expect(exception.message, 'Database error');
      expect(exception.code, 'DATABASE_ERROR');
      expect(exception.originalError, originalError);
    });
    
    test('should have correct toString', () {
      const exception = DatabaseBackupException('Database error');
      
      expect(exception.toString(), 'DatabaseBackupException: Database error');
    });
    
    test('should be instance of BackupException', () {
      const exception = DatabaseBackupException('Database error');
      
      expect(exception, isA<BackupException>());
    });
  });
}
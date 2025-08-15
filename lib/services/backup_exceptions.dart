/// Base exception class for backup operations
class BackupException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const BackupException(
    this.message, {
    this.code,
    this.originalError,
  });
  
  @override
  String toString() {
    if (code != null) {
      return 'BackupException($code): $message';
    }
    return 'BackupException: $message';
  }
}

/// Exception for restore operations
class RestoreException extends BackupException {
  const RestoreException(
    String message, {
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);
  
  @override
  String toString() {
    if (code != null) {
      return 'RestoreException($code): $message';
    }
    return 'RestoreException: $message';
  }
}

/// Exception for file permission issues
class FilePermissionException extends BackupException {
  const FilePermissionException(String message)
      : super(message, code: 'PERMISSION_DENIED');
  
  @override
  String toString() {
    return 'FilePermissionException: $message';
  }
}

/// Exception for invalid backup files
class InvalidBackupFileException extends BackupException {
  const InvalidBackupFileException(String message)
      : super(message, code: 'INVALID_BACKUP_FILE');
  
  @override
  String toString() {
    return 'InvalidBackupFileException: $message';
  }
}

/// Exception for storage space issues
class StorageException extends BackupException {
  const StorageException(String message)
      : super(message, code: 'STORAGE_ERROR');
  
  @override
  String toString() {
    return 'StorageException: $message';
  }
}

/// Exception for database operations during backup/restore
class DatabaseBackupException extends BackupException {
  const DatabaseBackupException(
    String message, {
    dynamic originalError,
  }) : super(message, code: 'DATABASE_ERROR', originalError: originalError);
  
  @override
  String toString() {
    return 'DatabaseBackupException: $message';
  }
}

/// Exception for security violations during backup operations
class SecurityException extends BackupException {
  const SecurityException(String message)
      : super(message, code: 'SECURITY_VIOLATION');
  
  @override
  String toString() {
    return 'SecurityException: $message';
  }
}

/// Exception for file path validation failures
class InvalidFilePathException extends SecurityException {
  const InvalidFilePathException(String message)
      : super('Invalid file path: $message');
  
  @override
  String toString() {
    return 'InvalidFilePathException: $message';
  }
}

/// Exception for SQL content validation failures
class UnsafeSqlException extends SecurityException {
  const UnsafeSqlException(String message)
      : super('Unsafe SQL content detected: $message');
  
  @override
  String toString() {
    return 'UnsafeSqlException: $message';
  }
}
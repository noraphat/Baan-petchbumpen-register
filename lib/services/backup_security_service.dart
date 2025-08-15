import 'dart:io';
import 'backup_exceptions.dart';

/// Service for handling security validation and checks for backup operations
class BackupSecurityService {
  static const List<String> _allowedFileExtensions = ['.sql', '.json'];
  static const int _maxFileSize = 100 * 1024 * 1024; // 100MB
  static const int _maxFilenameLength = 255;

  /// Validate file path for security issues
  Future<bool> validateFilePath(String filePath) async {
    try {
      // Check for null or empty path
      if (filePath.isEmpty) {
        throw InvalidFilePathException('File path cannot be empty');
      }

      // Check filename length
      final fileName = filePath.split('/').last;
      if (fileName.length > _maxFilenameLength) {
        throw InvalidFilePathException('Filename too long: ${fileName.length} characters');
      }

      // Check for directory traversal attempts
      if (_containsDirectoryTraversal(filePath)) {
        throw InvalidFilePathException('Directory traversal detected in path');
      }

      // Check for null bytes
      if (filePath.contains('\x00')) {
        throw InvalidFilePathException('Null byte detected in path');
      }

      // Check file extension
      if (!_hasAllowedExtension(filePath)) {
        throw InvalidFilePathException('File extension not allowed');
      }

      // Check for suspicious characters
      if (_containsSuspiciousCharacters(filePath)) {
        throw InvalidFilePathException('Suspicious characters detected in path');
      }

      return true;
    } on SecurityException {
      rethrow;
    } catch (e) {
      throw SecurityException('File path validation failed: ${e.toString()}');
    }
  }

  /// Validate SQL content for security issues
  Future<bool> validateSqlContent(String sqlContent) async {
    try {
      // Check for empty content
      if (sqlContent.trim().isEmpty) {
        throw UnsafeSqlException('SQL content cannot be empty');
      }

      // Check for dangerous SQL patterns
      if (_containsDangerousSql(sqlContent)) {
        throw UnsafeSqlException('Dangerous SQL statements detected');
      }

      // Check for SQL injection patterns
      if (_containsSqlInjectionPatterns(sqlContent)) {
        throw UnsafeSqlException('Potential SQL injection patterns detected');
      }

      // Check for excessive size
      if (sqlContent.length > _maxFileSize) {
        throw UnsafeSqlException('SQL content exceeds maximum size limit');
      }

      // Validate SQL structure
      if (!_hasValidSqlStructure(sqlContent)) {
        throw UnsafeSqlException('Invalid SQL structure detected');
      }

      return true;
    } on SecurityException {
      rethrow;
    } catch (e) {
      throw SecurityException('SQL content validation failed: ${e.toString()}');
    }
  }

  /// Validate backup file integrity and security
  Future<bool> validateBackupFile(String filePath) async {
    try {
      final file = File(filePath);

      // Check if file exists
      if (!await file.exists()) {
        throw InvalidBackupFileException('Backup file does not exist');
      }

      // Validate file path
      await validateFilePath(filePath);

      // Check file size
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw InvalidBackupFileException('Backup file is empty');
      }

      if (fileSize > _maxFileSize) {
        throw InvalidBackupFileException('Backup file exceeds maximum size limit');
      }

      // Read and validate content based on file type
      if (filePath.toLowerCase().endsWith('.sql')) {
        final content = await file.readAsString();
        await validateSqlContent(content);
      } else if (filePath.toLowerCase().endsWith('.json')) {
        await _validateJsonContent(filePath);
      }

      return true;
    } on SecurityException {
      rethrow;
    } on InvalidBackupFileException {
      rethrow;
    } catch (e) {
      throw SecurityException('Backup file validation failed: ${e.toString()}');
    }
  }

  /// Sanitize file path to prevent security issues
  String sanitizeFilePath(String filePath) {
    // Remove directory traversal attempts
    String sanitized = filePath.replaceAll(RegExp(r'\.\.[\\/]'), '');
    
    // Remove null bytes
    sanitized = sanitized.replaceAll('\x00', '');
    
    // Remove suspicious characters
    sanitized = sanitized.replaceAll(RegExp(r'[<>:"|?*]'), '_');
    
    // Limit filename length
    final parts = sanitized.split('/');
    if (parts.isNotEmpty) {
      final fileName = parts.last;
      if (fileName.length > _maxFilenameLength) {
        final extension = fileName.contains('.') ? fileName.substring(fileName.lastIndexOf('.')) : '';
        final baseName = fileName.substring(0, fileName.lastIndexOf('.'));
        final maxBaseLength = _maxFilenameLength - extension.length;
        parts[parts.length - 1] = baseName.substring(0, maxBaseLength) + extension;
        sanitized = parts.join('/');
      }
    }
    
    return sanitized;
  }

  /// Check if file path contains directory traversal attempts
  bool _containsDirectoryTraversal(String path) {
    final dangerousPatterns = [
      '../',
      '..\\',
      '/..',
      '\\..',
      '%2e%2e%2f',
      '%2e%2e%5c',
      '..%2f',
      '..%5c',
    ];

    final lowerPath = path.toLowerCase();
    return dangerousPatterns.any((pattern) => lowerPath.contains(pattern));
  }

  /// Check if file has allowed extension
  bool _hasAllowedExtension(String filePath) {
    final lowerPath = filePath.toLowerCase();
    return _allowedFileExtensions.any((ext) => lowerPath.endsWith(ext));
  }

  /// Check for suspicious characters in file path
  bool _containsSuspiciousCharacters(String path) {
    // Check for control characters and other suspicious patterns
    final suspiciousPatterns = [
      RegExp(r'[\x00-\x1f\x7f]'), // Control characters
      RegExp(r'[<>:"|?*]'), // Windows reserved characters
      RegExp(r'^\s+|\s+$'), // Leading/trailing whitespace
      RegExp(r'\s{2,}'), // Multiple consecutive spaces
    ];

    return suspiciousPatterns.any((pattern) => pattern.hasMatch(path));
  }

  /// Check if SQL content contains dangerous statements
  bool _containsDangerousSql(String sql) {
    final dangerousPatterns = [
      // Database manipulation
      RegExp(r'\bDROP\s+DATABASE\b', caseSensitive: false),
      RegExp(r'\bCREATE\s+DATABASE\b', caseSensitive: false),
      RegExp(r'\bALTER\s+DATABASE\b', caseSensitive: false),
      
      // System table manipulation
      RegExp(r'\bDELETE\s+FROM\s+sqlite_master\b', caseSensitive: false),
      RegExp(r'\bUPDATE\s+sqlite_master\b', caseSensitive: false),
      RegExp(r'\bINSERT\s+INTO\s+sqlite_master\b', caseSensitive: false),
      
      // Pragma statements that could be dangerous
      RegExp(r'\bPRAGMA\s+writable_schema\b', caseSensitive: false),
      RegExp(r'\bPRAGMA\s+journal_mode\s*=\s*OFF\b', caseSensitive: false),
      
      // Database attachment
      RegExp(r'\bATTACH\s+DATABASE\b', caseSensitive: false),
      RegExp(r'\bDETACH\s+DATABASE\b', caseSensitive: false),
      
      // File operations
      RegExp(r'\bLOAD_EXTENSION\b', caseSensitive: false),
      
      // Vacuum with specific database
      RegExp(r'\bVACUUM\s+\w+\b', caseSensitive: false),
      
      // Backup/restore commands
      RegExp(r'\b\.backup\b', caseSensitive: false),
      RegExp(r'\b\.restore\b', caseSensitive: false),
    ];

    return dangerousPatterns.any((pattern) => pattern.hasMatch(sql));
  }

  /// Check for SQL injection patterns
  bool _containsSqlInjectionPatterns(String sql) {
    final injectionPatterns = [
      // Union-based injection
      RegExp(r'\bUNION\s+SELECT\b.*\bFROM\s+sqlite_master\b', caseSensitive: false),
      
      // Comment-based injection
      RegExp(r'--\s*[^\r\n]*(?:DROP|DELETE|UPDATE|INSERT)', caseSensitive: false),
      RegExp(r'/\*.*?(?:DROP|DELETE|UPDATE|INSERT).*?\*/', caseSensitive: false),
      
      // Stacked queries with dangerous operations
      RegExp(r';\s*(?:DROP|DELETE\s+FROM\s+(?!.*WHERE)|UPDATE\s+(?!.*WHERE))', caseSensitive: false),
      
      // Hex-encoded strings that might hide malicious content
      RegExp(r'0x[0-9a-fA-F]+', caseSensitive: false),
      
      // Excessive nested queries
      RegExp(r'(\bSELECT\b.*?){5,}', caseSensitive: false),
    ];

    return injectionPatterns.any((pattern) => pattern.hasMatch(sql));
  }

  /// Check if SQL has valid structure for backup
  bool _hasValidSqlStructure(String sql) {
    // Must contain CREATE TABLE statements
    if (!RegExp(r'\bCREATE\s+TABLE\b', caseSensitive: false).hasMatch(sql)) {
      return false;
    }

    // Should not contain only DROP statements
    final dropCount = RegExp(r'\bDROP\s+TABLE\b', caseSensitive: false).allMatches(sql).length;
    final createCount = RegExp(r'\bCREATE\s+TABLE\b', caseSensitive: false).allMatches(sql).length;
    
    if (dropCount > 0 && createCount == 0) {
      return false; // Only DROP statements without CREATE
    }

    // Check for balanced parentheses in CREATE TABLE statements
    final createTableMatches = RegExp(r'CREATE\s+TABLE[^;]+;', caseSensitive: false).allMatches(sql);
    for (final match in createTableMatches) {
      final statement = match.group(0) ?? '';
      if (!_hasBalancedParentheses(statement)) {
        return false;
      }
    }

    return true;
  }

  /// Check if parentheses are balanced in SQL statement
  bool _hasBalancedParentheses(String sql) {
    int count = 0;
    for (int i = 0; i < sql.length; i++) {
      if (sql[i] == '(') {
        count++;
      } else if (sql[i] == ')') {
        count--;
        if (count < 0) return false;
      }
    }
    return count == 0;
  }

  /// Validate JSON content
  Future<bool> _validateJsonContent(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      
      // Basic JSON structure validation would go here
      // For now, just check it's not empty and has basic JSON structure
      if (!content.trim().startsWith('{') || !content.trim().endsWith('}')) {
        throw InvalidBackupFileException('Invalid JSON structure');
      }

      return true;
    } catch (e) {
      throw InvalidBackupFileException('JSON validation failed: ${e.toString()}');
    }
  }
}
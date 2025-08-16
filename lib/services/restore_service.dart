import 'dart:io';
import 'backup_exceptions.dart';
import 'db_helper.dart';
import 'file_management_service.dart';
import 'backup_security_service.dart';

/// Service for restoring data from backup files
class RestoreService {
  final FileManagementService _fileService;
  final DbHelper _dbHelper;
  final BackupSecurityService _securityService;
  
  RestoreService({
    FileManagementService? fileService,
    DbHelper? dbHelper,
    BackupSecurityService? securityService,
  }) : _fileService = fileService ?? FileManagementService(),
        _dbHelper = dbHelper ?? DbHelper(),
        _securityService = securityService ?? BackupSecurityService();

  /// Restore data from SQL backup file
  Future<void> restoreFromSqlFile(String filePath) async {
    String? emergencyBackupPath;
    
    try {
      // 1. Validate file path for security
      await _securityService.validateFilePath(filePath);
      
      // 2. Validate backup file
      if (!await validateBackupFile(filePath)) {
        throw InvalidBackupFileException('Invalid backup file format or content');
      }

      // 3. Create emergency backup before restore
      emergencyBackupPath = await createEmergencyBackup();

      try {
        // 4. Drop all existing tables
        await dropAllTables();

        // 5. Execute SQL file to restore data
        await executeSqlFile(filePath);

        // 6. Verify data integrity after restore
        if (!await verifyRestoreIntegrity()) {
          throw RestoreException('Data integrity verification failed after restore');
        }

        // 7. Clean up old emergency backups on successful restore
        await _cleanupOldEmergencyBackups();

      } catch (e) {
        // If restore fails, attempt to restore from emergency backup
        try {
          await _restoreFromEmergencyBackup();
        } catch (emergencyError) {
          throw RestoreException(
            'Restore failed and emergency backup restoration also failed',
            code: 'EMERGENCY_RESTORE_FAILED',
            originalError: emergencyError,
          );
        }
        rethrow;
      }

    } on SecurityException {
      rethrow;
    } on RestoreException {
      rethrow;
    } on InvalidBackupFileException {
      rethrow;
    } catch (e) {
      throw RestoreException(
        'Failed to restore from SQL file: ${e.toString()}',
        code: 'RESTORE_FAILED',
        originalError: e,
      );
    }
  }

  /// Create emergency backup of current database state
  Future<String> createEmergencyBackup() async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final emergencyFileName = 'emergency_backup_$timestamp.sql';
      
      // Get current database content as SQL
      final sqlContent = await _exportCurrentDatabaseToSql();
      
      // Save emergency backup
      final filePath = await _fileService.createBackupFile(emergencyFileName, sqlContent);
      
      // Store the emergency backup path for potential rollback
      _lastEmergencyBackupPath = filePath;
      
      return filePath;
      
    } catch (e) {
      throw RestoreException(
        'Failed to create emergency backup: ${e.toString()}',
        code: 'EMERGENCY_BACKUP_FAILED',
        originalError: e,
      );
    }
  }

  // Store the path of the last emergency backup for rollback
  String? _lastEmergencyBackupPath;

  /// Validate backup file format and content
  Future<bool> validateBackupFile(String filePath) async {
    try {
      // Use security service for comprehensive validation
      return await _securityService.validateBackupFile(filePath);
    } on SecurityException catch (e) {
      // Log security violation but return false instead of throwing
      // This allows the calling code to handle validation failure gracefully
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Drop all existing tables in the database
  Future<void> dropAllTables() async {
    try {
      final database = await _dbHelper.db;
      
      // Get list of all tables (excluding system tables)
      final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      
      // Drop each table
      for (final table in tables) {
        final tableName = table['name'] as String;
        await database.execute('DROP TABLE IF EXISTS $tableName');
      }
      
    } catch (e) {
      throw DatabaseBackupException(
        'Failed to drop tables: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Execute SQL file to restore database structure and data
  Future<void> executeSqlFile(String filePath) async {
    try {
      final file = File(filePath);
      final sqlContent = await file.readAsString();
      
      // Validate SQL content for security before execution
      await _securityService.validateSqlContent(sqlContent);
      
      final database = await _dbHelper.db;
      
      // Split SQL content into individual statements
      final statements = _splitSqlStatements(sqlContent);
      
      // Execute each statement in a transaction
      await database.transaction((txn) async {
        for (final statement in statements) {
          final trimmedStatement = statement.trim();
          if (trimmedStatement.isNotEmpty && !trimmedStatement.startsWith('--')) {
            // Additional security check for each statement
            if (_isStatementSafe(trimmedStatement)) {
              await txn.execute(trimmedStatement);
            } else {
              throw UnsafeSqlException('Unsafe SQL statement detected: ${trimmedStatement.substring(0, 50)}...');
            }
          }
        }
      });
      
    } on SecurityException {
      rethrow;
    } catch (e) {
      throw DatabaseBackupException(
        'Failed to execute SQL file: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Verify data integrity after restore
  Future<bool> verifyRestoreIntegrity() async {
    try {
      final database = await _dbHelper.db;
      
      // Check if essential tables exist
      final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      
      if (tables.isEmpty) {
        return false;
      }

      // Check if main tables exist
      final tableNames = tables.map((t) => t['name'] as String).toList();
      final requiredTables = ['regs', 'stays', 'reg_additional_info', 'app_settings'];
      
      for (final requiredTable in requiredTables) {
        if (!tableNames.contains(requiredTable)) {
          return false;
        }
      }

      // Verify table structures by attempting to query them
      for (final tableName in requiredTables) {
        try {
          await database.rawQuery('SELECT COUNT(*) FROM $tableName LIMIT 1');
        } catch (e) {
          return false;
        }
      }

      // Check for indexes
      final indexes = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'"
      );
      
      // Should have at least some indexes
      if (indexes.isEmpty) {
        return false;
      }

      return true;
      
    } catch (e) {
      return false;
    }
  }

  /// Export current database to SQL format for emergency backup
  Future<String> _exportCurrentDatabaseToSql() async {
    try {
      final database = await _dbHelper.db;
      final buffer = StringBuffer();
      
      // Add header comment
      buffer.writeln('-- Emergency backup created on ${DateTime.now().toIso8601String()}');
      buffer.writeln('-- This backup was created before restore operation');
      buffer.writeln();
      
      // Get all tables
      final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      
      for (final table in tables) {
        final tableName = table['name'] as String;
        
        // Get table schema
        final schema = await database.rawQuery(
          "SELECT sql FROM sqlite_master WHERE type='table' AND name=?",
          [tableName]
        );
        
        if (schema.isNotEmpty) {
          buffer.writeln('-- Table: $tableName');
          buffer.writeln('DROP TABLE IF EXISTS $tableName;');
          buffer.writeln('${schema.first['sql']};');
          buffer.writeln();
          
          // Get table data
          final data = await database.query(tableName);
          if (data.isNotEmpty) {
            for (final row in data) {
              final columns = row.keys.join(', ');
              final values = row.values.map((v) => v == null ? 'NULL' : "'${v.toString().replaceAll("'", "''")}'").join(', ');
              buffer.writeln('INSERT INTO $tableName ($columns) VALUES ($values);');
            }
            buffer.writeln();
          }
        }
      }
      
      // Get indexes
      final indexes = await database.rawQuery(
        "SELECT sql FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%' AND sql IS NOT NULL"
      );
      
      if (indexes.isNotEmpty) {
        buffer.writeln('-- Indexes');
        for (final index in indexes) {
          buffer.writeln('${index['sql']};');
        }
      }
      
      return buffer.toString();
      
    } catch (e) {
      throw DatabaseBackupException(
        'Failed to export current database: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Restore from emergency backup
  Future<void> _restoreFromEmergencyBackup() async {
    try {
      String? emergencyBackupPath;
      
      // Use the last created emergency backup if available
      if (_lastEmergencyBackupPath != null && await File(_lastEmergencyBackupPath!).exists()) {
        emergencyBackupPath = _lastEmergencyBackupPath;
      } else {
        // Find the most recent emergency backup
        final backupFiles = await _fileService.getBackupFiles();
        final emergencyBackups = backupFiles
            .where((file) => file.contains('emergency_backup_'))
            .toList();
        
        if (emergencyBackups.isEmpty) {
          throw RestoreException('No emergency backup found');
        }
        
        // Sort by filename (which contains timestamp) and get the most recent
        emergencyBackups.sort((a, b) => b.compareTo(a));
        emergencyBackupPath = emergencyBackups.first;
      }
      
      // Restore from emergency backup without creating another emergency backup
      await dropAllTables();
      
      // Read and execute emergency backup directly without security validation
      // since it's our own generated backup
      final file = File(emergencyBackupPath!);
      final sqlContent = await file.readAsString();
      
      // Use the existing executeSqlFile method but bypass security checks
      // by temporarily setting a flag or using a different approach
      await _executeSqlContentDirectly(sqlContent);
      
    } catch (e) {
      throw RestoreException(
        'Failed to restore from emergency backup: ${e.toString()}',
        code: 'EMERGENCY_RESTORE_FAILED',
        originalError: e,
      );
    }
  }

  /// Clean up old emergency backups (keep only the last 5)
  Future<void> _cleanupOldEmergencyBackups() async {
    try {
      final backupFiles = await _fileService.getBackupFiles();
      final emergencyBackups = backupFiles
          .where((file) => file.contains('emergency_backup_'))
          .toList();
      
      // Sort by filename (timestamp) - newest first
      emergencyBackups.sort((a, b) => b.compareTo(a));
      
      // Keep only the 5 most recent emergency backups
      const maxEmergencyBackups = 5;
      if (emergencyBackups.length > maxEmergencyBackups) {
        final backupsToDelete = emergencyBackups.skip(maxEmergencyBackups);
        
        for (final backupPath in backupsToDelete) {
          try {
            final fileName = backupPath.split('/').last;
            await _fileService.deleteBackupFile(fileName);
          } catch (e) {
            // Log but don't fail cleanup for individual file deletion errors
            continue;
          }
        }
      }
    } catch (e) {
      // Don't throw on cleanup failure - it's not critical
    }
  }

  /// Get the path of the last emergency backup created
  String? getLastEmergencyBackupPath() {
    return _lastEmergencyBackupPath;
  }

  /// Manually trigger rollback to the last emergency backup
  Future<void> rollbackToEmergencyBackup() async {
    if (_lastEmergencyBackupPath == null) {
      throw RestoreException('No emergency backup available for rollback');
    }
    
    try {
      await _restoreFromEmergencyBackup();
    } catch (e) {
      throw RestoreException(
        'Failed to rollback to emergency backup: ${e.toString()}',
        code: 'ROLLBACK_FAILED',
        originalError: e,
      );
    }
  }

  /// Check if individual SQL statement is safe to execute
  bool _isStatementSafe(String statement) {
    final upperStatement = statement.toUpperCase().trim();
    
    // Allow only specific safe statements for restore operations
    final allowedStatements = [
      'CREATE TABLE',
      'CREATE INDEX',
      'INSERT INTO',
      'DROP TABLE IF EXISTS',
      'DROP INDEX IF EXISTS',
    ];
    
    // Check if statement starts with any allowed pattern
    for (final allowed in allowedStatements) {
      if (upperStatement.startsWith(allowed)) {
        return true;
      }
    }
    
    // Allow comments
    if (upperStatement.startsWith('--')) {
      return true;
    }
    
    return false;
  }

  /// Split SQL content into individual statements
  List<String> _splitSqlStatements(String sql) {
    // Simple SQL statement splitter
    // This is a basic implementation - in production you might want a more robust parser
    final statements = <String>[];
    final lines = sql.split('\n');
    final buffer = StringBuffer();
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      // Skip comments and empty lines
      if (trimmedLine.isEmpty || trimmedLine.startsWith('--')) {
        continue;
      }
      
      buffer.writeln(line);
      
      // If line ends with semicolon, it's the end of a statement
      if (trimmedLine.endsWith(';')) {
        final statement = buffer.toString().trim();
        if (statement.isNotEmpty) {
          statements.add(statement);
        }
        buffer.clear();
      }
    }
    
    // Add any remaining content as a statement
    final remaining = buffer.toString().trim();
    if (remaining.isNotEmpty) {
      statements.add(remaining);
    }
    
    return statements;
  }

  /// Execute SQL content directly without security validation (for emergency backups)
  Future<void> _executeSqlContentDirectly(String sqlContent) async {
    try {
      final database = await _dbHelper.db;
      final statements = _splitSqlStatements(sqlContent);
      
      await database.transaction((txn) async {
        for (final statement in statements) {
          final trimmedStatement = statement.trim();
          if (trimmedStatement.isNotEmpty && !trimmedStatement.startsWith('--')) {
            await txn.execute(trimmedStatement);
          }
        }
      });
    } catch (e) {
      throw DatabaseBackupException(
        'Failed to execute SQL content: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
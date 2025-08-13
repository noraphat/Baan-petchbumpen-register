import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'backup_exceptions.dart';
import 'db_helper.dart';
import 'file_management_service.dart';

/// Service for restoring data from backup files
class RestoreService {
  final FileManagementService _fileService;
  final DbHelper _dbHelper;
  
  RestoreService({
    FileManagementService? fileService,
    DbHelper? dbHelper,
  }) : _fileService = fileService ?? FileManagementService(),
        _dbHelper = dbHelper ?? DbHelper();

  /// Restore data from SQL backup file
  Future<void> restoreFromSqlFile(String filePath) async {
    try {
      // 1. Validate backup file
      if (!await validateBackupFile(filePath)) {
        throw InvalidBackupFileException('Invalid backup file format or content');
      }

      // 2. Create emergency backup before restore
      await createEmergencyBackup();

      try {
        // 3. Drop all existing tables
        await dropAllTables();

        // 4. Execute SQL file to restore data
        await executeSqlFile(filePath);

        // 5. Verify data integrity after restore
        if (!await verifyRestoreIntegrity()) {
          throw RestoreException('Data integrity verification failed after restore');
        }

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
  Future<void> createEmergencyBackup() async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final emergencyFileName = 'emergency_backup_$timestamp.sql';
      
      // Get current database content as SQL
      final sqlContent = await _exportCurrentDatabaseToSql();
      
      // Save emergency backup
      await _fileService.createBackupFile(emergencyFileName, sqlContent);
      
    } catch (e) {
      throw RestoreException(
        'Failed to create emergency backup: ${e.toString()}',
        code: 'EMERGENCY_BACKUP_FAILED',
        originalError: e,
      );
    }
  }

  /// Validate backup file format and content
  Future<bool> validateBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      
      // Check if file exists
      if (!await file.exists()) {
        return false;
      }

      // Check file extension
      if (!filePath.toLowerCase().endsWith('.sql')) {
        return false;
      }

      // Read and validate SQL content
      final content = await file.readAsString();
      
      // Basic validation checks
      if (content.trim().isEmpty) {
        return false;
      }

      // Check for required SQL statements
      final hasCreateTable = content.contains('CREATE TABLE');
      final hasInsertData = content.contains('INSERT INTO');
      
      // A valid backup should have at least CREATE TABLE statements
      if (!hasCreateTable) {
        return false;
      }

      // Check for potentially dangerous SQL
      if (_containsDangerousSql(content)) {
        return false;
      }

      return true;
      
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
      
      final database = await _dbHelper.db;
      
      // Split SQL content into individual statements
      final statements = _splitSqlStatements(sqlContent);
      
      // Execute each statement in a transaction
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
      final latestEmergencyBackup = emergencyBackups.first;
      
      // Restore from emergency backup
      await dropAllTables();
      await executeSqlFile(latestEmergencyBackup);
      
    } catch (e) {
      throw RestoreException(
        'Failed to restore from emergency backup: ${e.toString()}',
        code: 'EMERGENCY_RESTORE_FAILED',
        originalError: e,
      );
    }
  }

  /// Check if SQL content contains potentially dangerous statements
  bool _containsDangerousSql(String sql) {
    final dangerousPatterns = [
      RegExp(r'\bDROP\s+DATABASE\b', caseSensitive: false),
      RegExp(r'\bDELETE\s+FROM\s+sqlite_master\b', caseSensitive: false),
      RegExp(r'\bUPDATE\s+sqlite_master\b', caseSensitive: false),
      RegExp(r'\bPRAGMA\s+writable_schema\b', caseSensitive: false),
      RegExp(r'\bATTACH\s+DATABASE\b', caseSensitive: false),
      RegExp(r'\bDETACH\s+DATABASE\b', caseSensitive: false),
    ];
    
    for (final pattern in dangerousPatterns) {
      if (pattern.hasMatch(sql)) {
        return true;
      }
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
}
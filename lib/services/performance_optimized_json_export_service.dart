import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';
import 'backup_exceptions.dart';

/// Performance-optimized JSON export service for large datasets
/// Implements streaming and batch processing for efficient memory usage
class PerformanceOptimizedJsonExportService {
  final DbHelper _dbHelper = DbHelper();
  
  // Performance configuration
  static const int _batchSize = 1000;
  static const int _streamBufferSize = 8192;
  
  /// Export all tables to JSON with streaming for large datasets
  Future<String> exportAllTablesToJsonStreaming({
    Function(double)? onProgress,
    Function(String)? onStatusUpdate,
  }) async {
    try {
      final database = await _dbHelper.db;
      
      // Get total record count for progress tracking
      final totalRecords = await _getTotalRecordCount(database);
      onStatusUpdate?.call('Found $totalRecords total records to export');
      
      // Create output file
      final fileName = generateJsonFileName();
      final directory = await _getBackupDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      
      // Use streaming to write JSON
      final sink = file.openWrite();
      
      try {
        await _writeJsonStreamingFormat(
          database, 
          sink, 
          totalRecords,
          onProgress: onProgress,
          onStatusUpdate: onStatusUpdate,
        );
        
        await sink.flush();
        await sink.close();
        
        onStatusUpdate?.call('Export completed successfully');
        onProgress?.call(1.0);
        
        return filePath;
      } finally {
        await sink.close();
      }
    } catch (e) {
      throw BackupException(
        'Failed to export data to JSON with streaming: ${e.toString()}',
        code: 'JSON_STREAMING_EXPORT_ERROR',
        originalError: e,
      );
    }
  }

  /// Write JSON in streaming format to avoid memory issues
  Future<void> _writeJsonStreamingFormat(
    Database database,
    IOSink sink,
    int totalRecords, {
    Function(double)? onProgress,
    Function(String)? onStatusUpdate,
  }) async {
    int processedRecords = 0;
    
    // Write JSON header
    sink.write('{\n');
    sink.write('  "export_info": {\n');
    sink.write('    "timestamp": "${DateTime.now().toIso8601String()}",\n');
    sink.write('    "version": "1.0",\n');
    sink.write('    "database_version": ${await _getDatabaseVersion(database)},\n');
    sink.write('    "total_records": $totalRecords,\n');
    sink.write('    "export_method": "streaming"\n');
    sink.write('  },\n');
    sink.write('  "tables": {\n');
    
    final tables = ['regs', 'reg_additional_info', 'stays', 'app_settings', 'maps', 'rooms', 'room_bookings'];
    
    for (int i = 0; i < tables.length; i++) {
      final tableName = tables[i];
      onStatusUpdate?.call('Exporting table: $tableName');
      
      sink.write('    "$tableName": [\n');
      
      final tableRecordCount = await _exportTableStreaming(
        database, 
        tableName, 
        sink,
        onProgress: (tableProgress) {
          final overallProgress = (processedRecords + (tableProgress * await _getTableRecordCount(database, tableName))) / totalRecords;
          onProgress?.call(overallProgress);
        },
      );
      
      processedRecords += tableRecordCount;
      
      sink.write('\n    ]');
      if (i < tables.length - 1) {
        sink.write(',');
      }
      sink.write('\n');
      
      // Update progress
      onProgress?.call(processedRecords / totalRecords);
    }
    
    sink.write('  }\n');
    sink.write('}\n');
  }

  /// Export single table with streaming and batching
  Future<int> _exportTableStreaming(
    Database database,
    String tableName,
    IOSink sink, {
    Function(double)? onProgress,
  }) async {
    try {
      // Check if table exists
      final tableExists = await _checkTableExists(database, tableName);
      if (!tableExists) {
        return 0;
      }
      
      // Get total count for this table
      final totalCount = await _getTableRecordCount(database, tableName);
      if (totalCount == 0) {
        return 0;
      }
      
      int processedCount = 0;
      int offset = 0;
      bool isFirstRecord = true;
      
      // Process in batches
      while (offset < totalCount) {
        final batch = await database.query(
          tableName,
          limit: _batchSize,
          offset: offset,
        );
        
        if (batch.isEmpty) break;
        
        // Write batch to stream
        for (final record in batch) {
          if (!isFirstRecord) {
            sink.write(',\n');
          } else {
            isFirstRecord = false;
          }
          
          sink.write('      ');
          sink.write(jsonEncode(record));
          
          processedCount++;
          
          // Flush periodically to avoid memory buildup
          if (processedCount % 100 == 0) {
            await sink.flush();
          }
        }
        
        offset += _batchSize;
        onProgress?.call(processedCount / totalCount);
      }
      
      return processedCount;
    } catch (e) {
      throw BackupException(
        'Failed to export table $tableName with streaming: ${e.toString()}',
        code: 'TABLE_STREAMING_EXPORT_ERROR',
        originalError: e,
      );
    }
  }

  /// Get total record count across all tables
  Future<int> _getTotalRecordCount(Database database) async {
    int total = 0;
    final tables = ['regs', 'reg_additional_info', 'stays', 'app_settings', 'maps', 'rooms', 'room_bookings'];
    
    for (final tableName in tables) {
      total += await _getTableRecordCount(database, tableName);
    }
    
    return total;
  }

  /// Get record count for specific table
  Future<int> _getTableRecordCount(Database database, String tableName) async {
    try {
      final tableExists = await _checkTableExists(database, tableName);
      if (!tableExists) {
        return 0;
      }
      
      final result = await database.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      return result.first['count'] as int;
    } catch (e) {
      return 0;
    }
  }

  /// Check if table exists
  Future<bool> _checkTableExists(Database database, String tableName) async {
    try {
      final result = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get database version
  Future<int> _getDatabaseVersion(Database database) async {
    try {
      final result = await database.rawQuery('PRAGMA user_version');
      return result.first['user_version'] as int;
    } catch (e) {
      return 0;
    }
  }

  /// Generate JSON filename with timestamp
  String generateJsonFileName() {
    final now = DateTime.now();
    final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
    return 'backup_streaming_$timestamp.json';
  }

  /// Get backup directory
  Future<Directory> _getBackupDirectory() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDocDir.path}/backups');
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      return backupDir;
    } catch (e) {
      throw BackupException(
        'Failed to access backup directory: ${e.toString()}',
        code: 'DIRECTORY_ACCESS_ERROR',
        originalError: e,
      );
    }
  }

  /// Optimized batch export for specific table with memory management
  Future<List<Map<String, dynamic>>> exportTableBatched(
    String tableName, {
    int? limit,
    int? offset,
  }) async {
    try {
      final database = await _dbHelper.db;
      
      final tableExists = await _checkTableExists(database, tableName);
      if (!tableExists) {
        return [];
      }
      
      // Use optimized query with proper indexing
      final result = await database.query(
        tableName,
        limit: limit ?? _batchSize,
        offset: offset ?? 0,
        orderBy: _getPrimaryKeyColumn(tableName),
      );
      
      return result;
    } catch (e) {
      throw BackupException(
        'Failed to export table $tableName in batch: ${e.toString()}',
        code: 'BATCH_EXPORT_ERROR',
        originalError: e,
      );
    }
  }

  /// Get primary key column for table (for consistent ordering)
  String _getPrimaryKeyColumn(String tableName) {
    switch (tableName) {
      case 'regs':
        return 'id';
      case 'stays':
      case 'reg_additional_info':
      case 'maps':
      case 'rooms':
      case 'room_bookings':
        return 'id';
      case 'app_settings':
        return 'key';
      default:
        return 'rowid';
    }
  }

  /// Memory-efficient JSON validation for large files
  Future<bool> validateJsonFileStreaming(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }
      
      // Stream-based JSON validation
      final stream = file.openRead();
      final decoder = JsonDecoder();
      
      try {
        // Read file in chunks and validate JSON structure
        final buffer = StringBuffer();
        int braceCount = 0;
        bool inString = false;
        bool escaped = false;
        
        await for (final chunk in stream) {
          final chunkStr = String.fromCharCodes(chunk);
          
          for (int i = 0; i < chunkStr.length; i++) {
            final char = chunkStr[i];
            
            if (escaped) {
              escaped = false;
              continue;
            }
            
            if (char == '\\') {
              escaped = true;
              continue;
            }
            
            if (char == '"') {
              inString = !inString;
              continue;
            }
            
            if (!inString) {
              if (char == '{') {
                braceCount++;
              } else if (char == '}') {
                braceCount--;
              }
            }
          }
        }
        
        // Valid JSON should have balanced braces
        return braceCount == 0;
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
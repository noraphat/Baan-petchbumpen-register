import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/services/performance_optimized_json_export_service.dart';
import '../../lib/services/performance_optimized_sql_export_service.dart';
import '../../lib/services/db_helper.dart';

/// Performance benchmark utility for backup operations
class PerformanceBenchmark {
  static const List<int> testSizes = [1000, 5000, 10000, 25000, 50000];
  
  /// Run comprehensive performance benchmark
  static Future<void> runBenchmark() async {
    print('=== Backup System Performance Benchmark ===\n');
    
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    final results = <String, Map<int, BenchmarkResult>>{};
    
    for (final size in testSizes) {
      print('Testing with $size records...');
      
      // Setup test database
      final database = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await _createTestTables(db);
        },
      );
      
      DbHelper.setTestDatabase(database);
      
      // Generate test data
      await _generateTestData(database, recordCount: size);
      
      // Benchmark JSON export
      final jsonResult = await _benchmarkJsonExport(size);
      results.putIfAbsent('JSON Export', () => {})[size] = jsonResult;
      
      // Benchmark SQL export
      final sqlResult = await _benchmarkSqlExport(size);
      results.putIfAbsent('SQL Export', () => {})[size] = sqlResult;
      
      // Benchmark batch operations
      final batchResult = await _benchmarkBatchOperations(size);
      results.putIfAbsent('Batch Operations', () => {})[size] = batchResult;
      
      await database.close();
      
      print('  Completed $size records\n');
    }
    
    // Print results
    _printBenchmarkResults(results);
    
    // Generate performance report
    await _generatePerformanceReport(results);
  }
  
  /// Benchmark JSON export performance
  static Future<BenchmarkResult> _benchmarkJsonExport(int recordCount) async {
    final service = PerformanceOptimizedJsonExportService();
    
    final stopwatch = Stopwatch()..start();
    final initialMemory = ProcessInfo.currentRss;
    
    final filePath = await service.exportAllTablesToJsonStreaming();
    
    stopwatch.stop();
    final finalMemory = ProcessInfo.currentRss;
    
    final fileSize = await File(filePath).length();
    await File(filePath).delete();
    
    return BenchmarkResult(
      operation: 'JSON Export',
      recordCount: recordCount,
      timeMs: stopwatch.elapsedMilliseconds,
      memoryUsedBytes: finalMemory - initialMemory,
      fileSizeBytes: fileSize,
    );
  }
  
  /// Benchmark SQL export performance
  static Future<BenchmarkResult> _benchmarkSqlExport(int recordCount) async {
    final service = PerformanceOptimizedSqlExportService();
    
    final stopwatch = Stopwatch()..start();
    final initialMemory = ProcessInfo.currentRss;
    
    final filePath = await service.exportToSqlStreaming();
    
    stopwatch.stop();
    final finalMemory = ProcessInfo.currentRss;
    
    final fileSize = await File(filePath).length();
    await File(filePath).delete();
    
    return BenchmarkResult(
      operation: 'SQL Export',
      recordCount: recordCount,
      timeMs: stopwatch.elapsedMilliseconds,
      memoryUsedBytes: finalMemory - initialMemory,
      fileSizeBytes: fileSize,
    );
  }
  
  /// Benchmark batch operations
  static Future<BenchmarkResult> _benchmarkBatchOperations(int recordCount) async {
    final service = PerformanceOptimizedJsonExportService();
    
    final stopwatch = Stopwatch()..start();
    final initialMemory = ProcessInfo.currentRss;
    
    // Test batch export of regs table
    final batchSize = 1000;
    int totalRecords = 0;
    int offset = 0;
    
    while (offset < recordCount) {
      final batch = await service.exportTableBatched(
        'regs',
        limit: batchSize,
        offset: offset,
      );
      
      totalRecords += batch.length;
      offset += batchSize;
      
      if (batch.length < batchSize) break;
    }
    
    stopwatch.stop();
    final finalMemory = ProcessInfo.currentRss;
    
    return BenchmarkResult(
      operation: 'Batch Operations',
      recordCount: totalRecords,
      timeMs: stopwatch.elapsedMilliseconds,
      memoryUsedBytes: finalMemory - initialMemory,
      fileSizeBytes: 0, // No file created for batch operations
    );
  }
  
  /// Print benchmark results in formatted table
  static void _printBenchmarkResults(Map<String, Map<int, BenchmarkResult>> results) {
    print('=== Performance Benchmark Results ===\n');
    
    for (final operation in results.keys) {
      print('$operation:');
      print('Records\tTime(ms)\tMemory(MB)\tFile(MB)\tRecords/sec');
      print('-' * 60);
      
      for (final size in testSizes) {
        final result = results[operation]![size];
        if (result != null) {
          final timeMs = result.timeMs;
          final memoryMB = (result.memoryUsedBytes / 1024 / 1024).toStringAsFixed(2);
          final fileMB = (result.fileSizeBytes / 1024 / 1024).toStringAsFixed(2);
          final recordsPerSec = (result.recordCount / (timeMs / 1000)).toStringAsFixed(0);
          
          print('${size}\t${timeMs}\t\t${memoryMB}\t\t${fileMB}\t\t${recordsPerSec}');
        }
      }
      print('');
    }
  }
  
  /// Generate detailed performance report
  static Future<void> _generatePerformanceReport(Map<String, Map<int, BenchmarkResult>> results) async {
    final report = StringBuffer();
    
    report.writeln('# Backup System Performance Report');
    report.writeln('Generated: ${DateTime.now().toIso8601String()}');
    report.writeln('');
    
    // Summary
    report.writeln('## Summary');
    report.writeln('');
    
    for (final operation in results.keys) {
      report.writeln('### $operation');
      report.writeln('');
      report.writeln('| Records | Time (ms) | Memory (MB) | File Size (MB) | Records/sec |');
      report.writeln('|---------|-----------|-------------|----------------|-------------|');
      
      for (final size in testSizes) {
        final result = results[operation]![size];
        if (result != null) {
          final timeMs = result.timeMs;
          final memoryMB = (result.memoryUsedBytes / 1024 / 1024).toStringAsFixed(2);
          final fileMB = (result.fileSizeBytes / 1024 / 1024).toStringAsFixed(2);
          final recordsPerSec = (result.recordCount / (timeMs / 1000)).toStringAsFixed(0);
          
          report.writeln('| $size | $timeMs | $memoryMB | $fileMB | $recordsPerSec |');
        }
      }
      report.writeln('');
    }
    
    // Performance analysis
    report.writeln('## Performance Analysis');
    report.writeln('');
    
    // Calculate scaling factors
    for (final operation in results.keys) {
      report.writeln('### $operation Scaling');
      report.writeln('');
      
      final operationResults = results[operation]!;
      final sizes = operationResults.keys.toList()..sort();
      
      for (int i = 1; i < sizes.length; i++) {
        final prevSize = sizes[i - 1];
        final currSize = sizes[i];
        final prevResult = operationResults[prevSize]!;
        final currResult = operationResults[currSize]!;
        
        final sizeRatio = currSize / prevSize;
        final timeRatio = currResult.timeMs / prevResult.timeMs;
        final memoryRatio = currResult.memoryUsedBytes / prevResult.memoryUsedBytes;
        
        report.writeln('- ${prevSize} to ${currSize} records:');
        report.writeln('  - Size ratio: ${sizeRatio.toStringAsFixed(1)}x');
        report.writeln('  - Time ratio: ${timeRatio.toStringAsFixed(1)}x');
        report.writeln('  - Memory ratio: ${memoryRatio.toStringAsFixed(1)}x');
        report.writeln('  - Efficiency: ${(sizeRatio / timeRatio).toStringAsFixed(2)} (higher is better)');
        report.writeln('');
      }
    }
    
    // Recommendations
    report.writeln('## Recommendations');
    report.writeln('');
    
    // Find best performing operations
    final jsonResults = results['JSON Export']!;
    final sqlResults = results['SQL Export']!;
    
    final json50k = jsonResults[50000];
    final sql50k = sqlResults[50000];
    
    if (json50k != null && sql50k != null) {
      if (json50k.timeMs < sql50k.timeMs) {
        report.writeln('- JSON export shows better performance for large datasets');
      } else {
        report.writeln('- SQL export shows better performance for large datasets');
      }
      
      final jsonThroughput = json50k.recordCount / (json50k.timeMs / 1000);
      final sqlThroughput = sql50k.recordCount / (sql50k.timeMs / 1000);
      
      report.writeln('- JSON throughput: ${jsonThroughput.toStringAsFixed(0)} records/sec');
      report.writeln('- SQL throughput: ${sqlThroughput.toStringAsFixed(0)} records/sec');
    }
    
    report.writeln('');
    report.writeln('## Performance Targets Met');
    report.writeln('');
    
    // Check if performance targets are met
    final targets = <String, bool>{};
    
    for (final operation in results.keys) {
      final result10k = results[operation]![10000];
      if (result10k != null) {
        // Target: 10,000 records in under 30 seconds
        targets['$operation - 10k records < 30s'] = result10k.timeMs < 30000;
        
        // Target: Memory usage < 100MB for streaming
        targets['$operation - Memory < 100MB'] = (result10k.memoryUsedBytes / 1024 / 1024) < 100;
      }
    }
    
    for (final target in targets.entries) {
      final status = target.value ? '✅ PASS' : '❌ FAIL';
      report.writeln('- ${target.key}: $status');
    }
    
    // Save report
    final reportFile = File('performance_report.md');
    await reportFile.writeAsString(report.toString());
    
    print('Performance report saved to: ${reportFile.path}');
  }
  
  /// Create test database tables
  static Future<void> _createTestTables(Database db) async {
    await db.execute('''
      CREATE TABLE regs (
        id TEXT PRIMARY KEY,
        first TEXT,
        last TEXT,
        dob TEXT,
        phone TEXT,
        addr TEXT,
        gender TEXT,
        hasIdCard INTEGER,
        status TEXT DEFAULT 'A',
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE stays (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        visitor_id TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        status TEXT DEFAULT 'active',
        note TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (visitor_id) REFERENCES regs (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE reg_additional_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        regId TEXT NOT NULL,
        visitId TEXT NOT NULL,
        startDate TEXT,
        endDate TEXT,
        shirtCount INTEGER DEFAULT 0,
        pantsCount INTEGER DEFAULT 0,
        matCount INTEGER DEFAULT 0,
        pillowCount INTEGER DEFAULT 0,
        blanketCount INTEGER DEFAULT 0,
        location TEXT,
        withChildren INTEGER DEFAULT 0,
        childrenCount INTEGER DEFAULT 0,
        notes TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        FOREIGN KEY (regId) REFERENCES regs (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE maps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        image_path TEXT,
        image_width REAL,
        image_height REAL,
        is_active INTEGER DEFAULT 0,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE rooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        size TEXT NOT NULL,
        shape TEXT DEFAULT 'square',
        capacity INTEGER NOT NULL,
        position_x REAL,
        position_y REAL,
        status TEXT DEFAULT 'available',
        description TEXT,
        current_occupant TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE room_bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_id INTEGER NOT NULL,
        visitor_id TEXT NOT NULL,
        check_in_date TEXT NOT NULL,
        check_out_date TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }
  
  /// Generate test data
  static Future<void> _generateTestData(Database db, {required int recordCount}) async {
    final random = Random();
    final batch = db.batch();
    
    // Generate regs data
    for (int i = 0; i < recordCount; i++) {
      final id = '${1000000000000 + i}';
      batch.insert('regs', {
        'id': id,
        'first': 'TestUser$i',
        'last': 'LastName$i',
        'dob': '1990-01-01',
        'phone': '081234${i.toString().padLeft(4, '0')}',
        'addr': 'Test Address $i, District ${i % 100}, Province ${i % 10}',
        'gender': random.nextBool() ? 'M' : 'F',
        'hasIdCard': 1,
        'status': 'A',
        'createdAt': DateTime.now().subtract(Duration(days: random.nextInt(365))).toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
    
    // Generate stays data (about 60% of regs)
    for (int i = 0; i < (recordCount * 0.6).round(); i++) {
      final visitorId = '${1000000000000 + i}';
      batch.insert('stays', {
        'visitor_id': visitorId,
        'start_date': '2024-01-${(i % 28 + 1).toString().padLeft(2, '0')}',
        'end_date': '2024-01-${((i % 28 + 1) + random.nextInt(7) + 1).toString().padLeft(2, '0')}',
        'status': random.nextBool() ? 'active' : 'completed',
        'note': 'Test stay note for visitor $i with some additional details',
        'created_at': DateTime.now().subtract(Duration(days: random.nextInt(30))).toIso8601String(),
      });
    }
    
    // Generate reg_additional_info data (about 40% of regs)
    for (int i = 0; i < (recordCount * 0.4).round(); i++) {
      final regId = '${1000000000000 + i}';
      batch.insert('reg_additional_info', {
        'regId': regId,
        'visitId': 'visit_${i}_${random.nextInt(1000)}',
        'startDate': '2024-01-${(i % 28 + 1).toString().padLeft(2, '0')}',
        'endDate': '2024-01-${((i % 28 + 1) + random.nextInt(7) + 1).toString().padLeft(2, '0')}',
        'shirtCount': random.nextInt(4),
        'pantsCount': random.nextInt(4),
        'matCount': 1,
        'pillowCount': 1,
        'blanketCount': random.nextInt(3) + 1,
        'location': 'Building ${random.nextInt(5) + 1}, Floor ${random.nextInt(3) + 1}',
        'withChildren': random.nextBool() ? 1 : 0,
        'childrenCount': random.nextInt(4),
        'notes': 'Additional information for visitor $i including special requirements and preferences',
        'createdAt': DateTime.now().subtract(Duration(days: random.nextInt(30))).toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
    
    await batch.commit(noResult: true);
  }
}

/// Benchmark result data class
class BenchmarkResult {
  final String operation;
  final int recordCount;
  final int timeMs;
  final int memoryUsedBytes;
  final int fileSizeBytes;
  
  BenchmarkResult({
    required this.operation,
    required this.recordCount,
    required this.timeMs,
    required this.memoryUsedBytes,
    required this.fileSizeBytes,
  });
  
  double get recordsPerSecond => recordCount / (timeMs / 1000);
  double get memoryMB => memoryUsedBytes / 1024 / 1024;
  double get fileSizeMB => fileSizeBytes / 1024 / 1024;
}

/// Main function to run benchmark
void main() async {
  await PerformanceBenchmark.runBenchmark();
}
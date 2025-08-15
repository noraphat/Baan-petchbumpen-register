import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'dart:math';
import '../../lib/services/performance_optimized_json_export_service.dart';
import '../../lib/services/performance_optimized_sql_export_service.dart';
import '../../lib/services/json_export_service.dart';
import '../../lib/services/sql_export_service.dart';
import '../../lib/services/db_helper.dart';

/// Performance tests for backup system with large datasets
void main() {
  group('Backup Performance Tests', () {
    late Database testDatabase;
    late PerformanceOptimizedJsonExportService optimizedJsonService;
    late PerformanceOptimizedSqlExportService optimizedSqlService;
    late JsonExportService standardJsonService;
    late SqlExportService standardSqlService;

    setUpAll(() async {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      
      optimizedJsonService = PerformanceOptimizedJsonExportService();
      optimizedSqlService = PerformanceOptimizedSqlExportService();
      standardJsonService = JsonExportService();
      standardSqlService = SqlExportService();
    });

    setUp(() async {
      // Create in-memory test database
      testDatabase = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await _createTestTables(db);
        },
      );
      
      // Override DbHelper to use test database
      DbHelper.setTestDatabase(testDatabase);
    });

    tearDown(() async {
      await testDatabase.close();
    });

    group('Large Dataset Performance Tests', () {
      test('JSON Export Performance - 10,000 records', () async {
        // Generate 10,000 test records
        await _generateTestData(testDatabase, recordCount: 10000);
        
        final stopwatch = Stopwatch()..start();
        
        // Track progress
        double lastProgress = 0.0;
        String lastStatus = '';
        
        final filePath = await optimizedJsonService.exportAllTablesToJsonStreaming(
          onProgress: (progress) {
            lastProgress = progress;
          },
          onStatusUpdate: (status) {
            lastStatus = status;
          },
        );
        
        stopwatch.stop();
        
        // Performance assertions
        expect(stopwatch.elapsedMilliseconds, lessThan(30000), 
               reason: 'JSON export should complete within 30 seconds');
        expect(lastProgress, equals(1.0), 
               reason: 'Progress should reach 100%');
        expect(File(filePath).existsSync(), isTrue, 
               reason: 'Export file should be created');
        
        // Verify file size is reasonable (not too large due to streaming)
        final fileSize = await File(filePath).length();
        expect(fileSize, greaterThan(1000), 
               reason: 'File should contain substantial data');
        
        print('JSON Export Performance (10k records):');
        print('  Time: ${stopwatch.elapsedMilliseconds}ms');
        print('  File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        print('  Final status: $lastStatus');
        
        // Cleanup
        await File(filePath).delete();
      });

      test('SQL Export Performance - 10,000 records', () async {
        // Generate 10,000 test records
        await _generateTestData(testDatabase, recordCount: 10000);
        
        final stopwatch = Stopwatch()..start();
        
        // Track progress
        double lastProgress = 0.0;
        String lastStatus = '';
        
        final filePath = await optimizedSqlService.exportToSqlStreaming(
          onProgress: (progress) {
            lastProgress = progress;
          },
          onStatusUpdate: (status) {
            lastStatus = status;
          },
        );
        
        stopwatch.stop();
        
        // Performance assertions
        expect(stopwatch.elapsedMilliseconds, lessThan(30000), 
               reason: 'SQL export should complete within 30 seconds');
        expect(lastProgress, equals(1.0), 
               reason: 'Progress should reach 100%');
        expect(File(filePath).existsSync(), isTrue, 
               reason: 'Export file should be created');
        
        // Verify file contains proper SQL structure
        final content = await File(filePath).readAsString();
        expect(content, contains('CREATE TABLE'), 
               reason: 'File should contain CREATE statements');
        expect(content, contains('INSERT INTO'), 
               reason: 'File should contain INSERT statements');
        
        final fileSize = await File(filePath).length();
        
        print('SQL Export Performance (10k records):');
        print('  Time: ${stopwatch.elapsedMilliseconds}ms');
        print('  File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        print('  Final status: $lastStatus');
        
        // Cleanup
        await File(filePath).delete();
      });

      test('Memory Usage Test - Large Dataset Export', () async {
        // Generate large dataset
        await _generateTestData(testDatabase, recordCount: 50000);
        
        // Monitor memory usage during export
        final initialMemory = ProcessInfo.currentRss;
        
        final filePath = await optimizedJsonService.exportAllTablesToJsonStreaming();
        
        final finalMemory = ProcessInfo.currentRss;
        final memoryIncrease = finalMemory - initialMemory;
        
        // Memory increase should be reasonable (less than 100MB for streaming)
        expect(memoryIncrease, lessThan(100 * 1024 * 1024), 
               reason: 'Memory usage should be controlled with streaming');
        
        print('Memory Usage Test (50k records):');
        print('  Initial memory: ${(initialMemory / 1024 / 1024).toStringAsFixed(2)} MB');
        print('  Final memory: ${(finalMemory / 1024 / 1024).toStringAsFixed(2)} MB');
        print('  Memory increase: ${(memoryIncrease / 1024 / 1024).toStringAsFixed(2)} MB');
        
        // Cleanup
        await File(filePath).delete();
      });

      test('Batch Processing Performance Test', () async {
        // Generate test data
        await _generateTestData(testDatabase, recordCount: 5000);
        
        final stopwatch = Stopwatch()..start();
        
        // Test batched export
        final results = await optimizedJsonService.exportTableBatched(
          'regs',
          limit: 1000,
          offset: 0,
        );
        
        stopwatch.stop();
        
        expect(results.length, equals(1000), 
               reason: 'Should return exactly 1000 records');
        expect(stopwatch.elapsedMilliseconds, lessThan(5000), 
               reason: 'Batch export should be fast');
        
        print('Batch Processing Performance:');
        print('  Time for 1000 records: ${stopwatch.elapsedMilliseconds}ms');
        print('  Records per second: ${(1000 / (stopwatch.elapsedMilliseconds / 1000)).toStringAsFixed(0)}');
      });
    });

    group('Performance Comparison Tests', () {
      test('Optimized vs Standard JSON Export Comparison', () async {
        // Generate moderate dataset for comparison
        await _generateTestData(testDatabase, recordCount: 5000);
        
        // Test optimized version
        final optimizedStopwatch = Stopwatch()..start();
        final optimizedPath = await optimizedJsonService.exportAllTablesToJsonStreaming();
        optimizedStopwatch.stop();
        
        // Test standard version
        final standardStopwatch = Stopwatch()..start();
        final standardPath = await standardJsonService.exportAllTablesToJson();
        standardStopwatch.stop();
        
        // Optimized should be faster or at least not significantly slower
        final optimizedTime = optimizedStopwatch.elapsedMilliseconds;
        final standardTime = standardStopwatch.elapsedMilliseconds;
        
        print('JSON Export Comparison (5k records):');
        print('  Optimized: ${optimizedTime}ms');
        print('  Standard: ${standardTime}ms');
        print('  Improvement: ${((standardTime - optimizedTime) / standardTime * 100).toStringAsFixed(1)}%');
        
        // Verify both files contain same data structure
        final optimizedSize = await File(optimizedPath).length();
        final standardSize = await File(standardPath).length();
        
        // Sizes should be comparable (within 10% difference)
        final sizeDifference = (optimizedSize - standardSize).abs() / standardSize;
        expect(sizeDifference, lessThan(0.1), 
               reason: 'File sizes should be comparable');
        
        // Cleanup
        await File(optimizedPath).delete();
        await File(standardPath).delete();
      });

      test('Streaming vs Non-streaming Memory Usage', () async {
        // Generate large dataset
        await _generateTestData(testDatabase, recordCount: 20000);
        
        // Test streaming approach
        final streamingInitialMemory = ProcessInfo.currentRss;
        final streamingPath = await optimizedJsonService.exportAllTablesToJsonStreaming();
        final streamingFinalMemory = ProcessInfo.currentRss;
        final streamingMemoryIncrease = streamingFinalMemory - streamingInitialMemory;
        
        // Reset memory state (force garbage collection)
        await Future.delayed(Duration(milliseconds: 100));
        
        // Test standard approach
        final standardInitialMemory = ProcessInfo.currentRss;
        final standardPath = await standardJsonService.exportAllTablesToJson();
        final standardFinalMemory = ProcessInfo.currentRss;
        final standardMemoryIncrease = standardFinalMemory - standardInitialMemory;
        
        print('Memory Usage Comparison (20k records):');
        print('  Streaming memory increase: ${(streamingMemoryIncrease / 1024 / 1024).toStringAsFixed(2)} MB');
        print('  Standard memory increase: ${(standardMemoryIncrease / 1024 / 1024).toStringAsFixed(2)} MB');
        print('  Memory savings: ${((standardMemoryIncrease - streamingMemoryIncrease) / standardMemoryIncrease * 100).toStringAsFixed(1)}%');
        
        // Streaming should use less memory
        expect(streamingMemoryIncrease, lessThan(standardMemoryIncrease), 
               reason: 'Streaming should use less memory');
        
        // Cleanup
        await File(streamingPath).delete();
        await File(standardPath).delete();
      });
    });

    group('Scalability Tests', () {
      test('Performance scaling with dataset size', () async {
        final testSizes = [1000, 5000, 10000, 25000];
        final results = <int, int>{};
        
        for (final size in testSizes) {
          // Clear database and generate new data
          await _clearTestData(testDatabase);
          await _generateTestData(testDatabase, recordCount: size);
          
          final stopwatch = Stopwatch()..start();
          final filePath = await optimizedJsonService.exportAllTablesToJsonStreaming();
          stopwatch.stop();
          
          results[size] = stopwatch.elapsedMilliseconds;
          
          print('Export time for $size records: ${stopwatch.elapsedMilliseconds}ms');
          
          // Cleanup
          await File(filePath).delete();
        }
        
        // Verify performance scales reasonably (should be roughly linear)
        final ratio1k5k = results[5000]! / results[1000]!;
        final ratio5k10k = results[10000]! / results[5000]!;
        
        // Performance should scale reasonably (not exponentially)
        expect(ratio1k5k, lessThan(10), 
               reason: 'Performance should scale reasonably');
        expect(ratio5k10k, lessThan(5), 
               reason: 'Performance should scale reasonably');
        
        print('Scaling Analysis:');
        print('  1k to 5k ratio: ${ratio1k5k.toStringAsFixed(2)}x');
        print('  5k to 10k ratio: ${ratio5k10k.toStringAsFixed(2)}x');
      });

      test('Concurrent export performance', () async {
        // Generate test data
        await _generateTestData(testDatabase, recordCount: 5000);
        
        // Test concurrent exports (simulating multiple backup operations)
        final stopwatch = Stopwatch()..start();
        
        final futures = List.generate(3, (index) async {
          return await optimizedJsonService.exportAllTablesToJsonStreaming();
        });
        
        final results = await Future.wait(futures);
        stopwatch.stop();
        
        // All exports should complete successfully
        expect(results.length, equals(3));
        for (final path in results) {
          expect(File(path).existsSync(), isTrue);
        }
        
        print('Concurrent Export Performance:');
        print('  3 concurrent exports: ${stopwatch.elapsedMilliseconds}ms');
        print('  Average per export: ${(stopwatch.elapsedMilliseconds / 3).toStringAsFixed(0)}ms');
        
        // Cleanup
        for (final path in results) {
          await File(path).delete();
        }
      });
    });

    group('File Size and Compression Tests', () {
      test('File size efficiency test', () async {
        await _generateTestData(testDatabase, recordCount: 10000);
        
        // Export with both services
        final jsonPath = await optimizedJsonService.exportAllTablesToJsonStreaming();
        final sqlPath = await optimizedSqlService.exportToSqlStreaming();
        
        final jsonSize = await File(jsonPath).length();
        final sqlSize = await File(sqlPath).length();
        
        print('File Size Comparison (10k records):');
        print('  JSON: ${(jsonSize / 1024 / 1024).toStringAsFixed(2)} MB');
        print('  SQL: ${(sqlSize / 1024 / 1024).toStringAsFixed(2)} MB');
        print('  SQL/JSON ratio: ${(sqlSize / jsonSize).toStringAsFixed(2)}');
        
        // Both files should be reasonable size
        expect(jsonSize, greaterThan(100000), reason: 'JSON should contain substantial data');
        expect(sqlSize, greaterThan(100000), reason: 'SQL should contain substantial data');
        
        // Cleanup
        await File(jsonPath).delete();
        await File(sqlPath).delete();
      });
    });
  });
}

/// Create test database tables
Future<void> _createTestTables(Database db) async {
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

/// Generate test data for performance testing
Future<void> _generateTestData(Database db, {required int recordCount}) async {
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
      'addr': 'Test Address $i',
      'gender': random.nextBool() ? 'M' : 'F',
      'hasIdCard': 1,
      'status': 'A',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
  
  // Generate stays data (about 50% of regs)
  for (int i = 0; i < recordCount ~/ 2; i++) {
    final visitorId = '${1000000000000 + i}';
    batch.insert('stays', {
      'visitor_id': visitorId,
      'start_date': '2024-01-01',
      'end_date': '2024-01-07',
      'status': 'active',
      'note': 'Test stay $i',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  
  // Generate reg_additional_info data (about 30% of regs)
  for (int i = 0; i < recordCount ~/ 3; i++) {
    final regId = '${1000000000000 + i}';
    batch.insert('reg_additional_info', {
      'regId': regId,
      'visitId': 'visit_$i',
      'startDate': '2024-01-01',
      'endDate': '2024-01-07',
      'shirtCount': random.nextInt(3),
      'pantsCount': random.nextInt(3),
      'matCount': 1,
      'pillowCount': 1,
      'blanketCount': 1,
      'location': 'Location $i',
      'withChildren': random.nextBool() ? 1 : 0,
      'childrenCount': random.nextInt(3),
      'notes': 'Test notes for visitor $i',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
  
  // Generate some app_settings
  batch.insert('app_settings', {
    'key': 'test_setting_1',
    'value': 'test_value_1',
    'updated_at': DateTime.now().toIso8601String(),
  });
  
  // Generate maps data
  for (int i = 0; i < 10; i++) {
    batch.insert('maps', {
      'name': 'Test Map $i',
      'image_path': '/test/path/map$i.png',
      'image_width': 800.0,
      'image_height': 600.0,
      'is_active': i == 0 ? 1 : 0,
      'description': 'Test map description $i',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
  
  // Generate rooms data
  for (int i = 0; i < 100; i++) {
    batch.insert('rooms', {
      'name': 'Room $i',
      'size': 'medium',
      'shape': 'square',
      'capacity': 2,
      'position_x': random.nextDouble() * 1000,
      'position_y': random.nextDouble() * 1000,
      'status': 'available',
      'description': 'Test room $i',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
  
  // Generate room_bookings data
  for (int i = 0; i < recordCount ~/ 10; i++) {
    final visitorId = '${1000000000000 + i}';
    batch.insert('room_bookings', {
      'room_id': (i % 100) + 1,
      'visitor_id': visitorId,
      'check_in_date': '2024-01-01',
      'check_out_date': '2024-01-07',
      'status': 'confirmed',
      'note': 'Test booking $i',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
  
  await batch.commit(noResult: true);
}

/// Clear all test data
Future<void> _clearTestData(Database db) async {
  await db.delete('room_bookings');
  await db.delete('rooms');
  await db.delete('maps');
  await db.delete('reg_additional_info');
  await db.delete('stays');
  await db.delete('regs');
  await db.delete('app_settings');
}
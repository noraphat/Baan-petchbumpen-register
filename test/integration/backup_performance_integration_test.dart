import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'dart:math';
import '../../lib/services/backup_service.dart';
import '../../lib/services/performance_optimized_json_export_service.dart';
import '../../lib/services/performance_optimized_sql_export_service.dart';
import '../../lib/services/backup_performance_monitor.dart';
import '../../lib/services/db_helper.dart';

/// Integration tests for backup system performance with real-world scenarios
void main() {
  group('Backup Performance Integration Tests', () {
    late Database testDatabase;
    late BackupService backupService;
    late BackupPerformanceMonitor performanceMonitor;

    setUpAll(() async {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      
      performanceMonitor = BackupPerformanceMonitor.instance;
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
      
      // Set test database
      DbHelper.setTestDatabase(testDatabase);
      
      // Reset backup service instance
      BackupService.resetInstance();
      backupService = BackupService.instance;
    });

    tearDown(() async {
      await testDatabase.close();
      DbHelper.clearTestDatabase();
    });

    group('Real-world Performance Scenarios', () {
      test('Large monastery dataset simulation - 25,000 visitors', () async {
        // Simulate a large monastery with 25,000 visitors over 5 years
        await _generateRealisticMonasteryData(testDatabase, visitorCount: 25000);
        
        final operationId = performanceMonitor.startOperation(
          'Large Dataset Export',
          metadata: {'visitorCount': 25000, 'scenario': 'monastery_simulation'},
        );
        
        final stopwatch = Stopwatch()..start();
        
        // Test JSON export performance
        final jsonPath = await backupService.exportToJson();
        
        stopwatch.stop();
        
        performanceMonitor.completeOperation(
          operationId,
          success: true,
          finalRecordCount: 25000,
          fileSizeBytes: await File(jsonPath).length(),
        );
        
        // Performance assertions for large dataset
        expect(stopwatch.elapsedMilliseconds, lessThan(60000), 
               reason: 'Large dataset export should complete within 60 seconds');
        
        // Verify file integrity
        expect(File(jsonPath).existsSync(), isTrue);
        final fileSize = await File(jsonPath).length();
        expect(fileSize, greaterThan(10 * 1024 * 1024), 
               reason: 'Large dataset should produce substantial file');
        
        print('Large Dataset Performance:');
        print('  Records: 25,000 visitors');
        print('  Time: ${stopwatch.elapsedMilliseconds}ms');
        print('  File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        print('  Throughput: ${(25000 / (stopwatch.elapsedMilliseconds / 1000)).toStringAsFixed(0)} records/sec');
        
        // Cleanup
        await File(jsonPath).delete();
      });

      test('Peak season backup simulation - concurrent operations', () async {
        // Simulate peak season with moderate dataset
        await _generateRealisticMonasteryData(testDatabase, visitorCount: 10000);
        
        // Simulate concurrent backup operations (like auto backup + manual export)
        final futures = <Future>[];
        final results = <String>[];
        
        final stopwatch = Stopwatch()..start();
        
        // Concurrent JSON and SQL exports
        futures.add(
          backupService.exportToJson().then((path) => results.add(path))
        );
        futures.add(
          backupService.exportToSql().then((path) => results.add(path))
        );
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Both operations should complete successfully
        expect(results.length, equals(2));
        for (final path in results) {
          expect(File(path).existsSync(), isTrue);
        }
        
        print('Concurrent Operations Performance:');
        print('  Operations: JSON + SQL export');
        print('  Total time: ${stopwatch.elapsedMilliseconds}ms');
        print('  Average per operation: ${(stopwatch.elapsedMilliseconds / 2).toStringAsFixed(0)}ms');
        
        // Cleanup
        for (final path in results) {
          await File(path).delete();
        }
      });

      test('Memory stress test - multiple large exports', () async {
        // Generate substantial dataset
        await _generateRealisticMonasteryData(testDatabase, visitorCount: 15000);
        
        final initialMemory = ProcessInfo.currentRss;
        final memoryReadings = <int>[];
        
        // Perform multiple exports to test memory management
        for (int i = 0; i < 3; i++) {
          final filePath = await backupService.exportToJson();
          
          final currentMemory = ProcessInfo.currentRss;
          memoryReadings.add(currentMemory);
          
          // Cleanup immediately to test memory release
          await File(filePath).delete();
          
          // Small delay to allow garbage collection
          await Future.delayed(Duration(milliseconds: 100));
        }
        
        final finalMemory = ProcessInfo.currentRss;
        final maxMemoryIncrease = memoryReadings
            .map((m) => m - initialMemory)
            .reduce((a, b) => a > b ? a : b);
        
        print('Memory Stress Test:');
        print('  Initial memory: ${(initialMemory / 1024 / 1024).toStringAsFixed(2)} MB');
        print('  Final memory: ${(finalMemory / 1024 / 1024).toStringAsFixed(2)} MB');
        print('  Max memory increase: ${(maxMemoryIncrease / 1024 / 1024).toStringAsFixed(2)} MB');
        print('  Memory leak: ${(finalMemory - initialMemory) / 1024 / 1024 > 50 ? 'DETECTED' : 'None'}');
        
        // Memory should not increase excessively
        expect(maxMemoryIncrease / 1024 / 1024, lessThan(200), 
               reason: 'Memory usage should be controlled');
      });

      test('Progressive dataset size performance analysis', () async {
        final testSizes = [1000, 5000, 10000, 20000];
        final performanceData = <int, Map<String, dynamic>>{};
        
        for (final size in testSizes) {
          // Clear and regenerate data
          await _clearTestData(testDatabase);
          await _generateRealisticMonasteryData(testDatabase, visitorCount: size);
          
          final stopwatch = Stopwatch()..start();
          final initialMemory = ProcessInfo.currentRss;
          
          final filePath = await backupService.exportToJson();
          
          stopwatch.stop();
          final finalMemory = ProcessInfo.currentRss;
          final fileSize = await File(filePath).length();
          
          performanceData[size] = {
            'timeMs': stopwatch.elapsedMilliseconds,
            'memoryMB': (finalMemory - initialMemory) / 1024 / 1024,
            'fileSizeMB': fileSize / 1024 / 1024,
            'throughput': size / (stopwatch.elapsedMilliseconds / 1000),
          };
          
          await File(filePath).delete();
        }
        
        // Analyze scaling characteristics
        print('Progressive Performance Analysis:');
        print('Size\tTime(ms)\tMemory(MB)\tFile(MB)\tThroughput');
        print('-' * 60);
        
        for (final size in testSizes) {
          final data = performanceData[size]!;
          print('${size}\t${data['timeMs']}\t\t${data['memoryMB'].toStringAsFixed(1)}\t\t${data['fileSizeMB'].toStringAsFixed(1)}\t\t${data['throughput'].toStringAsFixed(0)}');
        }
        
        // Verify reasonable scaling
        final ratio1k10k = performanceData[10000]!['timeMs'] / performanceData[1000]!['timeMs'];
        expect(ratio1k10k, lessThan(15), 
               reason: 'Performance should scale reasonably (not exponentially)');
      });
    });

    group('Performance Monitoring Integration', () {
      test('Performance monitor tracks metrics correctly', () async {
        await _generateRealisticMonasteryData(testDatabase, visitorCount: 5000);
        
        // Monitor performance updates
        final updates = <PerformanceUpdate>[];
        final subscription = performanceMonitor.performanceUpdates.listen(
          (update) => updates.add(update),
        );
        
        try {
          await backupService.exportToJson();
          
          // Should have received multiple updates
          expect(updates.length, greaterThan(2));
          
          // Should have start and completion updates
          expect(updates.any((u) => u.type == PerformanceUpdateType.started), isTrue);
          expect(updates.any((u) => u.type == PerformanceUpdateType.completed), isTrue);
          
          // Should have progress updates
          expect(updates.any((u) => u.progress != null), isTrue);
          
        } finally {
          await subscription.cancel();
        }
      });

      test('Performance targets validation', () async {
        await _generateRealisticMonasteryData(testDatabase, visitorCount: 8000);
        
        final operationId = performanceMonitor.startOperation('Target Test');
        
        final stopwatch = Stopwatch()..start();
        await backupService.exportToJson();
        stopwatch.stop();
        
        performanceMonitor.completeOperation(
          operationId,
          success: true,
          finalRecordCount: 8000,
        );
        
        final meetsTargets = performanceMonitor.meetsPerformanceTargets(operationId);
        
        print('Performance Targets Check:');
        print('  Time: ${stopwatch.elapsedMilliseconds}ms (target: <30000ms)');
        print('  Meets targets: ${meetsTargets ? 'YES' : 'NO'}');
        
        // For 8k records, should meet performance targets
        expect(meetsTargets, isTrue, 
               reason: 'Should meet performance targets for 8k records');
      });
    });

    group('Error Handling Performance', () {
      test('Performance under error conditions', () async {
        await _generateRealisticMonasteryData(testDatabase, visitorCount: 5000);
        
        // Simulate disk space error by using invalid path
        // This tests error handling performance
        final stopwatch = Stopwatch()..start();
        
        try {
          // This should fail gracefully without hanging
          await backupService.restoreFromFile('/invalid/path/file.sql');
          fail('Should have thrown an exception');
        } catch (e) {
          stopwatch.stop();
          
          // Error handling should be fast
          expect(stopwatch.elapsedMilliseconds, lessThan(5000), 
                 reason: 'Error handling should be fast');
          
          print('Error Handling Performance: ${stopwatch.elapsedMilliseconds}ms');
        }
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

  // Create performance indexes
  await db.execute('CREATE INDEX idx_regs_phone ON regs(phone)');
  await db.execute('CREATE INDEX idx_regs_status ON regs(status)');
  await db.execute('CREATE INDEX idx_stays_visitor_id ON stays(visitor_id)');
  await db.execute('CREATE INDEX idx_stays_date_range ON stays(start_date, end_date)');
}

/// Generate realistic monastery data for performance testing
Future<void> _generateRealisticMonasteryData(Database db, {required int visitorCount}) async {
  final random = Random();
  final batch = db.batch();
  
  // Thai names for realistic data
  final thaiFirstNames = [
    'สมชาย', 'สมหญิง', 'วิชัย', 'วิภา', 'ประยุทธ', 'ประภา', 'สุรชัย', 'สุรีย์',
    'นิรันดร', 'นิรมล', 'ธนาคาร', 'ธนพร', 'อนุชา', 'อนุสรา', 'พิชัย', 'พิมพ์',
    'รัตนา', 'รัชนี', 'สมบัติ', 'สมบูรณ์', 'วีระ', 'วีรยา', 'ชัยวัฒน์', 'ชัยรัตน์'
  ];
  
  final thaiLastNames = [
    'ใจดี', 'ใจงาม', 'สุขสม', 'สุขใส', 'เจริญ', 'เจริญสุข', 'พัฒนา', 'พัฒนาการ',
    'วิวัฒน์', 'วิวัฒนา', 'ศรีสุข', 'ศรีสวัสดิ์', 'ทองดี', 'ทองคำ', 'เงินดี', 'เงินทอง',
    'รุ่งเรือง', 'รุ่งโรจน์', 'สว่างใส', 'สว่างศรี', 'บุญมี', 'บุญเรือง', 'มีสุข', 'มีชัย'
  ];
  
  final provinces = [
    'กรุงเทพมหานคร', 'นนทบุรี', 'ปทุมธานี', 'สมุทรปราการ', 'นครปฐม',
    'เชียงใหม่', 'เชียงราย', 'ลำปาง', 'ลำพูน', 'แพร่',
    'นครราชสีมา', 'บุรีรัมย์', 'สุรินทร์', 'ศรีสะเกษ', 'อุบลราชธานี',
    'สงขลา', 'ภูเก็ต', 'กระบี่', 'ตรัง', 'สตูล'
  ];
  
  // Generate visitor records
  for (int i = 0; i < visitorCount; i++) {
    final id = '${1000000000000 + i}';
    final firstName = thaiFirstNames[random.nextInt(thaiFirstNames.length)];
    final lastName = thaiLastNames[random.nextInt(thaiLastNames.length)];
    final province = provinces[random.nextInt(provinces.length)];
    
    // Generate realistic birth dates (ages 20-80)
    final birthYear = DateTime.now().year - (20 + random.nextInt(60));
    final birthMonth = random.nextInt(12) + 1;
    final birthDay = random.nextInt(28) + 1;
    
    batch.insert('regs', {
      'id': id,
      'first': firstName,
      'last': lastName,
      'dob': '$birthDay/${birthMonth.toString().padLeft(2, '0')}/${(birthYear + 543)}', // Buddhist calendar
      'phone': '08${random.nextInt(9)}${random.nextInt(10000000).toString().padLeft(7, '0')}',
      'addr': '$province, เขต${random.nextInt(20) + 1}, แขวง${random.nextInt(50) + 1}, ${random.nextInt(999) + 1}/${random.nextInt(999) + 1}',
      'gender': random.nextBool() ? 'ชาย' : 'หญิง',
      'hasIdCard': 1,
      'status': 'A',
      'createdAt': DateTime.now().subtract(Duration(days: random.nextInt(1825))).toIso8601String(), // Up to 5 years ago
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
  
  // Generate stays data (70% of visitors have stays)
  final stayCount = (visitorCount * 0.7).round();
  for (int i = 0; i < stayCount; i++) {
    final visitorId = '${1000000000000 + i}';
    final startDate = DateTime.now().subtract(Duration(days: random.nextInt(365)));
    final duration = random.nextInt(14) + 1; // 1-14 days stay
    final endDate = startDate.add(Duration(days: duration));
    
    batch.insert('stays', {
      'visitor_id': visitorId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': random.nextDouble() < 0.8 ? 'completed' : 'active',
      'note': 'การเข้าพักครั้งที่ ${random.nextInt(5) + 1}',
      'created_at': startDate.toIso8601String(),
    });
  }
  
  // Generate additional info (50% of visitors)
  final additionalInfoCount = (visitorCount * 0.5).round();
  for (int i = 0; i < additionalInfoCount; i++) {
    final regId = '${1000000000000 + i}';
    final visitId = '${regId}_${DateTime.now().millisecondsSinceEpoch + i}';
    
    batch.insert('reg_additional_info', {
      'regId': regId,
      'visitId': visitId,
      'startDate': DateTime.now().subtract(Duration(days: random.nextInt(365))).toIso8601String(),
      'endDate': DateTime.now().subtract(Duration(days: random.nextInt(365) - 7)).toIso8601String(),
      'shirtCount': random.nextInt(4),
      'pantsCount': random.nextInt(4),
      'matCount': 1,
      'pillowCount': 1,
      'blanketCount': random.nextInt(3) + 1,
      'location': 'อาคาร ${random.nextInt(5) + 1} ชั้น ${random.nextInt(3) + 1} ห้อง ${random.nextInt(50) + 1}',
      'withChildren': random.nextBool() ? 1 : 0,
      'childrenCount': random.nextBool() ? random.nextInt(3) : 0,
      'notes': 'ข้อมูลเพิ่มเติมสำหรับการเข้าพัก มีความต้องการพิเศษ: ${random.nextBool() ? 'อาหารเจ' : 'ไม่มี'}',
      'createdAt': DateTime.now().subtract(Duration(days: random.nextInt(365))).toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
  
  // Generate some app settings
  batch.insert('app_settings', {
    'key': 'monastery_name',
    'value': 'วัดทดสอบประสิทธิภาพ',
    'updated_at': DateTime.now().toIso8601String(),
  });
  
  // Generate maps data
  for (int i = 0; i < 5; i++) {
    batch.insert('maps', {
      'name': 'แผนที่อาคาร ${i + 1}',
      'image_path': '/maps/building_${i + 1}.png',
      'image_width': 1200.0,
      'image_height': 800.0,
      'is_active': i == 0 ? 1 : 0,
      'description': 'แผนที่อาคารที่พักสำหรับผู้เข้าร่วมกิจกรรม',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
  
  // Generate rooms data
  for (int i = 0; i < 200; i++) {
    batch.insert('rooms', {
      'name': 'ห้อง ${(i + 1).toString().padLeft(3, '0')}',
      'size': ['small', 'medium', 'large'][random.nextInt(3)],
      'shape': 'square',
      'capacity': random.nextInt(4) + 1,
      'position_x': random.nextDouble() * 1000,
      'position_y': random.nextDouble() * 1000,
      'status': ['available', 'occupied', 'maintenance'][random.nextInt(3)],
      'description': 'ห้องพักสำหรับผู้เข้าร่วมกิจกรรม',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
  
  // Generate room bookings (30% of visitors have bookings)
  final bookingCount = (visitorCount * 0.3).round();
  for (int i = 0; i < bookingCount; i++) {
    final visitorId = '${1000000000000 + i}';
    final checkIn = DateTime.now().add(Duration(days: random.nextInt(30)));
    final checkOut = checkIn.add(Duration(days: random.nextInt(7) + 1));
    
    batch.insert('room_bookings', {
      'room_id': random.nextInt(200) + 1,
      'visitor_id': visitorId,
      'check_in_date': checkIn.toIso8601String(),
      'check_out_date': checkOut.toIso8601String(),
      'status': ['pending', 'confirmed', 'cancelled'][random.nextInt(3)],
      'note': 'การจองห้องพักสำหรับกิจกรรม',
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
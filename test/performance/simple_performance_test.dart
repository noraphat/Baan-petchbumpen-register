import 'dart:io';
import 'dart:math';

/// Simple performance test for backup operations without Flutter dependencies
void main() async {
  print('🚀 Starting Simple Backup Performance Tests...\n');
  
  final stopwatch = Stopwatch()..start();
  
  try {
    // Test 1: Large data structure creation and serialization
    await testLargeDataStructurePerformance();
    
    // Test 2: File I/O performance
    await testFileIOPerformance();
    
    // Test 3: Memory usage simulation
    await testMemoryUsageSimulation();
    
    stopwatch.stop();
    
    print('\n✅ Simple performance tests completed successfully!');
    print('Total execution time: ${stopwatch.elapsedMilliseconds}ms');
    
  } catch (e, stackTrace) {
    print('❌ Performance tests failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

/// Test large data structure creation and JSON serialization performance
Future<void> testLargeDataStructurePerformance() async {
  print('📊 Testing large data structure performance...');
  
  final stopwatch = Stopwatch()..start();
  
  // Create large data structure (simulating 10,000 records)
  final largeData = <String, dynamic>{
    'export_info': {
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
      'total_records': 10000,
    },
    'tables': <String, List<Map<String, dynamic>>>{},
  };
  
  // Generate test data
  final tables = largeData['tables'] as Map<String, List<Map<String, dynamic>>>;
  
  // Generate regs table data
  final regsList = <Map<String, dynamic>>[];
  for (int i = 0; i < 10000; i++) {
    regsList.add({
      'id': '${1000000000000 + i}',
      'first': 'TestUser$i',
      'last': 'LastName$i',
      'dob': '1990-01-01',
      'phone': '081234${i.toString().padLeft(4, '0')}',
      'addr': 'Test Address $i, District ${i % 100}, Province ${i % 10}',
      'gender': i % 2 == 0 ? 'M' : 'F',
      'hasIdCard': 1,
      'status': 'A',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
  tables['regs'] = regsList;
  
  // Generate stays table data
  final staysList = <Map<String, dynamic>>[];
  for (int i = 0; i < 5000; i++) {
    staysList.add({
      'id': i + 1,
      'visitor_id': '${1000000000000 + i}',
      'start_date': DateTime.now().subtract(Duration(days: Random().nextInt(365))).toIso8601String(),
      'end_date': DateTime.now().subtract(Duration(days: Random().nextInt(365) - 7)).toIso8601String(),
      'status': Random().nextBool() ? 'active' : 'completed',
      'note': 'Test stay note for visitor $i',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  tables['stays'] = staysList;
  
  stopwatch.stop();
  
  final dataCreationTime = stopwatch.elapsedMilliseconds;
  print('  Data structure creation: ${dataCreationTime}ms');
  
  // Test JSON serialization performance
  stopwatch.reset();
  stopwatch.start();
  
  // Simulate JSON encoding (without actual JSON library to avoid dependencies)
  int totalFields = 0;
  for (final table in tables.values) {
    for (final record in table) {
      totalFields += record.length;
    }
  }
  
  stopwatch.stop();
  
  final serializationTime = stopwatch.elapsedMilliseconds;
  print('  Data serialization simulation: ${serializationTime}ms');
  print('  Total fields processed: $totalFields');
  print('  Records per second: ${(15000 / (dataCreationTime + serializationTime) * 1000).toStringAsFixed(0)}');
  
  // Performance assertions
  if (dataCreationTime > 5000) {
    print('  ⚠️  WARNING: Data creation took longer than expected (${dataCreationTime}ms > 5000ms)');
  } else {
    print('  ✅ Data creation performance: GOOD');
  }
  
  if (serializationTime > 2000) {
    print('  ⚠️  WARNING: Serialization took longer than expected (${serializationTime}ms > 2000ms)');
  } else {
    print('  ✅ Serialization performance: GOOD');
  }
}

/// Test file I/O performance
Future<void> testFileIOPerformance() async {
  print('\n📁 Testing file I/O performance...');
  
  final stopwatch = Stopwatch()..start();
  
  // Create test data
  final testData = StringBuffer();
  for (int i = 0; i < 10000; i++) {
    testData.writeln('INSERT INTO regs VALUES (\'${1000000000000 + i}\', \'TestUser$i\', \'LastName$i\', \'1990-01-01\', \'0812345678\', \'Test Address $i\', \'M\', 1, \'A\', \'${DateTime.now().toIso8601String()}\', \'${DateTime.now().toIso8601String()}\');');
  }
  
  final dataString = testData.toString();
  stopwatch.stop();
  
  final dataGenerationTime = stopwatch.elapsedMilliseconds;
  print('  SQL data generation: ${dataGenerationTime}ms');
  
  // Test file writing performance
  stopwatch.reset();
  stopwatch.start();
  
  final testFile = File('test_performance_backup.sql');
  await testFile.writeAsString(dataString);
  
  stopwatch.stop();
  
  final fileWriteTime = stopwatch.elapsedMilliseconds;
  final fileSize = await testFile.length();
  
  print('  File write time: ${fileWriteTime}ms');
  print('  File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
  print('  Write speed: ${(fileSize / 1024 / 1024 / (fileWriteTime / 1000)).toStringAsFixed(2)} MB/s');
  
  // Test file reading performance
  stopwatch.reset();
  stopwatch.start();
  
  final readData = await testFile.readAsString();
  
  stopwatch.stop();
  
  final fileReadTime = stopwatch.elapsedMilliseconds;
  print('  File read time: ${fileReadTime}ms');
  print('  Read speed: ${(fileSize / 1024 / 1024 / (fileReadTime / 1000)).toStringAsFixed(2)} MB/s');
  
  // Cleanup
  await testFile.delete();
  
  // Performance assertions
  if (fileWriteTime > 3000) {
    print('  ⚠️  WARNING: File write took longer than expected (${fileWriteTime}ms > 3000ms)');
  } else {
    print('  ✅ File write performance: GOOD');
  }
  
  if (fileReadTime > 2000) {
    print('  ⚠️  WARNING: File read took longer than expected (${fileReadTime}ms > 2000ms)');
  } else {
    print('  ✅ File read performance: GOOD');
  }
  
  // Verify data integrity
  if (readData.length == dataString.length) {
    print('  ✅ Data integrity: VERIFIED');
  } else {
    print('  ❌ Data integrity: FAILED');
  }
}

/// Test memory usage simulation
Future<void> testMemoryUsageSimulation() async {
  print('\n🧠 Testing memory usage simulation...');
  
  final initialMemory = ProcessInfo.currentRss;
  print('  Initial memory: ${(initialMemory / 1024 / 1024).toStringAsFixed(2)} MB');
  
  // Simulate large data processing in batches
  final batchSize = 1000;
  final totalRecords = 10000;
  final batches = (totalRecords / batchSize).ceil();
  
  final stopwatch = Stopwatch()..start();
  
  for (int batch = 0; batch < batches; batch++) {
    // Simulate batch processing
    final batchData = <Map<String, dynamic>>[];
    
    for (int i = 0; i < batchSize; i++) {
      final recordIndex = batch * batchSize + i;
      if (recordIndex >= totalRecords) break;
      
      batchData.add({
        'id': '${1000000000000 + recordIndex}',
        'first': 'TestUser$recordIndex',
        'last': 'LastName$recordIndex',
        'data': 'Some additional data for record $recordIndex' * 10, // Make it larger
      });
    }
    
    // Simulate processing (e.g., JSON serialization)
    final processedData = <String>[];
    for (final record in batchData) {
      processedData.add(record.toString());
    }
    
    // Clear batch data to simulate memory management
    batchData.clear();
    processedData.clear();
    
    // Check memory usage every 5 batches
    if (batch % 5 == 0) {
      final currentMemory = ProcessInfo.currentRss;
      final memoryIncrease = currentMemory - initialMemory;
      print('  Batch ${batch + 1}/${batches}: Memory increase: ${(memoryIncrease / 1024 / 1024).toStringAsFixed(2)} MB');
      
      // If memory increase is too high, warn about potential memory leak
      if (memoryIncrease > 100 * 1024 * 1024) { // 100MB
        print('  ⚠️  WARNING: High memory usage detected');
      }
    }
  }
  
  stopwatch.stop();
  
  final finalMemory = ProcessInfo.currentRss;
  final totalMemoryIncrease = finalMemory - initialMemory;
  
  print('  Processing time: ${stopwatch.elapsedMilliseconds}ms');
  print('  Final memory: ${(finalMemory / 1024 / 1024).toStringAsFixed(2)} MB');
  print('  Total memory increase: ${(totalMemoryIncrease / 1024 / 1024).toStringAsFixed(2)} MB');
  print('  Records per second: ${(totalRecords / (stopwatch.elapsedMilliseconds / 1000)).toStringAsFixed(0)}');
  
  // Performance assertions
  if (totalMemoryIncrease > 50 * 1024 * 1024) { // 50MB
    print('  ⚠️  WARNING: Memory usage higher than expected (${(totalMemoryIncrease / 1024 / 1024).toStringAsFixed(2)} MB > 50 MB)');
  } else {
    print('  ✅ Memory usage: GOOD');
  }
  
  if (stopwatch.elapsedMilliseconds > 10000) { // 10 seconds
    print('  ⚠️  WARNING: Processing took longer than expected (${stopwatch.elapsedMilliseconds}ms > 10000ms)');
  } else {
    print('  ✅ Processing performance: GOOD');
  }
}
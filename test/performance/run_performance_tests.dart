#!/usr/bin/env dart

import 'dart:io';
import 'performance_benchmark.dart';

/// Script to run performance tests and generate reports
void main(List<String> args) async {
  print('🚀 Starting Backup System Performance Tests...\n');
  
  final stopwatch = Stopwatch()..start();
  
  try {
    // Run comprehensive benchmark
    await PerformanceBenchmark.runBenchmark();
    
    stopwatch.stop();
    
    print('\n✅ Performance tests completed successfully!');
    print('Total execution time: ${stopwatch.elapsedMilliseconds}ms');
    print('');
    print('📊 Reports generated:');
    print('  - performance_report.md');
    print('');
    print('🎯 Performance Targets:');
    print('  - JSON/SQL Export: < 30 seconds for 10k records');
    print('  - Memory usage: < 100MB for streaming operations');
    print('  - Throughput: > 300 records/second');
    
  } catch (e, stackTrace) {
    print('❌ Performance tests failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
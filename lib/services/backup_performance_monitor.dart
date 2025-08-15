import 'dart:io';
import 'dart:async';

/// Performance monitoring service for backup operations
/// Tracks metrics like execution time, memory usage, and throughput
class BackupPerformanceMonitor {
  static BackupPerformanceMonitor? _instance;
  static BackupPerformanceMonitor get instance => _instance ??= BackupPerformanceMonitor._();
  
  BackupPerformanceMonitor._();
  
  final Map<String, PerformanceMetrics> _metrics = {};
  final StreamController<PerformanceUpdate> _updateController = 
      StreamController<PerformanceUpdate>.broadcast();
  
  /// Stream of performance updates
  Stream<PerformanceUpdate> get performanceUpdates => _updateController.stream;
  
  /// Start monitoring an operation
  String startOperation(String operationName, {Map<String, dynamic>? metadata}) {
    final operationId = '${operationName}_${DateTime.now().millisecondsSinceEpoch}';
    
    _metrics[operationId] = PerformanceMetrics(
      operationId: operationId,
      operationName: operationName,
      startTime: DateTime.now(),
      startMemory: ProcessInfo.currentRss,
      metadata: metadata ?? {},
    );
    
    _updateController.add(PerformanceUpdate(
      operationId: operationId,
      operationName: operationName,
      type: PerformanceUpdateType.started,
      message: 'Started monitoring $operationName',
    ));
    
    return operationId;
  }
  
  /// Update operation progress
  void updateProgress(String operationId, {
    double? progress,
    int? recordsProcessed,
    String? currentTask,
    Map<String, dynamic>? additionalData,
  }) {
    final metrics = _metrics[operationId];
    if (metrics == null) return;
    
    metrics.progress = progress ?? metrics.progress;
    metrics.recordsProcessed = recordsProcessed ?? metrics.recordsProcessed;
    metrics.currentTask = currentTask ?? metrics.currentTask;
    
    if (additionalData != null) {
      metrics.additionalData.addAll(additionalData);
    }
    
    // Calculate current throughput
    final elapsed = DateTime.now().difference(metrics.startTime).inMilliseconds;
    if (elapsed > 0 && metrics.recordsProcessed > 0) {
      metrics.currentThroughput = (metrics.recordsProcessed / (elapsed / 1000)).round();
    }
    
    _updateController.add(PerformanceUpdate(
      operationId: operationId,
      operationName: metrics.operationName,
      type: PerformanceUpdateType.progress,
      progress: metrics.progress,
      throughput: metrics.currentThroughput,
      message: currentTask ?? 'Processing...',
    ));
  }
  
  /// Complete operation monitoring
  PerformanceMetrics completeOperation(String operationId, {
    bool success = true,
    String? errorMessage,
    int? finalRecordCount,
    int? fileSizeBytes,
  }) {
    final metrics = _metrics[operationId];
    if (metrics == null) {
      throw ArgumentError('Operation $operationId not found');
    }
    
    metrics.endTime = DateTime.now();
    metrics.endMemory = ProcessInfo.currentRss;
    metrics.success = success;
    metrics.errorMessage = errorMessage;
    metrics.finalRecordCount = finalRecordCount ?? metrics.recordsProcessed;
    metrics.fileSizeBytes = fileSizeBytes;
    
    // Calculate final metrics
    final duration = metrics.endTime!.difference(metrics.startTime);
    metrics.durationMs = duration.inMilliseconds;
    metrics.memoryUsedBytes = metrics.endMemory! - metrics.startMemory;
    
    if (metrics.finalRecordCount > 0 && metrics.durationMs > 0) {
      metrics.averageThroughput = (metrics.finalRecordCount / (metrics.durationMs / 1000)).round();
    }
    
    _updateController.add(PerformanceUpdate(
      operationId: operationId,
      operationName: metrics.operationName,
      type: success ? PerformanceUpdateType.completed : PerformanceUpdateType.failed,
      message: success ? 'Operation completed successfully' : 'Operation failed: $errorMessage',
      duration: metrics.durationMs,
      throughput: metrics.averageThroughput,
      memoryUsed: metrics.memoryUsedBytes,
    ));
    
    return metrics;
  }
  
  /// Get current metrics for an operation
  PerformanceMetrics? getMetrics(String operationId) {
    return _metrics[operationId];
  }
  
  /// Get all completed metrics
  List<PerformanceMetrics> getCompletedMetrics() {
    return _metrics.values.where((m) => m.endTime != null).toList();
  }
  
  /// Get performance summary for operation type
  PerformanceSummary getOperationSummary(String operationName) {
    final operationMetrics = _metrics.values
        .where((m) => m.operationName == operationName && m.endTime != null)
        .toList();
    
    if (operationMetrics.isEmpty) {
      return PerformanceSummary(
        operationName: operationName,
        totalOperations: 0,
        successfulOperations: 0,
        averageDurationMs: 0,
        averageThroughput: 0,
        averageMemoryUsage: 0,
      );
    }
    
    final successful = operationMetrics.where((m) => m.success).toList();
    final totalDuration = operationMetrics.fold<int>(0, (sum, m) => sum + m.durationMs);
    final totalThroughput = successful.fold<int>(0, (sum, m) => sum + m.averageThroughput);
    final totalMemory = operationMetrics.fold<int>(0, (sum, m) => sum + m.memoryUsedBytes);
    
    return PerformanceSummary(
      operationName: operationName,
      totalOperations: operationMetrics.length,
      successfulOperations: successful.length,
      averageDurationMs: totalDuration ~/ operationMetrics.length,
      averageThroughput: successful.isNotEmpty ? totalThroughput ~/ successful.length : 0,
      averageMemoryUsage: totalMemory ~/ operationMetrics.length,
      minDurationMs: operationMetrics.map((m) => m.durationMs).reduce((a, b) => a < b ? a : b),
      maxDurationMs: operationMetrics.map((m) => m.durationMs).reduce((a, b) => a > b ? a : b),
      totalRecordsProcessed: operationMetrics.fold<int>(0, (sum, m) => sum + m.finalRecordCount),
    );
  }
  
  /// Clear old metrics (keep only last 100 operations)
  void cleanupMetrics() {
    if (_metrics.length <= 100) return;
    
    final sortedEntries = _metrics.entries.toList()
      ..sort((a, b) => b.value.startTime.compareTo(a.value.startTime));
    
    _metrics.clear();
    
    // Keep only the 100 most recent operations
    for (int i = 0; i < 100 && i < sortedEntries.length; i++) {
      _metrics[sortedEntries[i].key] = sortedEntries[i].value;
    }
  }
  
  /// Export performance data to JSON
  Map<String, dynamic> exportMetrics() {
    return {
      'export_timestamp': DateTime.now().toIso8601String(),
      'total_operations': _metrics.length,
      'metrics': _metrics.values.map((m) => m.toJson()).toList(),
    };
  }
  
  /// Check if operation meets performance targets
  bool meetsPerformanceTargets(String operationId) {
    final metrics = _metrics[operationId];
    if (metrics == null || metrics.endTime == null) return false;
    
    // Define performance targets
    const targets = {
      'JSON Export': {'maxDurationMs': 30000, 'maxMemoryMB': 100, 'minThroughput': 300},
      'SQL Export': {'maxDurationMs': 30000, 'maxMemoryMB': 100, 'minThroughput': 300},
      'Restore': {'maxDurationMs': 60000, 'maxMemoryMB': 150, 'minThroughput': 200},
    };
    
    final target = targets[metrics.operationName];
    if (target == null) return true; // No targets defined
    
    final memoryMB = metrics.memoryUsedBytes / 1024 / 1024;
    
    return metrics.durationMs <= target['maxDurationMs']! &&
           memoryMB <= target['maxMemoryMB']! &&
           metrics.averageThroughput >= target['minThroughput']!;
  }
  
  /// Generate performance report
  String generatePerformanceReport() {
    final report = StringBuffer();
    
    report.writeln('# Backup Performance Report');
    report.writeln('Generated: ${DateTime.now().toIso8601String()}');
    report.writeln('');
    
    // Overall statistics
    final allMetrics = getCompletedMetrics();
    final successfulOps = allMetrics.where((m) => m.success).length;
    
    report.writeln('## Overall Statistics');
    report.writeln('- Total operations: ${allMetrics.length}');
    report.writeln('- Successful operations: $successfulOps');
    report.writeln('- Success rate: ${(successfulOps / allMetrics.length * 100).toStringAsFixed(1)}%');
    report.writeln('');
    
    // Operation summaries
    final operationNames = allMetrics.map((m) => m.operationName).toSet();
    
    for (final operationName in operationNames) {
      final summary = getOperationSummary(operationName);
      
      report.writeln('## $operationName Performance');
      report.writeln('- Total operations: ${summary.totalOperations}');
      report.writeln('- Successful operations: ${summary.successfulOperations}');
      report.writeln('- Average duration: ${summary.averageDurationMs}ms');
      report.writeln('- Average throughput: ${summary.averageThroughput} records/sec');
      report.writeln('- Average memory usage: ${(summary.averageMemoryUsage / 1024 / 1024).toStringAsFixed(2)} MB');
      
      if (summary.minDurationMs != null && summary.maxDurationMs != null) {
        report.writeln('- Duration range: ${summary.minDurationMs}ms - ${summary.maxDurationMs}ms');
      }
      
      if (summary.totalRecordsProcessed != null) {
        report.writeln('- Total records processed: ${summary.totalRecordsProcessed}');
      }
      
      report.writeln('');
    }
    
    // Performance targets analysis
    report.writeln('## Performance Targets Analysis');
    
    for (final operationName in operationNames) {
      final operationMetrics = allMetrics.where((m) => m.operationName == operationName);
      final meetingTargets = operationMetrics.where((m) => meetsPerformanceTargets(m.operationId)).length;
      final targetRate = (meetingTargets / operationMetrics.length * 100).toStringAsFixed(1);
      
      report.writeln('- $operationName: $targetRate% meeting performance targets');
    }
    
    return report.toString();
  }
  
  /// Dispose resources
  void dispose() {
    _updateController.close();
    _metrics.clear();
  }
}

/// Performance metrics for a single operation
class PerformanceMetrics {
  final String operationId;
  final String operationName;
  final DateTime startTime;
  final int startMemory;
  final Map<String, dynamic> metadata;
  
  DateTime? endTime;
  int? endMemory;
  int durationMs = 0;
  int memoryUsedBytes = 0;
  bool success = false;
  String? errorMessage;
  
  double progress = 0.0;
  int recordsProcessed = 0;
  int finalRecordCount = 0;
  int? fileSizeBytes;
  String? currentTask;
  int currentThroughput = 0;
  int averageThroughput = 0;
  
  Map<String, dynamic> additionalData = {};
  
  PerformanceMetrics({
    required this.operationId,
    required this.operationName,
    required this.startTime,
    required this.startMemory,
    required this.metadata,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'operationId': operationId,
      'operationName': operationName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMs': durationMs,
      'memoryUsedBytes': memoryUsedBytes,
      'success': success,
      'errorMessage': errorMessage,
      'finalRecordCount': finalRecordCount,
      'fileSizeBytes': fileSizeBytes,
      'averageThroughput': averageThroughput,
      'metadata': metadata,
      'additionalData': additionalData,
    };
  }
}

/// Performance summary for an operation type
class PerformanceSummary {
  final String operationName;
  final int totalOperations;
  final int successfulOperations;
  final int averageDurationMs;
  final int averageThroughput;
  final int averageMemoryUsage;
  final int? minDurationMs;
  final int? maxDurationMs;
  final int? totalRecordsProcessed;
  
  PerformanceSummary({
    required this.operationName,
    required this.totalOperations,
    required this.successfulOperations,
    required this.averageDurationMs,
    required this.averageThroughput,
    required this.averageMemoryUsage,
    this.minDurationMs,
    this.maxDurationMs,
    this.totalRecordsProcessed,
  });
  
  double get successRate => totalOperations > 0 ? successfulOperations / totalOperations : 0.0;
}

/// Performance update event
class PerformanceUpdate {
  final String operationId;
  final String operationName;
  final PerformanceUpdateType type;
  final String message;
  final double? progress;
  final int? duration;
  final int? throughput;
  final int? memoryUsed;
  
  PerformanceUpdate({
    required this.operationId,
    required this.operationName,
    required this.type,
    required this.message,
    this.progress,
    this.duration,
    this.throughput,
    this.memoryUsed,
  });
}

/// Types of performance updates
enum PerformanceUpdateType {
  started,
  progress,
  completed,
  failed,
}
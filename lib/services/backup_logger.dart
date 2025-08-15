import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Comprehensive logging service for backup operations
class BackupLogger {
  static BackupLogger? _instance;
  static BackupLogger get instance => _instance ??= BackupLogger._();
  
  BackupLogger._();

  final StreamController<LogEntry> _logController = StreamController<LogEntry>.broadcast();
  final List<LogEntry> _logBuffer = [];
  static const int _maxBufferSize = 1000;
  static const int _maxLogFileSize = 5 * 1024 * 1024; // 5MB

  /// Stream of log entries
  Stream<LogEntry> get logStream => _logController.stream;

  /// Get current log buffer
  List<LogEntry> get logBuffer => List.unmodifiable(_logBuffer);

  /// Log debug message
  void debug(String message, {String? operation, Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, operation: operation, data: data);
  }

  /// Log info message
  void info(String message, {String? operation, Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, operation: operation, data: data);
  }

  /// Log warning message
  void warning(String message, {String? operation, Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, operation: operation, data: data);
  }

  /// Log error message
  void error(
    String message, {
    String? operation,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.error,
      message,
      operation: operation,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Log critical error message
  void critical(
    String message, {
    String? operation,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.critical,
      message,
      operation: operation,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Log operation start
  void startOperation(String operation, {Map<String, dynamic>? data}) {
    info('Starting operation: $operation', operation: operation, data: data);
  }

  /// Log operation completion
  void completeOperation(
    String operation, {
    Duration? duration,
    Map<String, dynamic>? data,
  }) {
    final message = duration != null
        ? 'Completed operation: $operation (${duration.inMilliseconds}ms)'
        : 'Completed operation: $operation';
    info(message, operation: operation, data: data);
  }

  /// Log operation failure
  void failOperation(
    String operation, {
    dynamic error,
    StackTrace? stackTrace,
    Duration? duration,
    Map<String, dynamic>? data,
  }) {
    final message = duration != null
        ? 'Failed operation: $operation (${duration.inMilliseconds}ms)'
        : 'Failed operation: $operation';
    this.error(
      message,
      operation: operation,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Log performance metrics
  void performance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? metrics,
  }) {
    final data = {
      'duration_ms': duration.inMilliseconds,
      'duration_seconds': duration.inSeconds,
      ...?metrics,
    };
    info('Performance: $operation took ${duration.inMilliseconds}ms', 
         operation: operation, data: data);
  }

  /// Internal logging method
  void _log(
    LogLevel level,
    String message, {
    String? operation,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    final entry = LogEntry(
      level: level,
      message: message,
      operation: operation,
      error: error,
      stackTrace: stackTrace,
      data: data,
      timestamp: DateTime.now(),
    );

    // Add to buffer
    _logBuffer.add(entry);
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }

    // Send to stream
    _logController.add(entry);

    // Log to developer console
    developer.log(
      entry.formattedMessage,
      name: 'BackupLogger',
      level: entry.developerLogLevel,
      error: error,
      stackTrace: stackTrace,
    );

    // Write to file asynchronously
    _writeToFile(entry);
  }

  /// Write log entry to file
  Future<void> _writeToFile(LogEntry entry) async {
    try {
      final file = await _getLogFile();
      final logLine = '${entry.toJson()}\n';
      
      // Check file size and rotate if necessary
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize > _maxLogFileSize) {
          await _rotateLogFile(file);
        }
      }
      
      await file.writeAsString(logLine, mode: FileMode.append);
    } catch (e) {
      // Fallback to developer log if file writing fails
      developer.log(
        'Failed to write log to file: $e',
        name: 'BackupLogger',
        level: 1000,
      );
    }
  }

  /// Get log file
  Future<File> _getLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final logDir = Directory('${directory.path}/logs');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    return File('${logDir.path}/backup.log');
  }

  /// Rotate log file when it gets too large
  Future<void> _rotateLogFile(File currentFile) async {
    try {
      final directory = currentFile.parent;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final rotatedFile = File('${directory.path}/backup_$timestamp.log');
      
      await currentFile.rename(rotatedFile.path);
      
      // Keep only the last 5 rotated files
      final logFiles = directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('backup_') && f.path.endsWith('.log'))
          .toList();
      
      logFiles.sort((a, b) => b.path.compareTo(a.path));
      
      if (logFiles.length > 5) {
        for (int i = 5; i < logFiles.length; i++) {
          await logFiles[i].delete();
        }
      }
    } catch (e) {
      developer.log(
        'Failed to rotate log file: $e',
        name: 'BackupLogger',
        level: 1000,
      );
    }
  }

  /// Get logs by level
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logBuffer.where((entry) => entry.level == level).toList();
  }

  /// Get logs by operation
  List<LogEntry> getLogsByOperation(String operation) {
    return _logBuffer.where((entry) => entry.operation == operation).toList();
  }

  /// Get logs in time range
  List<LogEntry> getLogsInRange(DateTime start, DateTime end) {
    return _logBuffer.where((entry) => 
      entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end)
    ).toList();
  }

  /// Get recent logs
  List<LogEntry> getRecentLogs({int count = 100}) {
    final logs = List<LogEntry>.from(_logBuffer);
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs.take(count).toList();
  }

  /// Export logs to string
  String exportLogs({
    LogLevel? minLevel,
    String? operation,
    DateTime? since,
  }) {
    var logs = List<LogEntry>.from(_logBuffer);
    
    if (minLevel != null) {
      logs = logs.where((log) => log.level.index >= minLevel.index).toList();
    }
    
    if (operation != null) {
      logs = logs.where((log) => log.operation == operation).toList();
    }
    
    if (since != null) {
      logs = logs.where((log) => log.timestamp.isAfter(since)).toList();
    }
    
    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final buffer = StringBuffer();
    buffer.writeln('Backup System Logs');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${logs.length}');
    buffer.writeln('${'=' * 50}');
    
    for (final log in logs) {
      buffer.writeln(log.formattedMessage);
      if (log.data != null && log.data!.isNotEmpty) {
        buffer.writeln('  Data: ${jsonEncode(log.data)}');
      }
      if (log.error != null) {
        buffer.writeln('  Error: ${log.error}');
      }
      if (log.stackTrace != null) {
        buffer.writeln('  Stack trace:');
        buffer.writeln('    ${log.stackTrace.toString().replaceAll('\n', '\n    ')}');
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  /// Clear log buffer
  void clearLogs() {
    _logBuffer.clear();
    info('Log buffer cleared');
  }

  /// Dispose resources
  void dispose() {
    if (!_logController.isClosed) {
      _logController.close();
    }
  }
}

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Log entry
class LogEntry {
  final LogLevel level;
  final String message;
  final String? operation;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  const LogEntry({
    required this.level,
    required this.message,
    this.operation,
    this.error,
    this.stackTrace,
    this.data,
    required this.timestamp,
  });

  /// Get developer log level
  int get developerLogLevel {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.critical:
        return 1200;
    }
  }

  /// Get level name
  String get levelName {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.critical:
        return 'CRITICAL';
    }
  }

  /// Get formatted message
  String get formattedMessage {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('[$levelName] ');
    if (operation != null) {
      buffer.write('[$operation] ');
    }
    buffer.write(message);
    return buffer.toString();
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': levelName,
      'operation': operation,
      'message': message,
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
      'data': data,
    };
  }

  /// Create from JSON
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      level: LogLevel.values.firstWhere(
        (l) => l.toString().split('.').last.toUpperCase() == json['level'],
        orElse: () => LogLevel.info,
      ),
      message: json['message'] ?? '',
      operation: json['operation'],
      error: json['error'],
      stackTrace: json['stackTrace'] != null 
          ? StackTrace.fromString(json['stackTrace'])
          : null,
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  String toString() {
    return formattedMessage;
  }
}

/// Extension for measuring operation duration
extension BackupLoggerOperations on BackupLogger {
  /// Measure and log operation duration
  Future<T> measureOperation<T>(
    String operation,
    Future<T> Function() function, {
    Map<String, dynamic>? data,
  }) async {
    startOperation(operation, data: data);
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await function();
      stopwatch.stop();
      completeOperation(operation, duration: stopwatch.elapsed, data: data);
      performance(operation, stopwatch.elapsed);
      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();
      failOperation(
        operation,
        error: error,
        stackTrace: stackTrace,
        duration: stopwatch.elapsed,
        data: data,
      );
      rethrow;
    }
  }
}
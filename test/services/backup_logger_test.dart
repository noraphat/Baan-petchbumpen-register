import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/services/backup_logger.dart';

void main() {
  group('BackupLogger', () {
    late BackupLogger logger;
    late StreamSubscription<LogEntry> subscription;
    late List<LogEntry> receivedLogs;

    setUp(() {
      logger = BackupLogger.instance;
      receivedLogs = [];
      subscription = logger.logStream.listen((logEntry) {
        receivedLogs.add(logEntry);
      });
    });

    tearDown(() {
      subscription.cancel();
      receivedLogs.clear();
      logger.clearLogs();
    });

    test('should log debug message', () async {
      logger.debug('Test debug message', operation: 'Test Operation');

      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedLogs.length, equals(1));
      final logEntry = receivedLogs.first;
      expect(logEntry.level, equals(LogLevel.debug));
      expect(logEntry.message, equals('Test debug message'));
      expect(logEntry.operation, equals('Test Operation'));
    });

    test('should log info message', () async {
      logger.info('Test info message', operation: 'Test Operation');

      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedLogs.length, equals(1));
      final logEntry = receivedLogs.first;
      expect(logEntry.level, equals(LogLevel.info));
      expect(logEntry.message, equals('Test info message'));
      expect(logEntry.operation, equals('Test Operation'));
    });

    test('should log warning message', () async {
      logger.warning('Test warning message', operation: 'Test Operation');

      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedLogs.length, equals(1));
      final logEntry = receivedLogs.first;
      expect(logEntry.level, equals(LogLevel.warning));
      expect(logEntry.message, equals('Test warning message'));
      expect(logEntry.operation, equals('Test Operation'));
    });

    test('should log error message', () async {
      final testError = Exception('Test error');
      final testStackTrace = StackTrace.current;

      logger.error(
        'Test error message',
        operation: 'Test Operation',
        error: testError,
        stackTrace: testStackTrace,
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedLogs.length, equals(1));
      final logEntry = receivedLogs.first;
      expect(logEntry.level, equals(LogLevel.error));
      expect(logEntry.message, equals('Test error message'));
      expect(logEntry.operation, equals('Test Operation'));
      expect(logEntry.error, equals(testError));
      expect(logEntry.stackTrace, equals(testStackTrace));
    });

    test('should log critical message', () async {
      final testError = Exception('Critical error');

      logger.critical(
        'Test critical message',
        operation: 'Test Operation',
        error: testError,
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedLogs.length, equals(1));
      final logEntry = receivedLogs.first;
      expect(logEntry.level, equals(LogLevel.critical));
      expect(logEntry.message, equals('Test critical message'));
      expect(logEntry.operation, equals('Test Operation'));
      expect(logEntry.error, equals(testError));
    });

    test('should log with data', () async {
      final testData = {'key1': 'value1', 'key2': 42};

      logger.info('Test message with data', operation: 'Test Operation', data: testData);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedLogs.length, equals(1));
      final logEntry = receivedLogs.first;
      expect(logEntry.data, equals(testData));
    });

    test('should start and complete operation', () async {
      logger.startOperation('Test Operation', data: {'param': 'value'});
      logger.completeOperation('Test Operation', duration: const Duration(milliseconds: 100));

      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedLogs.length, equals(2));
      expect(receivedLogs[0].message, contains('Starting operation: Test Operation'));
      expect(receivedLogs[1].message, contains('Completed operation: Test Operation (100ms)'));
    });

    test('should fail operation', () async {
      final testError = Exception('Operation failed');

      logger.failOperation(
        'Test Operation',
        error: testError,
        duration: const Duration(milliseconds: 50),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedLogs.length, equals(1));
      final logEntry = receivedLogs.first;
      expect(logEntry.level, equals(LogLevel.error));
      expect(logEntry.message, contains('Failed operation: Test Operation (50ms)'));
      expect(logEntry.error, equals(testError));
    });

    test('should log performance metrics', () async {
      final testMetrics = {'records_processed': 1000, 'memory_used': 512};

      logger.performance(
        'Test Operation',
        const Duration(milliseconds: 250),
        metrics: testMetrics,
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedLogs.length, equals(1));
      final logEntry = receivedLogs.first;
      expect(logEntry.message, contains('Performance: Test Operation took 250ms'));
      expect(logEntry.data!['duration_ms'], equals(250));
      expect(logEntry.data!['records_processed'], equals(1000));
      expect(logEntry.data!['memory_used'], equals(512));
    });

    test('should maintain log buffer with max size', () async {
      // Add more logs than the buffer size (assuming max is 1000)
      for (int i = 0; i < 1005; i++) {
        logger.info('Log message $i');
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // Buffer should not exceed max size
      expect(logger.logBuffer.length, lessThanOrEqualTo(1000));
      
      // Should contain the most recent logs
      expect(logger.logBuffer.last.message, equals('Log message 1004'));
    });

    test('should get logs by level', () async {
      logger.debug('Debug message');
      logger.info('Info message');
      logger.warning('Warning message');
      logger.error('Error message');

      await Future.delayed(const Duration(milliseconds: 10));

      final errorLogs = logger.getLogsByLevel(LogLevel.error);
      expect(errorLogs.length, equals(1));
      expect(errorLogs.first.message, equals('Error message'));

      final warningLogs = logger.getLogsByLevel(LogLevel.warning);
      expect(warningLogs.length, equals(1));
      expect(warningLogs.first.message, equals('Warning message'));
    });

    test('should get logs by operation', () async {
      logger.info('Message 1', operation: 'Operation A');
      logger.info('Message 2', operation: 'Operation B');
      logger.info('Message 3', operation: 'Operation A');

      await Future.delayed(const Duration(milliseconds: 10));

      final operationALogs = logger.getLogsByOperation('Operation A');
      expect(operationALogs.length, equals(2));
      expect(operationALogs[0].message, equals('Message 1'));
      expect(operationALogs[1].message, equals('Message 3'));
    });

    test('should get logs in time range', () async {
      final start = DateTime.now();
      
      logger.info('Message 1');
      await Future.delayed(const Duration(milliseconds: 10));
      
      final middle = DateTime.now();
      
      logger.info('Message 2');
      await Future.delayed(const Duration(milliseconds: 10));
      
      final end = DateTime.now();

      final logsInRange = logger.getLogsInRange(start, end);
      expect(logsInRange.length, equals(1));
      expect(logsInRange.first.message, equals('Message 2'));
    });

    test('should get recent logs', () async {
      for (int i = 0; i < 10; i++) {
        logger.info('Message $i');
      }

      await Future.delayed(const Duration(milliseconds: 10));

      final recentLogs = logger.getRecentLogs(count: 5);
      expect(recentLogs.length, equals(5));
      
      // Should be in reverse chronological order (newest first)
      expect(recentLogs.first.message, equals('Message 9'));
      expect(recentLogs.last.message, equals('Message 5'));
    });

    test('should export logs to string', () async {
      logger.info('Info message', operation: 'Test Op');
      logger.error('Error message', operation: 'Test Op', error: Exception('Test error'));

      await Future.delayed(const Duration(milliseconds: 10));

      final exportedLogs = logger.exportLogs(operation: 'Test Op');
      
      expect(exportedLogs, contains('Backup System Logs'));
      expect(exportedLogs, contains('Total entries: 2'));
      expect(exportedLogs, contains('Info message'));
      expect(exportedLogs, contains('Error message'));
      expect(exportedLogs, contains('Exception: Test error'));
    });

    test('should export logs with filters', () async {
      logger.debug('Debug message');
      logger.info('Info message');
      logger.warning('Warning message');
      logger.error('Error message');

      await Future.delayed(const Duration(milliseconds: 10));

      final exportedLogs = logger.exportLogs(minLevel: LogLevel.warning);
      
      expect(exportedLogs, contains('Warning message'));
      expect(exportedLogs, contains('Error message'));
      expect(exportedLogs, isNot(contains('Debug message')));
      expect(exportedLogs, isNot(contains('Info message')));
    });

    test('should clear logs', () async {
      logger.info('Message 1');
      logger.info('Message 2');

      await Future.delayed(const Duration(milliseconds: 10));

      expect(logger.logBuffer.length, equals(2));

      logger.clearLogs();

      await Future.delayed(const Duration(milliseconds: 10));

      // Should have one log entry for the clear operation itself
      expect(logger.logBuffer.length, equals(1));
      expect(logger.logBuffer.first.message, equals('Log buffer cleared'));
    });

    test('should measure operation duration', () async {
      String? result;
      Exception? caughtException;

      try {
        result = await logger.measureOperation('Test Operation', () async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 'Success';
        });
      } catch (e) {
        caughtException = e as Exception;
      }

      await Future.delayed(const Duration(milliseconds: 10));

      expect(result, equals('Success'));
      expect(caughtException, isNull);
      
      // Should have start, complete, and performance logs
      expect(receivedLogs.length, greaterThanOrEqualTo(3));
      expect(receivedLogs.any((log) => log.message.contains('Starting operation')), isTrue);
      expect(receivedLogs.any((log) => log.message.contains('Completed operation')), isTrue);
      expect(receivedLogs.any((log) => log.message.contains('Performance')), isTrue);
    });

    test('should measure operation duration with failure', () async {
      String? result;
      Exception? caughtException;

      try {
        result = await logger.measureOperation('Test Operation', () async {
          await Future.delayed(const Duration(milliseconds: 50));
          throw Exception('Operation failed');
        });
      } catch (e) {
        caughtException = e as Exception;
      }

      await Future.delayed(const Duration(milliseconds: 10));

      expect(result, isNull);
      expect(caughtException, isNotNull);
      expect(caughtException.toString(), contains('Operation failed'));
      
      // Should have start and fail logs
      expect(receivedLogs.length, greaterThanOrEqualTo(2));
      expect(receivedLogs.any((log) => log.message.contains('Starting operation')), isTrue);
      expect(receivedLogs.any((log) => log.message.contains('Failed operation')), isTrue);
    });
  });

  group('LogEntry', () {
    test('should create log entry with all properties', () {
      final timestamp = DateTime.now();
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;
      final data = {'key': 'value'};

      final logEntry = LogEntry(
        level: LogLevel.error,
        message: 'Test message',
        operation: 'Test Operation',
        error: error,
        stackTrace: stackTrace,
        data: data,
        timestamp: timestamp,
      );

      expect(logEntry.level, equals(LogLevel.error));
      expect(logEntry.message, equals('Test message'));
      expect(logEntry.operation, equals('Test Operation'));
      expect(logEntry.error, equals(error));
      expect(logEntry.stackTrace, equals(stackTrace));
      expect(logEntry.data, equals(data));
      expect(logEntry.timestamp, equals(timestamp));
    });

    test('should return correct developer log level', () {
      expect(const LogEntry(
        level: LogLevel.debug,
        message: 'test',
        timestamp: timestamp,
      ).developerLogLevel, equals(500));

      expect(const LogEntry(
        level: LogLevel.info,
        message: 'test',
        timestamp: timestamp,
      ).developerLogLevel, equals(800));

      expect(const LogEntry(
        level: LogLevel.warning,
        message: 'test',
        timestamp: timestamp,
      ).developerLogLevel, equals(900));

      expect(const LogEntry(
        level: LogLevel.error,
        message: 'test',
        timestamp: timestamp,
      ).developerLogLevel, equals(1000));

      expect(const LogEntry(
        level: LogLevel.critical,
        message: 'test',
        timestamp: timestamp,
      ).developerLogLevel, equals(1200));
    });

    test('should return correct level name', () {
      expect(const LogEntry(
        level: LogLevel.debug,
        message: 'test',
        timestamp: timestamp,
      ).levelName, equals('DEBUG'));

      expect(const LogEntry(
        level: LogLevel.info,
        message: 'test',
        timestamp: timestamp,
      ).levelName, equals('INFO'));

      expect(const LogEntry(
        level: LogLevel.warning,
        message: 'test',
        timestamp: timestamp,
      ).levelName, equals('WARN'));

      expect(const LogEntry(
        level: LogLevel.error,
        message: 'test',
        timestamp: timestamp,
      ).levelName, equals('ERROR'));

      expect(const LogEntry(
        level: LogLevel.critical,
        message: 'test',
        timestamp: timestamp,
      ).levelName, equals('CRITICAL'));
    });

    test('should format message correctly', () {
      final timestamp = DateTime.parse('2022-01-01T12:00:00.000Z');
      
      final logEntry = LogEntry(
        level: LogLevel.info,
        message: 'Test message',
        operation: 'Test Operation',
        timestamp: timestamp,
      );

      final formatted = logEntry.formattedMessage;
      expect(formatted, contains('[2022-01-01T12:00:00.000Z]'));
      expect(formatted, contains('[INFO]'));
      expect(formatted, contains('[Test Operation]'));
      expect(formatted, contains('Test message'));
    });

    test('should convert to and from JSON', () {
      final timestamp = DateTime.parse('2022-01-01T12:00:00.000Z');
      final stackTrace = StackTrace.current;
      final data = {'key': 'value', 'number': 42};

      final originalEntry = LogEntry(
        level: LogLevel.error,
        message: 'Test message',
        operation: 'Test Operation',
        error: 'Test error',
        stackTrace: stackTrace,
        data: data,
        timestamp: timestamp,
      );

      final json = originalEntry.toJson();
      final recreatedEntry = LogEntry.fromJson(json);

      expect(recreatedEntry.level, equals(originalEntry.level));
      expect(recreatedEntry.message, equals(originalEntry.message));
      expect(recreatedEntry.operation, equals(originalEntry.operation));
      expect(recreatedEntry.error, equals(originalEntry.error));
      expect(recreatedEntry.data, equals(originalEntry.data));
      expect(recreatedEntry.timestamp, equals(originalEntry.timestamp));
    });

    test('should have correct toString implementation', () {
      final timestamp = DateTime.parse('2022-01-01T12:00:00.000Z');
      
      final logEntry = LogEntry(
        level: LogLevel.info,
        message: 'Test message',
        operation: 'Test Operation',
        timestamp: timestamp,
      );

      expect(logEntry.toString(), equals(logEntry.formattedMessage));
    });
  });
}

// Helper constant for tests
const timestamp = Duration(milliseconds: 1640995200000); // 2022-01-01 00:00:00
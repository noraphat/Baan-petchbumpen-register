import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/services/backup_error_handler.dart';
import 'package:flutter_petchbumpen_register/services/backup_exceptions.dart';

void main() {
  group('BackupErrorHandler', () {
    late BackupErrorHandler errorHandler;

    setUp(() {
      errorHandler = BackupErrorHandler.instance;
    });

    testWidgets('should show success message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    errorHandler.showSuccess(
                      context,
                      'Test success message',
                      details: 'Test details',
                    );
                  },
                  child: const Text('Show Success'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pump();

      expect(find.text('Test success message'), findsOneWidget);
      expect(find.text('Test details'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should show warning message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    errorHandler.showWarning(
                      context,
                      'Test warning message',
                      details: 'Test warning details',
                    );
                  },
                  child: const Text('Show Warning'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Warning'));
      await tester.pump();

      expect(find.text('Test warning message'), findsOneWidget);
      expect(find.text('Test warning details'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('should handle FilePermissionException correctly', (WidgetTester tester) async {
      const exception = FilePermissionException('Permission denied');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    errorHandler.handleError(context, exception);
                  },
                  child: const Text('Handle Error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Handle Error'));
      await tester.pump();

      expect(find.text('ไม่มีสิทธิ์เข้าถึงไฟล์'), findsOneWidget);
      expect(find.byIcon(Icons.folder_off), findsOneWidget);
    });

    testWidgets('should handle InvalidBackupFileException correctly', (WidgetTester tester) async {
      const exception = InvalidBackupFileException('Invalid file format');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    errorHandler.handleError(context, exception);
                  },
                  child: const Text('Handle Error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Handle Error'));
      await tester.pump();

      expect(find.text('ไฟล์สำรองข้อมูลไม่ถูกต้อง'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should handle StorageException correctly', (WidgetTester tester) async {
      const exception = StorageException('Insufficient storage');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    errorHandler.handleError(context, exception);
                  },
                  child: const Text('Handle Error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Handle Error'));
      await tester.pump();

      expect(find.text('พื้นที่เก็บข้อมูลไม่เพียงพอ'), findsOneWidget);
      expect(find.byIcon(Icons.storage), findsOneWidget);
    });

    testWidgets('should handle DatabaseBackupException correctly', (WidgetTester tester) async {
      const exception = DatabaseBackupException('Database error');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    errorHandler.handleError(context, exception);
                  },
                  child: const Text('Handle Error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Handle Error'));
      await tester.pump();

      expect(find.text('เกิดข้อผิดพลาดกับฐานข้อมูล'), findsOneWidget);
      expect(find.byIcon(Icons.storage), findsOneWidget);
    });

    testWidgets('should handle RestoreException correctly', (WidgetTester tester) async {
      const exception = RestoreException('Restore failed');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    errorHandler.handleError(context, exception);
                  },
                  child: const Text('Handle Error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Handle Error'));
      await tester.pump();

      expect(find.text('การกู้คืนข้อมูลล้มเหลว'), findsOneWidget);
      expect(find.byIcon(Icons.restore), findsOneWidget);
    });

    testWidgets('should handle generic BackupException correctly', (WidgetTester tester) async {
      const exception = BackupException('Generic backup error');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    errorHandler.handleError(context, exception);
                  },
                  child: const Text('Handle Error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Handle Error'));
      await tester.pump();

      expect(find.text('เกิดข้อผิดพลาดในการสำรองข้อมูล'), findsOneWidget);
      expect(find.byIcon(Icons.backup), findsOneWidget);
    });

    testWidgets('should handle generic exception correctly', (WidgetTester tester) async {
      final exception = Exception('Generic error');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    errorHandler.handleError(context, exception);
                  },
                  child: const Text('Handle Error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Handle Error'));
      await tester.pump();

      expect(find.text('เกิดข้อผิดพลาดที่ไม่คาดคิด'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should show retry button for retryable errors', (WidgetTester tester) async {
      bool retryPressed = false;
      const exception = FilePermissionException('Permission denied');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    errorHandler.handleError(
                      context,
                      exception,
                      onRetry: () {
                        retryPressed = true;
                      },
                    );
                  },
                  child: const Text('Handle Error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Handle Error'));
      await tester.pump();

      expect(find.text('ลองใหม่'), findsOneWidget);

      await tester.tap(find.text('ลองใหม่'));
      await tester.pump();

      expect(retryPressed, isTrue);
    });

    testWidgets('should show confirmation dialog', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await errorHandler.showConfirmationDialog(
                      context,
                      title: 'Test Confirmation',
                      message: 'Are you sure?',
                      confirmText: 'Yes',
                      cancelText: 'No',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test Confirmation'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);

      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('should return false when dialog is cancelled', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await errorHandler.showConfirmationDialog(
                      context,
                      title: 'Test Confirmation',
                      message: 'Are you sure?',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    test('should log errors correctly', () {
      const exception = BackupException('Test error');
      
      // This test verifies that logging doesn't throw exceptions
      expect(() {
        errorHandler.logError('Test operation', exception);
      }, returnsNormally);
    });

    test('should log warnings correctly', () {
      expect(() {
        errorHandler.logWarning('Test warning message');
      }, returnsNormally);
    });

    test('should log info correctly', () {
      expect(() {
        errorHandler.logInfo('Test info message');
      }, returnsNormally);
    });

    test('should log debug correctly', () {
      expect(() {
        errorHandler.logDebug('Test debug message');
      }, returnsNormally);
    });
  });

  group('ErrorInfo', () {
    test('should create ErrorInfo correctly', () {
      const errorInfo = ErrorInfo(
        title: 'Test Title',
        message: 'Test Message',
        suggestion: 'Test Suggestion',
        icon: Icons.error,
        color: Colors.red,
        isRetryable: true,
      );

      expect(errorInfo.title, equals('Test Title'));
      expect(errorInfo.message, equals('Test Message'));
      expect(errorInfo.suggestion, equals('Test Suggestion'));
      expect(errorInfo.icon, equals(Icons.error));
      expect(errorInfo.color, equals(Colors.red));
      expect(errorInfo.isRetryable, isTrue);
    });
  });
}
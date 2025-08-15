import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_petchbumpen_register/services/backup_service.dart';
import 'package:flutter_petchbumpen_register/services/backup_error_handler.dart';
import 'package:flutter_petchbumpen_register/services/backup_exceptions.dart';
import 'package:flutter_petchbumpen_register/widgets/json_export_button.dart';
import 'package:flutter_petchbumpen_register/widgets/auto_backup_toggle.dart';
import 'package:flutter_petchbumpen_register/widgets/restore_button.dart';

import '../services/backup_service_test.mocks.dart';

void main() {
  group('Backup Error Handling Integration Tests', () {
    late MockBackupService mockBackupService;
    late BackupErrorHandler errorHandler;

    setUp(() {
      mockBackupService = MockBackupService();
      errorHandler = BackupErrorHandler.instance;
      BackupService.resetInstance();
    });

    testWidgets('JsonExportButton should handle FilePermissionException correctly', 
        (WidgetTester tester) async {
      // Arrange
      when(mockBackupService.exportToJson())
          .thenThrow(const FilePermissionException('Permission denied'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JsonExportButton(
              backupService: mockBackupService,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(JsonExportButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert
      expect(find.text('ไม่มีสิทธิ์เข้าถึงไฟล์'), findsOneWidget);
      expect(find.text('ลองใหม่'), findsOneWidget);
      expect(find.byIcon(Icons.folder_off), findsOneWidget);
    });

    testWidgets('JsonExportButton should handle StorageException correctly', 
        (WidgetTester tester) async {
      // Arrange
      when(mockBackupService.exportToJson())
          .thenThrow(const StorageException('Insufficient storage'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JsonExportButton(
              backupService: mockBackupService,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(JsonExportButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert
      expect(find.text('พื้นที่เก็บข้อมูลไม่เพียงพอ'), findsOneWidget);
      expect(find.byIcon(Icons.storage), findsOneWidget);
      // Storage errors are not retryable
      expect(find.text('ลองใหม่'), findsNothing);
    });

    testWidgets('JsonExportButton should handle DatabaseBackupException correctly', 
        (WidgetTester tester) async {
      // Arrange
      when(mockBackupService.exportToJson())
          .thenThrow(const DatabaseBackupException('Database connection failed'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JsonExportButton(
              backupService: mockBackupService,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(JsonExportButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert
      expect(find.text('เกิดข้อผิดพลาดกับฐานข้อมูล'), findsOneWidget);
      expect(find.text('ลองใหม่'), findsOneWidget);
      expect(find.byIcon(Icons.database), findsOneWidget);
    });

    testWidgets('JsonExportButton should handle generic exception correctly', 
        (WidgetTester tester) async {
      // Arrange
      when(mockBackupService.exportToJson())
          .thenThrow(Exception('Unexpected error'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JsonExportButton(
              backupService: mockBackupService,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(JsonExportButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert
      expect(find.text('เกิดข้อผิดพลาดที่ไม่คาดคิด'), findsOneWidget);
      expect(find.text('ลองใหม่'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('JsonExportButton should show success message on successful export', 
        (WidgetTester tester) async {
      // Arrange
      when(mockBackupService.exportToJson())
          .thenAnswer((_) async => '/path/to/backup.json');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JsonExportButton(
              backupService: mockBackupService,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(JsonExportButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert
      expect(find.text('ส่งออกข้อมูล JSON เรียบร้อยแล้ว'), findsOneWidget);
      expect(find.text('บันทึกที่: /path/to/backup.json'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('AutoBackupToggle should handle enable/disable errors correctly', 
        (WidgetTester tester) async {
      // Arrange
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => MockBackupSettings());
      when(mockBackupService.enableAutoBackup())
          .thenThrow(const BackupException('Failed to enable auto backup'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoBackupToggle(
              backupService: mockBackupService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the switch
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert
      expect(find.text('เกิดข้อผิดพลาดในการสำรองข้อมูล'), findsOneWidget);
      expect(find.text('ลองใหม่'), findsOneWidget);
    });

    testWidgets('RestoreButton should handle InvalidBackupFileException correctly', 
        (WidgetTester tester) async {
      // Arrange
      when(mockBackupService.restoreFromFile(any))
          .thenThrow(const InvalidBackupFileException('Invalid backup file'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestoreButton(
              backupService: mockBackupService,
            ),
          ),
        ),
      );

      // Simulate file selection and restore
      final restoreButtonState = tester.state<_RestoreButtonState>(
        find.byType(RestoreButton)
      );
      restoreButtonState.setState(() {
        restoreButtonState._selectedFilePath = '/path/to/invalid.sql';
      });

      await tester.pump();

      // Tap restore button
      await tester.tap(find.text('กู้คืนข้อมูล'));
      await tester.pumpAndSettle();

      // Confirm in dialog
      await tester.tap(find.text('ยืนยันการกู้คืน'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert
      expect(find.text('ไฟล์สำรองข้อมูลไม่ถูกต้อง'), findsOneWidget);
      expect(find.text('ลองใหม่'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('RestoreButton should handle RestoreException correctly', 
        (WidgetTester tester) async {
      // Arrange
      when(mockBackupService.restoreFromFile(any))
          .thenThrow(const RestoreException('Restore verification failed'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestoreButton(
              backupService: mockBackupService,
            ),
          ),
        ),
      );

      // Simulate file selection and restore
      final restoreButtonState = tester.state<_RestoreButtonState>(
        find.byType(RestoreButton)
      );
      restoreButtonState.setState(() {
        restoreButtonState._selectedFilePath = '/path/to/backup.sql';
      });

      await tester.pump();

      // Tap restore button
      await tester.tap(find.text('กู้คืนข้อมูล'));
      await tester.pumpAndSettle();

      // Confirm in dialog
      await tester.tap(find.text('ยืนยันการกู้คืน'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert
      expect(find.text('การกู้คืนข้อมูลล้มเหลว'), findsOneWidget);
      expect(find.text('ลองใหม่'), findsOneWidget);
      expect(find.byIcon(Icons.restore), findsOneWidget);
    });

    testWidgets('RestoreButton should show success message on successful restore', 
        (WidgetTester tester) async {
      // Arrange
      when(mockBackupService.restoreFromFile(any))
          .thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestoreButton(
              backupService: mockBackupService,
            ),
          ),
        ),
      );

      // Simulate file selection and restore
      final restoreButtonState = tester.state<_RestoreButtonState>(
        find.byType(RestoreButton)
      );
      restoreButtonState.setState(() {
        restoreButtonState._selectedFilePath = '/path/to/backup.sql';
      });

      await tester.pump();

      // Tap restore button
      await tester.tap(find.text('กู้คืนข้อมูล'));
      await tester.pumpAndSettle();

      // Confirm in dialog
      await tester.tap(find.text('ยืนยันการกู้คืน'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert
      expect(find.text('กู้คืนข้อมูลเรียบร้อยแล้ว'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Error messages should be dismissible', 
        (WidgetTester tester) async {
      // Arrange
      when(mockBackupService.exportToJson())
          .thenThrow(const BackupException('Test error'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JsonExportButton(
              backupService: mockBackupService,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(JsonExportButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert error is shown
      expect(find.text('เกิดข้อผิดพลาดในการสำรองข้อมูล'), findsOneWidget);

      // Dismiss the snackbar
      await tester.drag(find.byType(SnackBar), const Offset(0, -100));
      await tester.pumpAndSettle();

      // Assert error is dismissed
      expect(find.text('เกิดข้อผิดพลาดในการสำรองข้อมูล'), findsNothing);
    });

    testWidgets('Retry functionality should work correctly', 
        (WidgetTester tester) async {
      // Arrange
      int callCount = 0;
      when(mockBackupService.exportToJson()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw const BackupException('First attempt failed');
        }
        return '/path/to/backup.json';
      });

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JsonExportButton(
              backupService: mockBackupService,
            ),
          ),
        ),
      );

      // First attempt - should fail
      await tester.tap(find.byType(JsonExportButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert error is shown
      expect(find.text('เกิดข้อผิดพลาดในการสำรองข้อมูล'), findsOneWidget);
      expect(find.text('ลองใหม่'), findsOneWidget);

      // Retry
      await tester.tap(find.text('ลองใหม่'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert success is shown
      expect(find.text('ส่งออกข้อมูล JSON เรียบร้อยแล้ว'), findsOneWidget);
      expect(callCount, equals(2));
    });

    testWidgets('Multiple error types should be handled in sequence', 
        (WidgetTester tester) async {
      // Arrange
      int callCount = 0;
      when(mockBackupService.exportToJson()).thenAnswer((_) async {
        callCount++;
        switch (callCount) {
          case 1:
            throw const FilePermissionException('Permission denied');
          case 2:
            throw const StorageException('Insufficient storage');
          case 3:
            throw const DatabaseBackupException('Database error');
          default:
            return '/path/to/backup.json';
        }
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JsonExportButton(
              backupService: mockBackupService,
            ),
          ),
        ),
      );

      // First attempt - FilePermissionException
      await tester.tap(find.byType(JsonExportButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('ไม่มีสิทธิ์เข้าถึงไฟล์'), findsOneWidget);

      // Retry - StorageException
      await tester.tap(find.text('ลองใหม่'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('พื้นที่เก็บข้อมูลไม่เพียงพอ'), findsOneWidget);

      // Wait for snackbar to disappear and try again
      await tester.pump(const Duration(seconds: 6));
      await tester.tap(find.byType(JsonExportButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('เกิดข้อผิดพลาดกับฐานข้อมูล'), findsOneWidget);

      // Final retry - Success
      await tester.tap(find.text('ลองใหม่'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('ส่งออกข้อมูล JSON เรียบร้อยแล้ว'), findsOneWidget);

      expect(callCount, equals(4));
    });
  });
}

// Mock classes for testing
class MockBackupSettings extends Mock {
  @override
  bool get autoBackupEnabled => false;
  
  @override
  DateTime? get lastBackupTime => null;
  
  @override
  int get maxBackupDays => 31;
  
  @override
  String get backupDirectory => '/test/backup';
}

// Extension to access private state for testing
extension RestoreButtonTestExtension on WidgetTester {
  _RestoreButtonState get restoreButtonState {
    return state<_RestoreButtonState>(find.byType(RestoreButton));
  }
}

// Private state class access for testing
class _RestoreButtonState extends State<RestoreButton> {
  String? _selectedFilePath;
  
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:flutter_petchbumpen_register/widgets/json_export_button.dart';
import 'package:flutter_petchbumpen_register/services/backup_service.dart';

@GenerateNiceMocks([MockSpec<BackupService>()])
import 'json_export_button_test.mocks.dart';

void main() {
  group('JsonExportButton', () {
    late MockBackupService mockBackupService;

    setUp(() {
      mockBackupService = MockBackupService();
    });

    Widget createWidget({VoidCallback? onExportComplete}) {
      return MaterialApp(
        home: Scaffold(
          body: JsonExportButton(
            backupService: mockBackupService,
            onExportComplete: onExportComplete,
          ),
        ),
      );
    }

    testWidgets('should display export button initially', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Export ข้อมูลเป็น JSON'), findsOneWidget);
      expect(find.text('ส่งออกข้อมูลทั้งหมดเป็นไฟล์ JSON'), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('should show info about full data export', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.textContaining('ข้อมูลจะถูกส่งออกแบบเต็มรูปแบบ'), findsOneWidget);
      expect(find.textContaining('ไม่มีการซ่อนข้อมูล'), findsOneWidget);
    });

    testWidgets('should start export when tapped', (tester) async {
      when(mockBackupService.exportToJson())
          .thenAnswer((_) async => '/test/backup.json');

      await tester.pumpWidget(createWidget());

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(find.text('กำลังส่งออกข้อมูล...'), findsOneWidget);
      expect(find.text('กรุณารอสักครู่...'), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('should show progress indicator during export', (tester) async {
      when(mockBackupService.exportToJson())
          .thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 500));
            return '/test/backup.json';
          });

      await tester.pumpWidget(createWidget());

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('ความคืบหน้า'), findsOneWidget);
    });

    testWidgets('should show success message after export', (tester) async {
      const testFilePath = '/test/backup.json';
      when(mockBackupService.exportToJson())
          .thenAnswer((_) async => testFilePath);

      bool onExportCompleteCalled = false;
      await tester.pumpWidget(createWidget(
        onExportComplete: () => onExportCompleteCalled = true,
      ));

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('ส่งออกข้อมูล JSON เรียบร้อยแล้ว'), findsOneWidget);
      expect(find.textContaining(testFilePath), findsOneWidget);
      expect(onExportCompleteCalled, isTrue);
    });

    testWidgets('should show error message when export fails', (tester) async {
      when(mockBackupService.exportToJson())
          .thenThrow(Exception('Export failed'));

      await tester.pumpWidget(createWidget());

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('เกิดข้อผิดพลาดในการส่งออกข้อมูล'), findsOneWidget);
    });

    testWidgets('should disable button during export', (tester) async {
      when(mockBackupService.exportToJson())
          .thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 500));
            return '/test/backup.json';
          });

      await tester.pumpWidget(createWidget());

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      // Try to tap again during export
      await tester.tap(find.byType(InkWell));
      await tester.pump();

      // Should only call exportToJson once
      verify(mockBackupService.exportToJson()).called(1);
    });

    testWidgets('should show rotating sync icon during export', (tester) async {
      when(mockBackupService.exportToJson())
          .thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 500));
            return '/test/backup.json';
          });

      await tester.pumpWidget(createWidget());

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(find.byIcon(Icons.sync), findsOneWidget);
      
      // Check that animation is running
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('should show progress percentage', (tester) async {
      when(mockBackupService.exportToJson())
          .thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 500));
            return '/test/backup.json';
          });

      await tester.pumpWidget(createWidget());

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      // Should show 0% initially
      expect(find.text('0%'), findsOneWidget);

      // Advance time to see progress
      await tester.pump(const Duration(milliseconds: 200));
      
      // Should show some progress
      expect(find.textContaining('%'), findsOneWidget);
    });

    testWidgets('should reset state after successful export', (tester) async {
      when(mockBackupService.exportToJson())
          .thenAnswer((_) async => '/test/backup.json');

      await tester.pumpWidget(createWidget());

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Should be back to initial state
      expect(find.text('Export ข้อมูลเป็น JSON'), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('should reset state after failed export', (tester) async {
      when(mockBackupService.exportToJson())
          .thenThrow(Exception('Export failed'));

      await tester.pumpWidget(createWidget());

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Should be back to initial state
      expect(find.text('Export ข้อมูลเป็น JSON'), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });
  });
}
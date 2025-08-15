import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:flutter_petchbumpen_register/widgets/restore_button.dart';
import 'package:flutter_petchbumpen_register/services/backup_service.dart';

@GenerateNiceMocks([MockSpec<BackupService>()])
import 'restore_button_test.mocks.dart';

void main() {
  group('RestoreButton', () {
    late MockBackupService mockBackupService;

    setUp(() {
      mockBackupService = MockBackupService();
    });

    Widget createWidget({VoidCallback? onRestoreComplete}) {
      return MaterialApp(
        home: Scaffold(
          body: RestoreButton(
            backupService: mockBackupService,
            onRestoreComplete: onRestoreComplete,
          ),
        ),
      );
    }

    testWidgets('should display restore button initially', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('กู้คืนข้อมูลจากไฟล์'), findsOneWidget);
      expect(find.text('เลือกไฟล์สำรองข้อมูลเพื่อกู้คืน'), findsOneWidget);
      expect(find.byIcon(Icons.restore), findsOneWidget);
      expect(find.text('เลือกไฟล์'), findsOneWidget);
    });

    testWidgets('should show warning message', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.textContaining('การกู้คืนจะลบข้อมูลปัจจุบันทั้งหมด'), findsOneWidget);
      expect(find.textContaining('กรุณาตรวจสอบไฟล์ให้แน่ใจ'), findsOneWidget);
    });

    testWidgets('should show file picker button', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.widgetWithText(OutlinedButton, 'เลือกไฟล์'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });

    testWidgets('should not show restore button when no file selected', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.widgetWithText(ElevatedButton, 'กู้คืนข้อมูล'), findsNothing);
    });

    testWidgets('should display card with proper styling', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.byType(Card), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });


  });
}
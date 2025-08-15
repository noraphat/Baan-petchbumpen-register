import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:flutter_petchbumpen_register/widgets/backup_settings_widget.dart';
import 'package:flutter_petchbumpen_register/services/backup_service.dart';
import 'package:flutter_petchbumpen_register/models/backup_settings.dart';

@GenerateNiceMocks([MockSpec<BackupService>()])
import 'backup_settings_widget_test.mocks.dart';

void main() {
  group('BackupSettingsWidget', () {
    late MockBackupService mockBackupService;
    late BackupSettings testSettings;

    setUp(() {
      mockBackupService = MockBackupService();
      testSettings = BackupSettings(
        autoBackupEnabled: true,
        lastBackupTime: DateTime(2024, 1, 15, 10, 30),
        maxBackupDays: 31,
        backupDirectory: '/test/backup/directory',
      );
    });

    Widget createWidget({VoidCallback? onSettingsChanged}) {
      return MaterialApp(
        home: Scaffold(
          body: BackupSettingsWidget(
            backupService: mockBackupService,
            onSettingsChanged: onSettingsChanged,
          ),
        ),
      );
    }

    testWidgets('should display backup settings when loaded', (tester) async {
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => testSettings);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('การตั้งค่าสำรองข้อมูล'), findsOneWidget);
      expect(find.text('สำรองข้อมูลอัตโนมัติรายวัน'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('/test/backup/directory'), findsOneWidget);
    });

    testWidgets('should show auto backup enabled state', (tester) async {
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => testSettings);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('should show auto backup disabled state', (tester) async {
      final disabledSettings = BackupSettings(
        autoBackupEnabled: false,
        lastBackupTime: null,
        maxBackupDays: 31,
        backupDirectory: '/test/backup/directory',
      );

      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => disabledSettings);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);
    });

    testWidgets('should display backup directory info', (tester) async {
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => testSettings);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('ตำแหน่งไฟล์สำรองข้อมูล'), findsOneWidget);
      expect(find.text('/test/backup/directory'), findsOneWidget);
    });

    testWidgets('should display max backup days info', (tester) async {
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => testSettings);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('31 วัน'), findsOneWidget);
    });

    testWidgets('should show error state when loading fails', (tester) async {
      when(mockBackupService.getBackupSettings())
          .thenThrow(Exception('Load failed'));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('ไม่สามารถโหลดการตั้งค่าได้'), findsOneWidget);
    });
  });
}
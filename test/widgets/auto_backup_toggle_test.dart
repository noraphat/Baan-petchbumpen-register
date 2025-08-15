import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:flutter_petchbumpen_register/widgets/auto_backup_toggle.dart';
import 'package:flutter_petchbumpen_register/services/backup_service.dart';
import 'package:flutter_petchbumpen_register/models/backup_settings.dart';

@GenerateNiceMocks([MockSpec<BackupService>()])
import 'auto_backup_toggle_test.mocks.dart';

void main() {
  group('AutoBackupToggle', () {
    late MockBackupService mockBackupService;
    late BackupSettings enabledSettings;
    late BackupSettings disabledSettings;

    setUp(() {
      mockBackupService = MockBackupService();
      enabledSettings = BackupSettings(
        autoBackupEnabled: true,
        lastBackupTime: DateTime(2024, 1, 15, 10, 30),
        maxBackupDays: 31,
        backupDirectory: '/test/backup',
      );
      disabledSettings = BackupSettings(
        autoBackupEnabled: false,
        lastBackupTime: null,
        maxBackupDays: 31,
        backupDirectory: '/test/backup',
      );
    });

    Widget createWidget({VoidCallback? onToggleChanged}) {
      return MaterialApp(
        home: Scaffold(
          body: AutoBackupToggle(
            backupService: mockBackupService,
            onToggleChanged: onToggleChanged,
          ),
        ),
      );
    }

    testWidgets('should display loading indicator initially', (tester) async {
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => Future.delayed(const Duration(seconds: 1), () => enabledSettings));

      await tester.pumpWidget(createWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display enabled state correctly', (tester) async {
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => enabledSettings);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('สำรองข้อมูลอัตโนมัติรายวัน'), findsOneWidget);
      expect(find.text('ระบบจะสำรองข้อมูลอัตโนมัติทุกวัน'), findsOneWidget);
      
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('should display disabled state correctly', (tester) async {
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => disabledSettings);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('ปิดใช้งานการสำรองข้อมูลอัตโนมัติ'), findsOneWidget);
      
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);
    });

    testWidgets('should show last backup time when enabled', (tester) async {
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => enabledSettings);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('สำรองข้อมูลล่าสุด'), findsOneWidget);
      expect(find.textContaining('วันที่แล้ว'), findsOneWidget);
      expect(find.textContaining('มกราคม'), findsOneWidget);
    });

    testWidgets('should show "never backed up" when no backup time', (tester) async {
      final settingsWithoutBackup = BackupSettings(
        autoBackupEnabled: true,
        lastBackupTime: null,
        maxBackupDays: 31,
        backupDirectory: '/test/backup',
      );

      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => settingsWithoutBackup);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('ยังไม่เคยสำรองข้อมูล'), findsOneWidget);
      expect(find.text('ระบบจะสำรองข้อมูลในครั้งถัดไป'), findsOneWidget);
    });

    testWidgets('should enable auto backup when switch is toggled on', (tester) async {
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => disabledSettings);
      when(mockBackupService.enableAutoBackup())
          .thenAnswer((_) async {});
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => enabledSettings);

      bool onToggleChangedCalled = false;
      await tester.pumpWidget(createWidget(
        onToggleChanged: () => onToggleChangedCalled = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      verify(mockBackupService.enableAutoBackup()).called(1);
      expect(onToggleChangedCalled, isTrue);
    });

    testWidgets('should disable auto backup when switch is toggled off', (tester) async {
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => enabledSettings);
      when(mockBackupService.disableAutoBackup())
          .thenAnswer((_) async {});
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => disabledSettings);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      verify(mockBackupService.disableAutoBackup()).called(1);
    });

    testWidgets('should show success message when enabling auto backup', (tester) async {
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => disabledSettings);
      when(mockBackupService.enableAutoBackup())
          .thenAnswer((_) async {});
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => enabledSettings);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('เปิดใช้งานสำรองข้อมูลอัตโนมัติแล้ว'), findsOneWidget);
    });

    testWidgets('should show success message when disabling auto backup', (tester) async {
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => enabledSettings);
      when(mockBackupService.disableAutoBackup())
          .thenAnswer((_) async {});
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => disabledSettings);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('ปิดใช้งานสำรองข้อมูลอัตโนมัติแล้ว'), findsOneWidget);
    });

    testWidgets('should show error message when toggle fails', (tester) async {
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => disabledSettings);
      when(mockBackupService.enableAutoBackup())
          .thenThrow(Exception('Enable failed'));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('เกิดข้อผิดพลาด'), findsOneWidget);
    });

    testWidgets('should show loading indicator during toggle', (tester) async {
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => disabledSettings);
      when(mockBackupService.enableAutoBackup())
          .thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 500));
          });
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => enabledSettings);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('should prevent multiple toggles during update', (tester) async {
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => disabledSettings);
      when(mockBackupService.enableAutoBackup())
          .thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 500));
          });
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => enabledSettings);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pump();

      // Try to tap again during update
      await tester.tap(find.byType(Switch));
      await tester.pump();

      // Should only call enableAutoBackup once
      verify(mockBackupService.enableAutoBackup()).called(1);
    });

    testWidgets('should show backup file info when enabled', (tester) async {
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => enabledSettings);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('DD.sql'), findsOneWidget);
      expect(find.textContaining('31 วัน'), findsOneWidget);
    });

    testWidgets('should format relative time correctly', (tester) async {
      // Test recent backup (minutes ago)
      final recentSettings = BackupSettings(
        autoBackupEnabled: true,
        lastBackupTime: DateTime.now().subtract(const Duration(minutes: 30)),
        maxBackupDays: 31,
        backupDirectory: '/test/backup',
      );

      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => recentSettings);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('นาทีที่แล้ว'), findsOneWidget);
    });

    testWidgets('should format detailed time correctly', (tester) async {
      when(mockBackupService.getBackupSettings())
          .thenAnswer((_) async => enabledSettings);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('15 มกราคม 2567'), findsOneWidget);
      expect(find.textContaining('10:30'), findsOneWidget);
    });
  });
}
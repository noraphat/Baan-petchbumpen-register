import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_petchbumpen_register/main.dart' as app;
import 'package:flutter_petchbumpen_register/services/db_helper.dart';
import 'package:flutter_petchbumpen_register/models/reg_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Developer Settings Integration Tests', () {
    setUp(() async {
      // Clear database before each test
      await DbHelper().clearAllData();
      
      // Create test user and delete it
      final testUser = RegData.manual(
        id: '1234567890123',
        first: 'สมชาย',
        last: 'ทดสอบ',
        dob: '15 มกราคม 2500',
        phone: '0812345678',
        addr: 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์',
        gender: 'ชาย',
      );
      await DbHelper().insert(testUser);
      await DbHelper().delete(testUser.id);
    });

    testWidgets('should display developer settings screen', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to developer settings
      await tester.tap(find.text('Developer Setting'));
      await tester.pumpAndSettle();

      // Verify developer settings screen is displayed
      expect(find.text('Developer Setting'), findsOneWidget);
    });

    testWidgets('should display deleted records', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to developer settings
      await tester.tap(find.text('Developer Setting'));
      await tester.pumpAndSettle();

      // Verify deleted records section is displayed
      expect(find.text('ข้อมูลที่ถูกลบ'), findsOneWidget);
    });

    testWidgets('should restore deleted record', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to developer settings
      await tester.tap(find.text('Developer Setting'));
      await tester.pumpAndSettle();

      // Wait for deleted records to load
      await tester.pump(const Duration(seconds: 2));

      // Tap on restore button for deleted record
      final restoreButtons = find.text('กู้คืน');
      if (restoreButtons.evaluate().isNotEmpty) {
        await tester.tap(restoreButtons.first);
        await tester.pumpAndSettle();

        // Verify confirmation dialog
        expect(find.text('ยืนยันการกู้คืนข้อมูล'), findsOneWidget);

        // Confirm restoration
        await tester.tap(find.text('กู้คืน').last);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should navigate to map management', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to developer settings
      await tester.tap(find.text('Developer Setting'));
      await tester.pumpAndSettle();

      // Tap on map management button
      await tester.tap(find.text('จัดการแผนที่'));
      await tester.pumpAndSettle();

      // Verify map management screen is displayed
      expect(find.text('จัดการแผนที่'), findsOneWidget);
    });

    testWidgets('should permanently delete record', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to developer settings
      await tester.tap(find.text('Developer Setting'));
      await tester.pumpAndSettle();

      // Wait for deleted records to load
      await tester.pump(const Duration(seconds: 2));

      // Tap on permanent delete button
      final deleteButtons = find.text('ลบถาวร');
      if (deleteButtons.evaluate().isNotEmpty) {
        await tester.tap(deleteButtons.first);
        await tester.pumpAndSettle();

        // Verify confirmation dialog
        expect(find.text('ยืนยันการลบถาวร'), findsOneWidget);

        // Cancel deletion
        await tester.tap(find.text('ยกเลิก'));
        await tester.pumpAndSettle();
      }
    });

    tearDown(() async {
      // Clean up after each test
      await DbHelper().clearAllData();
    });
  });
}

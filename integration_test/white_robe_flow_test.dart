import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_petchbumpen_register/main.dart' as app;
import 'package:flutter_petchbumpen_register/services/db_helper.dart';
import 'package:flutter_petchbumpen_register/models/reg_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('White Robe Distribution Flow Integration Tests', () {
    setUp(() async {
      // Clear database and create test data
      await DbHelper().clearAllData();

      // Create test user
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
    });

    testWidgets('should complete white robe distribution flow', (
      WidgetTester tester,
    ) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Tap on white robe menu
      await tester.tap(find.text('เบิกชุดขาว'));
      await tester.pumpAndSettle();

      // Simulate QR code scan by entering ID manually
      await tester.enterText(
        find.byKey(const Key('qr_input_field')),
        '1234567890123',
      );

      // Tap scan/search button
      await tester.tap(find.byKey(const Key('scan_button')));
      await tester.pumpAndSettle();

      // Verify user information is displayed
      expect(find.text('สมชาย ทดสอบ'), findsOneWidget);
      expect(find.text('1234567890123'), findsOneWidget);

      // Tap approve button
      await tester.tap(find.text('อนุมัติ'));
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.textContaining('อนุมัติการเบิกชุดขาวสำเร็จ'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();
    });

    testWidgets('should handle invalid QR code', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to white robe scanner
      await tester.tap(find.text('เบิกชุดขาว'));
      await tester.pumpAndSettle();

      // Enter invalid ID
      await tester.enterText(
        find.byKey(const Key('qr_input_field')),
        '9999999999999',
      );

      await tester.tap(find.byKey(const Key('scan_button')));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.textContaining('ไม่พบข้อมูล'), findsOneWidget);

      // Close error dialog
      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();
    });

    testWidgets('should validate Thai National ID format', (
      WidgetTester tester,
    ) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to white robe scanner
      await tester.tap(find.text('เบิกชุดขาว'));
      await tester.pumpAndSettle();

      // Enter invalid format ID
      await tester.enterText(
        find.byKey(const Key('qr_input_field')),
        '123456789',
      );

      await tester.tap(find.byKey(const Key('scan_button')));
      await tester.pumpAndSettle();

      // Verify validation error
      expect(
        find.textContaining('รูปแบบหมายเลขบัตรประชาชนไม่ถูกต้อง'),
        findsOneWidget,
      );
    });

    testWidgets('should handle camera permission and QR scanning', (
      WidgetTester tester,
    ) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to white robe scanner
      await tester.tap(find.text('เบิกชุดขาว'));
      await tester.pumpAndSettle();

      // Tap QR scan button (camera)
      await tester.tap(find.byKey(const Key('camera_scan_button')));
      await tester.pumpAndSettle();

      // Verify camera view is displayed or permission dialog
      expect(find.textContaining('Camera permission'), findsOneWidget);
    });

    testWidgets('should display user history after approval', (
      WidgetTester tester,
    ) async {
      // Create additional info for test user
      final additionalInfo = RegAdditionalInfo.create(
        regId: '1234567890123',
        shirtCount: 2,
        pantsCount: 1,
        matCount: 1,
        pillowCount: 1,
        blanketCount: 1,
      );
      await DbHelper().insertAdditionalInfo(additionalInfo);

      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate and scan
      await tester.tap(find.text('เบิกชุดขาว'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('qr_input_field')),
        '1234567890123',
      );
      await tester.tap(find.byKey(const Key('scan_button')));
      await tester.pumpAndSettle();

      // Verify equipment information is displayed
      expect(find.textContaining('เสื้อ: 2'), findsOneWidget);
      expect(find.textContaining('กางเกง: 1'), findsOneWidget);
      expect(find.textContaining('เสื่อ: 1'), findsOneWidget);
    });

    testWidgets('should handle multiple scan attempts', (
      WidgetTester tester,
    ) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to scanner
      await tester.tap(find.text('เบิกชุดขาว'));
      await tester.pumpAndSettle();

      // First scan - valid ID
      await tester.enterText(
        find.byKey(const Key('qr_input_field')),
        '1234567890123',
      );
      await tester.tap(find.byKey(const Key('scan_button')));
      await tester.pumpAndSettle();

      // Approve
      await tester.tap(find.text('อนุมัติ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();

      // Clear field for next scan
      await tester.enterText(find.byKey(const Key('qr_input_field')), '');

      // Second scan - same ID (should still work)
      await tester.enterText(
        find.byKey(const Key('qr_input_field')),
        '1234567890123',
      );
      await tester.tap(find.byKey(const Key('scan_button')));
      await tester.pumpAndSettle();

      // Verify user is found again
      expect(find.text('สมชาย ทดสอบ'), findsOneWidget);
    });

    tearDown(() async {
      // Clean up after each test
      await DbHelper().clearAllData();
    });
  });
}

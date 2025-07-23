import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_petchbumpen_register/main.dart' as app;
import 'package:flutter_petchbumpen_register/services/db_helper.dart';
import 'package:flutter_petchbumpen_register/models/reg_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Registration Flow Integration Tests', () {
    setUp(() async {
      // Clear database before each test
      await DbHelper().clearAllData();
    });

    testWidgets('should complete manual registration flow', (
      WidgetTester tester,
    ) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Tap on registration menu
      await tester.tap(find.text('ลงทะเบียน'));
      await tester.pumpAndSettle();

      // Tap on manual form
      await tester.tap(find.text('กรอกเอง'));
      await tester.pumpAndSettle();

      // Fill in Thai National ID
      await tester.enterText(
        find.byKey(const Key('id_search_field')),
        '1234567890123',
      );
      await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
      await tester.pumpAndSettle();

      // Fill in personal information
      await tester.enterText(
        find.byKey(const Key('first_name_field')),
        'สมชาย',
      );
      await tester.enterText(find.byKey(const Key('last_name_field')), 'ใจดี');
      await tester.enterText(
        find.byKey(const Key('phone_field')),
        '0812345678',
      );

      // Select date of birth
      await tester.tap(find.byKey(const Key('dob_field')));
      await tester.pumpAndSettle();

      // Select a date from Buddhist calendar
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      // Select province
      await tester.tap(find.byKey(const Key('province_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('กรุงเทพมหานคร').last);
      await tester.pumpAndSettle();

      // Select district
      await tester.tap(find.byKey(const Key('district_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('บางรัก').last);
      await tester.pumpAndSettle();

      // Select sub-district
      await tester.tap(find.byKey(const Key('subdistrict_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('สุริยวงศ์').last);
      await tester.pumpAndSettle();

      // Fill additional address
      await tester.enterText(
        find.byKey(const Key('additional_address_field')),
        '123 ถนนสีลม',
      );

      // Submit form
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      // Fill additional information dialog
      await tester.tap(find.text('15')); // Select start date
      await tester.pumpAndSettle();

      await tester.tap(find.text('17')); // Select end date
      await tester.pumpAndSettle();

      // Add equipment
      await tester.tap(find.byIcon(Icons.add).first); // Add shirt
      await tester.tap(find.byIcon(Icons.add)); // Add pants

      // Save additional info
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      // Verify success
      expect(find.textContaining('บันทึกสำเร็จ'), findsOneWidget);
    });

    testWidgets('should handle existing user registration', (
      WidgetTester tester,
    ) async {
      // Pre-populate database with test user
      final testUser = RegData.manual(
        id: '1234567890123',
        first: 'สมหญิง',
        last: 'ใจดี',
        dob: '15 มกราคม 2500',
        phone: '0898765432',
        addr: 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์, 456 ถนนสาทร',
        gender: 'หญิง',
      );
      await DbHelper().insert(testUser);

      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to manual form
      await tester.tap(find.text('ลงทะเบียน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('กรอกเอง'));
      await tester.pumpAndSettle();

      // Search for existing user
      await tester.enterText(
        find.byKey(const Key('id_search_field')),
        '1234567890123',
      );
      await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
      await tester.pumpAndSettle();

      // Verify user data is loaded
      expect(find.text('สมหญิง'), findsOneWidget);
      expect(find.text('ใจดี'), findsOneWidget);
      expect(find.text('0898765432'), findsOneWidget);

      // Verify fields are disabled (except phone)
      final firstNameField = tester.widget<TextFormField>(
        find.byKey(const Key('first_name_field')),
      );
      expect(firstNameField.enabled, isFalse);

      // Phone field should be editable
      final phoneField = tester.widget<TextFormField>(
        find.byKey(const Key('phone_field')),
      );
      expect(phoneField.enabled, isTrue);

      // Update phone number
      await tester.enterText(
        find.byKey(const Key('phone_field')),
        '0887654321',
      );

      // Submit
      await tester.tap(find.text('ลงทะเบียน'));
      await tester.pumpAndSettle();

      // Verify additional info dialog appears
      expect(find.text('แก้ไขข้อมูลการเข้าพัก'), findsOneWidget);
    });

    testWidgets('should validate Thai National ID correctly', (
      WidgetTester tester,
    ) async {
      // Launch app and navigate to manual form
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('ลงทะเบียน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('กรอกเอง'));
      await tester.pumpAndSettle();

      // Enter invalid ID
      await tester.enterText(
        find.byKey(const Key('id_search_field')),
        '1234567890124', // Invalid checksum
      );
      await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
      await tester.pumpAndSettle();

      // Wait for validation message
      await tester.pump(const Duration(seconds: 3));

      // Verify error message appears
      expect(
        find.text('โปรดตรวจสอบหมายเลขบัตรประชาชนอีกครั้ง'),
        findsOneWidget,
      );

      // Verify dialog appears
      expect(find.text('หมายเลขบัตรประชาชนไม่ถูกต้อง'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();
    });

    testWidgets('should handle form validation correctly', (
      WidgetTester tester,
    ) async {
      // Launch app and navigate to manual form
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('ลงทะเบียน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('กรอกเอง'));
      await tester.pumpAndSettle();

      // Enter valid ID for new user
      await tester.enterText(
        find.byKey(const Key('id_search_field')),
        '1234567890123',
      );
      await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
      await tester.pumpAndSettle();

      // Try to submit without filling required fields
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      // Verify validation messages
      expect(find.text('ระบุ ชื่อ'), findsOneWidget);
      expect(find.text('ระบุ นามสกุล'), findsOneWidget);
    });

    tearDown(() async {
      // Clean up after each test
      await DbHelper().clearAllData();
    });
  });
}

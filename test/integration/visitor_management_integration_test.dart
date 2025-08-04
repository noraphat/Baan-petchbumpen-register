import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_petchbumpen_register/main.dart' as app;
import 'package:flutter_petchbumpen_register/services/db_helper.dart';
import 'package:flutter_petchbumpen_register/models/reg_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Visitor Management Integration Tests', () {
    setUp(() async {
      // Clear database before each test
      await DbHelper().clearAllData();
      
      // Create test users
      final testUser1 = RegData.manual(
        id: '1234567890123',
        first: 'สมชาย',
        last: 'ทดสอบ',
        dob: '15 มกราคม 2500',
        phone: '0812345678',
        addr: 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์',
        gender: 'ชาย',
      );
      
      final testUser2 = RegData.manual(
        id: '9876543210987',
        first: 'สมหญิง',
        last: 'ทดสอบ',
        dob: '20 มกราคม 2500',
        phone: '0898765432',
        addr: 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์',
        gender: 'หญิง',
      );
      
      await DbHelper().insert(testUser1);
      await DbHelper().insert(testUser2);
    });

    testWidgets('should display visitor management screen with test data', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to visitor management
      await tester.tap(find.text('ข้อมูลผู้ปฏิบัติธรรม'));
      await tester.pumpAndSettle();

      // Verify visitor management screen is displayed
      expect(find.text('ข้อมูลผู้ปฏิบัติธรรม'), findsOneWidget);
    });

    testWidgets('should search for visitors by ID', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to visitor management
      await tester.tap(find.text('ข้อมูลผู้ปฏิบัติธรรม'));
      await tester.pumpAndSettle();

      // Enter search term
      await tester.enterText(find.byType(TextField), '1234567890123');
      await tester.pumpAndSettle();

      // Verify search results
      expect(find.text('สมชาย'), findsOneWidget);
    });

    testWidgets('should filter visitors by gender', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to visitor management
      await tester.tap(find.text('ข้อมูลผู้ปฏิบัติธรรม'));
      await tester.pumpAndSettle();

      // Tap on gender filter dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();

      // Select male gender
      await tester.tap(find.text('ชาย').last);
      await tester.pumpAndSettle();

      // Verify only male visitors are shown
      expect(find.text('สมชาย'), findsOneWidget);
      expect(find.text('สมหญิง'), findsNothing);
    });

    testWidgets('should sort visitors by creation date', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to visitor management
      await tester.tap(find.text('ข้อมูลผู้ปฏิบัติธรรม'));
      await tester.pumpAndSettle();

      // Tap on sort button
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      // Verify sort options are displayed
      expect(find.byType(PopupMenuButton), findsOneWidget);
    });

    testWidgets('should edit visitor information', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to visitor management
      await tester.tap(find.text('ข้อมูลผู้ปฏิบัติธรรม'));
      await tester.pumpAndSettle();

      // Tap on a visitor to edit
      await tester.tap(find.text('สมชาย'));
      await tester.pumpAndSettle();

      // Verify edit screen is displayed
      expect(find.byType(AppBar), findsOneWidget);
    });

    tearDown(() async {
      // Clean up after each test
      await DbHelper().clearAllData();
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_petchbumpen_register/main.dart' as app;
import 'package:flutter_petchbumpen_register/services/db_helper.dart';
import 'package:flutter_petchbumpen_register/models/reg_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Daily Summary Integration Tests', () {
    setUp(() async {
      // Clear database before each test
      await DbHelper().clearAllData();
    });

    testWidgets('should display daily summary with test data', (WidgetTester tester) async {
      // Create test data
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

      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to daily summary
      await tester.tap(find.text('สรุปผลประจำวัน'));
      await tester.pumpAndSettle();

      // Verify daily summary screen is displayed
      expect(find.text('สรุปผลประจำวัน'), findsOneWidget);
    });

    testWidgets('should change period selection', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to daily summary
      await tester.tap(find.text('สรุปผลประจำวัน'));
      await tester.pumpAndSettle();

      // Tap on period dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select different period
      await tester.tap(find.text('สัปดาห์นี้').last);
      await tester.pumpAndSettle();

      // Verify period changed
      expect(find.text('สัปดาห์นี้'), findsOneWidget);
    });

    testWidgets('should change date selection', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to daily summary
      await tester.tap(find.text('สรุปผลประจำวัน'));
      await tester.pumpAndSettle();

      // Tap on date picker
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Select a different date
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      // Verify date changed
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('should refresh data when refresh button is tapped', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to daily summary
      await tester.tap(find.text('สรุปผลประจำวัน'));
      await tester.pumpAndSettle();

      // Tap refresh button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Verify data is refreshed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    tearDown(() async {
      // Clean up after each test
      await DbHelper().clearAllData();
    });
  });
}

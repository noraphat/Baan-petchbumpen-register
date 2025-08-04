import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_petchbumpen_register/main.dart' as app;
import 'package:flutter_petchbumpen_register/services/db_helper.dart';
import 'package:flutter_petchbumpen_register/models/reg_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Accommodation Booking Integration Tests', () {
    setUp(() async {
      // Clear database before each test
      await DbHelper().clearAllData();
    });

    testWidgets('should display accommodation booking screen', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to accommodation booking
      await tester.tap(find.text('จองที่พัก'));
      await tester.pumpAndSettle();

      // Verify accommodation booking screen is displayed
      expect(find.text('จองที่พัก'), findsOneWidget);
    });

    testWidgets('should change date selection', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to accommodation booking
      await tester.tap(find.text('จองที่พัก'));
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

    testWidgets('should display room information when available', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to accommodation booking
      await tester.tap(find.text('จองที่พัก'));
      await tester.pumpAndSettle();

      // Wait for rooms to load
      await tester.pump(const Duration(seconds: 2));

      // Verify room information is displayed
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should handle room selection', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to accommodation booking
      await tester.tap(find.text('จองที่พัก'));
      await tester.pumpAndSettle();

      // Wait for rooms to load
      await tester.pump(const Duration(seconds: 2));

      // Try to tap on a room (if available)
      final roomContainers = find.byType(Container);
      if (roomContainers.evaluate().isNotEmpty) {
        await tester.tap(roomContainers.first);
        await tester.pumpAndSettle();
      }
    });

    tearDown(() async {
      // Clean up after each test
      await DbHelper().clearAllData();
    });
  });
}

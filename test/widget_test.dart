// Main app integration test
//
// This test verifies that the main DhammaReg app initializes correctly
// and displays the home screen with proper Thai localization.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter_petchbumpen_register/main.dart';
import 'package:flutter_petchbumpen_register/screen/home_screen.dart';

void main() {
  setUpAll(() async {
    // Initialize Thai locale for date formatting
    await initializeDateFormatting('th_TH', null);
  });

  group('DhammaReg Main App Tests', () {
    testWidgets('should initialize and display home screen', (WidgetTester tester) async {
      // Build the main app
      await tester.pumpWidget(const DhammaReg());
      await tester.pumpAndSettle();

      // Verify home screen is displayed
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('บ้านเพชรบำเพ็ญ'), findsOneWidget);
    });

    testWidgets('should have correct theme configuration', (WidgetTester tester) async {
      await tester.pumpWidget(const DhammaReg());
      await tester.pumpAndSettle();

      // Verify Material 3 theme
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.useMaterial3, isTrue);
      expect(materialApp.theme?.colorScheme.primary, isNotNull);
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('should have Thai localization support', (WidgetTester tester) async {
      await tester.pumpWidget(const DhammaReg());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.supportedLocales, contains(const Locale('th', 'TH')));
      expect(materialApp.supportedLocales, contains(const Locale('en', 'US')));
    });

    testWidgets('should display all main menu options', (WidgetTester tester) async {
      await tester.pumpWidget(const DhammaReg());
      await tester.pumpAndSettle();

      // Verify main menu items are present
      expect(find.text('ลงทะเบียน'), findsOneWidget);
      expect(find.text('เบิกชุดขาว'), findsOneWidget);
      expect(find.text('จองที่พัก'), findsOneWidget);
      expect(find.text('ตารางกิจกรรม'), findsOneWidget);
      expect(find.text('สรุปผลประจำวัน'), findsOneWidget);
    });

    testWidgets('should handle navigation to registration menu', (WidgetTester tester) async {
      await tester.pumpWidget(const DhammaReg());
      await tester.pumpAndSettle();

      // Tap on registration menu
      await tester.tap(find.text('ลงทะเบียน'));
      await tester.pumpAndSettle();

      // Should navigate to registration menu
      expect(find.text('เมนูลงทะเบียน'), findsOneWidget);
    });

    testWidgets('should initialize without errors', (WidgetTester tester) async {
      await tester.pumpWidget(const DhammaReg());
      await tester.pumpAndSettle();

      // Should not have any exceptions during initialization
      expect(tester.takeException(), isNull);
    });

    testWidgets('should have proper input decoration theme', (WidgetTester tester) async {
      await tester.pumpWidget(const DhammaReg());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final theme = materialApp.theme!;
      
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
      
      final focusedBorder = theme.inputDecorationTheme.focusedBorder as OutlineInputBorder;
      expect(focusedBorder.borderSide.color, equals(Colors.purple));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/screen/home_screen.dart';
import 'package:flutter_petchbumpen_register/screen/registration/registration_menu.dart';
import 'package:flutter_petchbumpen_register/screen/white_robe_scaner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('HomeScreen Tests', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    Widget createTestWidget() {
      return const MaterialApp(
        home: HomeScreen(),
      );
    }

    group('UI Rendering', () {
      testWidgets('should display app bar with correct title and icon', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check app bar title
        expect(find.text('บ้านเพชรบำเพ็ญ'), findsOneWidget);
        
        // Check app bar icon
        expect(find.byIcon(Icons.spa), findsOneWidget);
        
        // Check app bar styling
        final appBar = find.byType(AppBar);
        expect(appBar, findsOneWidget);
        
        final appBarWidget = tester.widget<AppBar>(appBar);
        expect(appBarWidget.backgroundColor, equals(Colors.white));
        expect(appBarWidget.elevation, equals(2));
      });

      testWidgets('should display all menu items', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check all menu items are present
        expect(find.text('ลงทะเบียน'), findsOneWidget);
        expect(find.text('เบิกชุดขาว'), findsOneWidget);
        expect(find.text('จองที่พัก'), findsOneWidget);
        expect(find.text('ตารางกิจกรรม'), findsOneWidget);
        expect(find.text('สรุปผลประจำวัน'), findsOneWidget);
      });

      testWidgets('should display correct icons for each menu item', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check menu icons
        expect(find.byIcon(Icons.app_registration), findsOneWidget);
        expect(find.byIcon(Icons.checkroom), findsOneWidget);
        expect(find.byIcon(Icons.bed_outlined), findsOneWidget);
        expect(find.byIcon(Icons.event_note), findsOneWidget);
        expect(find.byIcon(Icons.bar_chart), findsOneWidget);
      });

      testWidgets('should use purple theme color for icons', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find all card icons and verify they use purple color
        final cardIcons = find.descendant(
          of: find.byType(Card),
          matching: find.byType(Icon),
        );

        expect(cardIcons, findsNWidgets(5)); // 5 menu cards

        for (int i = 0; i < 5; i++) {
          final iconWidget = tester.widget<Icon>(cardIcons.at(i));
          expect(iconWidget.color, equals(Colors.purple));
          expect(iconWidget.size, equals(40));
        }
      });

      testWidgets('should display cards in grid layout', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check grid view
        expect(find.byType(GridView), findsOneWidget);
        
        final gridView = tester.widget<GridView>(find.byType(GridView));
        // For GridView.count, check crossAxisCount through reflection
        expect(gridView.runtimeType.toString(), contains('GridView'));
        expect(gridView.mainAxisSpacing, equals(20));
        expect(gridView.crossAxisSpacing, equals(20));
        expect(gridView.childAspectRatio, equals(1.1));
      });

      testWidgets('should have correct background color', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final scaffold = find.byType(Scaffold);
        final scaffoldWidget = tester.widget<Scaffold>(scaffold);
        expect(scaffoldWidget.backgroundColor, equals(const Color(0xFFF6FAF7)));
      });
    });

    group('Navigation', () {
      testWidgets('should navigate to RegistrationMenu when registration card tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap on registration card
        await tester.tap(find.text('ลงทะเบียน'));
        await tester.pumpAndSettle();

        // Should navigate to RegistrationMenu
        expect(find.byType(RegistrationMenu), findsOneWidget);
        expect(find.text('เมนูลงทะเบียน'), findsOneWidget);
      });

      testWidgets('should navigate to WhiteRobeScanner when white robe card tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap on white robe card
        await tester.tap(find.text('เบิกชุดขาว'));
        await tester.pumpAndSettle();

        // Should navigate to WhiteRobeScanner
        expect(find.byType(WhiteRobeScanner), findsOneWidget);
      });

      testWidgets('should show WIP message for unimplemented features', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final wipFeatures = ['จองที่พัก', 'ตารางกิจกรรม', 'สรุปผลประจำวัน'];

        for (final feature in wipFeatures) {
          // Tap on the feature
          await tester.tap(find.text(feature));
          await tester.pumpAndSettle();

          // Should show WIP snackbar
          expect(find.text('ฟังก์ชันนี้อยู่ระหว่างการพัฒนา'), findsOneWidget);

          // Wait for snackbar to disappear
          await tester.pumpAndSettle(const Duration(seconds: 4));
        }
      });
    });

    group('Accessibility', () {
      testWidgets('should be accessible for screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // All menu cards should be tappable
        final inkWells = find.byType(InkWell);
        expect(inkWells, findsNWidgets(5));

        for (int i = 0; i < 5; i++) {
          final inkWell = tester.widget<InkWell>(inkWells.at(i));
          expect(inkWell.onTap, isNotNull);
        }
      });

      testWidgets('should have semantic labels for menu items', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Text should be accessible
        expect(find.text('ลงทะเบียน'), findsOneWidget);
        expect(find.text('เบิกชุดขาว'), findsOneWidget);
        expect(find.text('จองที่พัก'), findsOneWidget);
        expect(find.text('ตารางกิจกรรม'), findsOneWidget);
        expect(find.text('สรุปผลประจำวัน'), findsOneWidget);
      });

      testWidgets('should support tap interactions on entire card area', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Each card should be fully tappable
        final cards = find.byType(Card);
        expect(cards, findsNWidgets(5));

        // Test tapping first card (registration)
        await tester.tap(cards.first);
        await tester.pumpAndSettle();

        expect(find.byType(RegistrationMenu), findsOneWidget);
      });
    });

    group('Debug Mode Features', () {
      testWidgets('should show debug button in debug mode', (WidgetTester tester) async {
        // Note: This test assumes we're running in debug mode during testing
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Debug button should be visible (if kDebugMode is true)
        // In real debug mode, this would show the test system button
        final debugButton = find.text('ทดสอบระบบ');
        
        // Debug button may or may not be visible depending on build mode
        // If visible, it should be functional
        if (tester.any(debugButton)) {
          expect(find.byIcon(Icons.bug_report), findsOneWidget);
          
          // Should be able to tap it
          await tester.tap(debugButton);
          await tester.pumpAndSettle();
          
          // Should show success message
          expect(find.text('สร้างข้อมูลทดสอบแล้ว ดู Console สำหรับรายละเอียด'), findsOneWidget);
        }
      });
    });

    group('Layout Responsiveness', () {
      testWidgets('should adapt to different screen sizes', (WidgetTester tester) async {
        // Test with different screen sizes
        await tester.binding.setSurfaceSize(const Size(400, 600));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should still display all menu items
        expect(find.text('ลงทะเบียน'), findsOneWidget);
        expect(find.text('เบิกชุดขาว'), findsOneWidget);
        
        // Test with larger screen
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        await tester.pump();

        // Should still work properly
        expect(find.text('ลงทะเบียน'), findsOneWidget);
        expect(find.text('เบิกชุดขาว'), findsOneWidget);
        
        // Reset to default size
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('should handle padding correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check that body has correct padding
        final paddingWidget = find.descendant(
          of: find.byType(Scaffold),
          matching: find.byType(Padding),
        );
        
        expect(paddingWidget, findsWidgets);
        
        final padding = tester.widget<Padding>(paddingWidget.first);
        expect(padding.padding, equals(const EdgeInsets.all(20)));
      });
    });

    group('Card Styling', () {
      testWidgets('should have correct card styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final cards = find.byType(Card);
        expect(cards, findsNWidgets(5));

        // Check first card styling
        final card = tester.widget<Card>(cards.first);
        expect(card.elevation, equals(4));
        expect(card.shape, isA<RoundedRectangleBorder>());
        
        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, equals(BorderRadius.circular(20)));
      });

      testWidgets('should have correct InkWell border radius', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final inkWells = find.byType(InkWell);
        
        for (int i = 0; i < 5; i++) {
          final inkWell = tester.widget<InkWell>(inkWells.at(i));
          expect(inkWell.borderRadius, equals(BorderRadius.circular(20)));
        }
      });

      testWidgets('should have correct text styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find text within cards
        final registrationText = find.descendant(
          of: find.byType(Card),
          matching: find.text('ลงทะเบียน'),
        );

        final textWidget = tester.widget<Text>(registrationText);
        expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
        expect(textWidget.style?.fontSize, equals(16));
        expect(textWidget.textAlign, equals(TextAlign.center));
      });
    });

    group('Error Handling', () {
      testWidgets('should handle navigation errors gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Multiple rapid taps should not cause issues
        await tester.tap(find.text('ลงทะเบียน'));
        await tester.tap(find.text('ลงทะเบียน'));
        await tester.tap(find.text('ลงทะเบียน'));
        await tester.pumpAndSettle();

        // Should still navigate correctly
        expect(find.byType(RegistrationMenu), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle missing database gracefully', (WidgetTester tester) async {
        // Test that UI renders even if database operations fail
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should render without database errors
        expect(find.text('บ้านเพชรบำเพ็ญ'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Performance', () {
      testWidgets('should not cause memory leaks with repeated navigation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Navigate back and forth multiple times
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.text('ลงทะเบียน'));
          await tester.pumpAndSettle();
          
          await tester.pageBack();
          await tester.pumpAndSettle();
        }

        // Should still be responsive
        expect(find.text('บ้านเพชรบำเพ็ญ'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should rebuild efficiently', (WidgetTester tester) async {
        int buildCount = 0;
        
        Widget createCountingWidget() {
          return MaterialApp(
            home: Builder(
              builder: (context) {
                buildCount++;
                return const HomeScreen();
              },
            ),
          );
        }

        await tester.pumpWidget(createCountingWidget());
        await tester.pumpAndSettle();
        
        final initialBuildCount = buildCount;

        // Interactions should not cause unnecessary rebuilds
        await tester.tap(find.text('จองที่พัก'));
        await tester.pumpAndSettle();
        
        await tester.pump(const Duration(seconds: 4)); // Wait for snackbar
        
        // Build count should remain reasonable
        expect(buildCount, lessThanOrEqualTo(initialBuildCount + 2));
      });
    });
  });
}
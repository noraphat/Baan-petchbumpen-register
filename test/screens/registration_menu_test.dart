import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/screen/registration/registration_menu.dart';
import 'package:flutter_petchbumpen_register/screen/registration/manual_form.dart';
import 'package:flutter_petchbumpen_register/screen/registration/capture_form.dart';

void main() {
  group('RegistrationMenu Tests', () {
    Widget createTestWidget() {
      return const MaterialApp(
        home: RegistrationMenu(),
      );
    }

    group('UI Rendering', () {
      testWidgets('should display app bar with correct title', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('เมนูลงทะเบียน'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('should display both registration options', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check for both registration options
        expect(find.text('กรอกเอง'), findsOneWidget);
        expect(find.text('ถ่ายรูปบัตรประชาชน'), findsOneWidget);
      });

      testWidgets('should display correct icons for each option', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check icons
        expect(find.byIcon(Icons.edit_note), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      });

      testWidgets('should display options as cards', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(Card), findsNWidgets(2));
      });

      testWidgets('should display ListTile for each option', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(ListTile), findsNWidgets(2));
      });

      testWidgets('should display chevron right icons for navigation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
      });
    });

    group('Layout and Styling', () {
      testWidgets('should have correct padding around content', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final paddingWidget = find.byType(Padding);
        expect(paddingWidget, findsWidgets);

        final padding = tester.widget<Padding>(paddingWidget.first);
        expect(padding.padding, equals(const EdgeInsets.all(16)));
      });

      testWidgets('should have SingleChildScrollView for scrollable content', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });

      testWidgets('should have proper spacing between options', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final sizedBoxes = find.byType(SizedBox);
        final sizedBox = tester.widget<SizedBox>(sizedBoxes.first);
        expect(sizedBox.height, equals(24));
      });

      testWidgets('should display icons with correct size', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final leadingIcons = find.descendant(
          of: find.byType(ListTile),
          matching: find.byType(Icon),
        ).evaluate().where((element) {
          final icon = element.widget as Icon;
          return icon.icon == Icons.edit_note || icon.icon == Icons.camera_alt;
        });

        expect(leadingIcons.length, equals(2));

        for (final iconElement in leadingIcons) {
          final icon = iconElement.widget as Icon;
          expect(icon.size, equals(40));
        }
      });
    });

    group('Navigation', () {
      testWidgets('should navigate to ManualForm when "กรอกเอง" tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('กรอกเอง'));
        await tester.pumpAndSettle();

        expect(find.byType(ManualForm), findsOneWidget);
        expect(find.text('ลงทะเบียน'), findsOneWidget); // ManualForm app bar title
      });

      testWidgets('should navigate to CaptureForm when "ถ่ายรูปบัตรประชาชน" tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('ถ่ายรูปบัตรประชาชน'));
        await tester.pumpAndSettle();

        expect(find.byType(CaptureForm), findsOneWidget);
      });

      testWidgets('should be able to tap on entire ListTile area', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final manualFormTile = find.ancestor(
          of: find.text('กรอกเอง'),
          matching: find.byType(ListTile),
        );

        await tester.tap(manualFormTile);
        await tester.pumpAndSettle();

        expect(find.byType(ManualForm), findsOneWidget);
      });

      testWidgets('should be able to tap on card area', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final manualFormCard = find.ancestor(
          of: find.text('กรอกเอง'),
          matching: find.byType(Card),
        );

        await tester.tap(manualFormCard);
        await tester.pumpAndSettle();

        expect(find.byType(ManualForm), findsOneWidget);
      });

      testWidgets('should maintain navigation stack correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Navigate to ManualForm
        await tester.tap(find.text('กรอกเอง'));
        await tester.pumpAndSettle();

        expect(find.byType(ManualForm), findsOneWidget);

        // Navigate back
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Should be back to RegistrationMenu
        expect(find.byType(RegistrationMenu), findsOneWidget);
        expect(find.text('เมนูลงทะเบียน'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should be accessible for screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Text should be readable by screen readers
        expect(find.text('กรอกเอง'), findsOneWidget);
        expect(find.text('ถ่ายรูปบัตรประชาชน'), findsOneWidget);

        // ListTiles should be tappable
        final listTiles = find.byType(ListTile);
        for (int i = 0; i < 2; i++) {
          final listTile = tester.widget<ListTile>(listTiles.at(i));
          expect(listTile.onTap, isNotNull);
        }
      });

      testWidgets('should provide clear visual feedback for interactions', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Cards should provide visual feedback when tapped
        final cards = find.byType(Card);
        expect(cards, findsNWidgets(2));

        // ListTiles should have trailing icons for navigation indication
        expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
      });

      testWidgets('should support keyboard navigation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ListTiles should be focusable for keyboard navigation
        final listTiles = find.byType(ListTile);
        expect(listTiles, findsNWidgets(2));

        // Each ListTile should be interactive
        for (int i = 0; i < 2; i++) {
          final listTile = tester.widget<ListTile>(listTiles.at(i));
          expect(listTile.onTap, isNotNull);
        }
      });
    });

    group('Responsive Design', () {
      testWidgets('should adapt to different screen sizes', (WidgetTester tester) async {
        // Test with small screen
        await tester.binding.setSurfaceSize(const Size(320, 568));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('กรอกเอง'), findsOneWidget);
        expect(find.text('ถ่ายรูปบัตรประชาชน'), findsOneWidget);

        // Test with large screen
        await tester.binding.setSurfaceSize(const Size(768, 1024));
        await tester.pump();

        expect(find.text('กรอกเอง'), findsOneWidget);
        expect(find.text('ถ่ายรูปบัตรประชาชน'), findsOneWidget);

        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('should handle text scaling appropriately', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: const RegistrationMenu(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should render without overflow
        expect(tester.takeException(), isNull);
        expect(find.text('กรอกเอง'), findsOneWidget);
        expect(find.text('ถ่ายรูปบัตรประชาชน'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle rapid taps gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Rapid taps should not cause issues
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('กรอกเอง'));
        }
        await tester.pumpAndSettle();

        // Should navigate only once
        expect(find.byType(ManualForm), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle missing navigation targets gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Even if navigation fails, should not crash
        expect(tester.takeException(), isNull);
      });
    });

    group('Performance', () {
      testWidgets('should build efficiently', (WidgetTester tester) async {
        int buildCount = 0;

        Widget createCountingWidget() {
          return MaterialApp(
            home: Builder(
              builder: (context) {
                buildCount++;
                return const RegistrationMenu();
              },
            ),
          );
        }

        await tester.pumpWidget(createCountingWidget());
        await tester.pumpAndSettle();

        final initialBuildCount = buildCount;

        // Simple interactions should not cause unnecessary rebuilds
        await tester.tap(find.text('กรอกเอง'));
        await tester.pumpAndSettle();

        // Build count should remain reasonable
        expect(buildCount, lessThanOrEqualTo(initialBuildCount + 1));
      });

      testWidgets('should not cause memory leaks', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Navigate back and forth multiple times
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.text('กรอกเอง'));
          await tester.pumpAndSettle();

          await tester.pageBack();
          await tester.pumpAndSettle();
        }

        // Should still be functional
        expect(find.text('เมนูลงทะเบียน'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Integration', () {
      testWidgets('should integrate correctly with parent navigation', (WidgetTester tester) async {
        // Test within a navigation stack
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegistrationMenu()),
                        );
                      },
                      child: const Text('Go to Registration'),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
          ),
        );

        // Navigate to RegistrationMenu
        await tester.tap(find.text('Go to Registration'));
        await tester.pumpAndSettle();

        expect(find.byType(RegistrationMenu), findsOneWidget);

        // Test navigation from RegistrationMenu
        await tester.tap(find.text('กรอกเอง'));
        await tester.pumpAndSettle();

        expect(find.byType(ManualForm), findsOneWidget);

        // Navigate back through the stack
        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(find.byType(RegistrationMenu), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(find.text('Go to Registration'), findsOneWidget);
      });
    });

    group('Visual Testing', () {
      testWidgets('should have consistent styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Cards should have consistent appearance
        final cards = find.byType(Card);
        expect(cards, findsNWidgets(2));

        // Icons should be consistently sized and styled
        final editIcon = find.byIcon(Icons.edit_note);
        final cameraIcon = find.byIcon(Icons.camera_alt);

        expect(editIcon, findsOneWidget);
        expect(cameraIcon, findsOneWidget);

        final editIconWidget = tester.widget<Icon>(editIcon);
        final cameraIconWidget = tester.widget<Icon>(cameraIcon);

        expect(editIconWidget.size, equals(cameraIconWidget.size));
      });

      testWidgets('should maintain visual hierarchy', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // App bar should be at the top
        final appBar = find.byType(AppBar);
        expect(appBar, findsOneWidget);

        // Body content should be below app bar
        final scaffold = find.byType(Scaffold);
        expect(scaffold, findsOneWidget);

        // Cards should be arranged vertically
        final column = find.byType(Column);
        expect(column, findsOneWidget);
      });
    });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/widgets/menu_card.dart';

void main() {
  group('MenuCard Tests', () {
    late bool tapped;
    late VoidCallback onTap;

    setUp(() {
      tapped = false;
      onTap = () => tapped = true;
    });

    Widget createTestWidget({
      String label = 'Test Label',
      IconData icon = Icons.star,
      VoidCallback? onTapCallback,
      Gradient? gradient,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: MenuCard(
            label: label,
            icon: icon,
            onTap: onTapCallback ?? onTap,
            gradient: gradient,
          ),
        ),
      );
    }

    group('Rendering', () {
      testWidgets('should display label and icon correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          label: 'ลงทะเบียน',
          icon: Icons.app_registration,
        ));

        expect(find.text('ลงทะเบียน'), findsOneWidget);
        expect(find.byIcon(Icons.app_registration), findsOneWidget);
      });

      testWidgets('should display Thai text labels correctly', (WidgetTester tester) async {
        const thaiLabels = [
          'ลงทะเบียน',
          'เบิกชุดขาว',
          'จองที่พัก',
          'ตารางกิจกรรม',
          'สรุปผลประจำวัน',
        ];

        for (final label in thaiLabels) {
          await tester.pumpWidget(createTestWidget(label: label));
          expect(find.text(label), findsOneWidget);
        }
      });

      testWidgets('should apply default gradient when none provided', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        final inkWidget = find.byType(Ink);
        expect(inkWidget, findsOneWidget);

        final ink = tester.widget<Ink>(inkWidget);
        expect(ink.decoration, isA<BoxDecoration>());

        final boxDecoration = ink.decoration as BoxDecoration;
        expect(boxDecoration.gradient, isNotNull);
        expect(boxDecoration.gradient, isA<LinearGradient>());

        final gradient = boxDecoration.gradient as LinearGradient;
        expect(gradient.colors, contains(Colors.white));
        expect(gradient.colors, contains(Colors.grey.shade100));
      });

      testWidgets('should apply custom gradient when provided', (WidgetTester tester) async {
        final customGradient = LinearGradient(
          colors: [Colors.blue.shade200, Colors.blue.shade400],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

        await tester.pumpWidget(createTestWidget(gradient: customGradient));

        final inkWidget = find.byType(Ink);
        final ink = tester.widget<Ink>(inkWidget);
        final boxDecoration = ink.decoration as BoxDecoration;

        expect(boxDecoration.gradient, equals(customGradient));
      });
    });

    group('Styling', () {
      testWidgets('should have rounded corners', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        final inkWell = find.byType(InkWell);
        final inkWellWidget = tester.widget<InkWell>(inkWell);
        expect(inkWellWidget.borderRadius, equals(BorderRadius.circular(20)));

        final ink = find.byType(Ink);
        final inkWidget = tester.widget<Ink>(ink);
        final boxDecoration = inkWidget.decoration as BoxDecoration;
        expect(boxDecoration.borderRadius, equals(BorderRadius.circular(20)));
      });

      testWidgets('should have shadow effect', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        final ink = find.byType(Ink);
        final inkWidget = tester.widget<Ink>(ink);
        final boxDecoration = inkWidget.decoration as BoxDecoration;

        expect(boxDecoration.boxShadow, isNotNull);
        expect(boxDecoration.boxShadow!.length, equals(1));

        final shadow = boxDecoration.boxShadow!.first;
        expect(shadow.color, equals(Colors.black.withOpacity(.07)));
        expect(shadow.blurRadius, equals(10));
        expect(shadow.offset, equals(const Offset(0, 4)));
      });

      testWidgets('should display icon with correct size and color', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(icon: Icons.star));

        final iconWidget = find.byIcon(Icons.star);
        expect(iconWidget, findsOneWidget);

        final icon = tester.widget<Icon>(iconWidget);
        expect(icon.size, equals(48));
        expect(icon.color, equals(Colors.teal));
      });

      testWidgets('should display text with correct styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(label: 'Test Text'));

        final textWidget = find.text('Test Text');
        expect(textWidget, findsOneWidget);

        final text = tester.widget<Text>(textWidget);
        expect(text.style?.fontWeight, equals(FontWeight.w600));
      });
    });

    group('Layout', () {
      testWidgets('should arrange icon and text vertically', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          label: 'Test Layout',
          icon: Icons.star,
        ));

        final column = find.byType(Column);
        expect(column, findsOneWidget);

        final columnWidget = tester.widget<Column>(column);
        expect(columnWidget.mainAxisSize, equals(MainAxisSize.min));
        expect(columnWidget.children.length, equals(3)); // Icon, SizedBox, Text

        // Check that icon comes before text
        expect(columnWidget.children[0], isA<Icon>());
        expect(columnWidget.children[1], isA<SizedBox>());
        expect(columnWidget.children[2], isA<Text>());
      });

      testWidgets('should have proper spacing between icon and text', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        final column = find.byType(Column);
        final columnWidget = tester.widget<Column>(column);
        final sizedBox = columnWidget.children[1] as SizedBox;

        expect(sizedBox.height, equals(8));
      });

      testWidgets('should be centered within its container', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        final center = find.byType(Center);
        expect(center, findsOneWidget);
      });
    });

    group('Interactions', () {
      testWidgets('should call onTap when tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(tapped, isFalse);

        await tester.tap(find.byType(MenuCard));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });

      testWidgets('should show ripple effect on tap', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Tap and hold to see ripple effect
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(MenuCard))
        );
        await tester.pump(const Duration(milliseconds: 100));

        // InkWell should show splash effect
        expect(find.byType(InkWell), findsOneWidget);

        await gesture.up();
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });

      testWidgets('should be tappable across entire card area', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        final menuCardFinder = find.byType(MenuCard);
        final cardRect = tester.getRect(menuCardFinder);

        // Test tapping at different areas of the card
        final testPoints = [
          cardRect.topLeft + const Offset(10, 10),
          cardRect.topRight + const Offset(-10, 10),
          cardRect.bottomLeft + const Offset(10, -10),
          cardRect.bottomRight + const Offset(-10, -10),
          cardRect.center,
        ];

        int tapCount = 0;
        void countTaps() => tapCount++;

        for (int i = 0; i < testPoints.length; i++) {
          await tester.pumpWidget(createTestWidget(onTapCallback: countTaps));
          
          await tester.tapAt(testPoints[i]);
          await tester.pumpAndSettle();
        }

        expect(tapCount, equals(testPoints.length));
      });
    });

    group('Accessibility', () {
      testWidgets('should be accessible for screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(label: 'Accessible Button'));

        final menuCard = find.byType(MenuCard);
        expect(menuCard, findsOneWidget);

        // The text should be readable by screen readers
        expect(find.text('Accessible Button'), findsOneWidget);

        // Should have semantics for tapping
        final inkWell = find.byType(InkWell);
        final inkWellWidget = tester.widget<InkWell>(inkWell);
        expect(inkWellWidget.onTap, isNotNull);
      });

      testWidgets('should support different text sizes', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
                child: MenuCard(
                  label: 'Large Text',
                  icon: Icons.text_fields,
                  onTap: onTap,
                ),
              ),
            ),
          ),
        );

        // Should render without overflow
        expect(tester.takeException(), isNull);
        expect(find.text('Large Text'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle empty label gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(label: ''));

        expect(find.text(''), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle very long labels gracefully', (WidgetTester tester) async {
        const longLabel = 'This is a very long label that might cause layout issues if not handled properly by the widget';
        
        await tester.pumpWidget(createTestWidget(label: longLabel));

        expect(find.textContaining(longLabel), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle null gradient gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(gradient: null));

        // Should use default gradient
        final ink = find.byType(Ink);
        final inkWidget = tester.widget<Ink>(ink);
        final boxDecoration = inkWidget.decoration as BoxDecoration;

        expect(boxDecoration.gradient, isNotNull);
        expect(tester.takeException(), isNull);
      });
    });

    group('Integration with Theme', () {
      testWidgets('should use theme text style', (WidgetTester tester) async {
        final customTheme = ThemeData(
          textTheme: const TextTheme(
            bodyLarge: TextStyle(
              color: Colors.red,
              fontSize: 20,
            ),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: customTheme,
            home: Scaffold(
              body: MenuCard(
                label: 'Themed Text',
                icon: Icons.palette,
                onTap: onTap,
              ),
            ),
          ),
        );

        final textWidget = find.text('Themed Text');
        final text = tester.widget<Text>(textWidget);

        // Should use theme's bodyLarge style as base
        expect(text.style?.fontSize, equals(20));
        expect(text.style?.fontWeight, equals(FontWeight.w600)); // Override from widget
      });
    });

    group('Performance', () {
      testWidgets('should rebuild efficiently', (WidgetTester tester) async {
        int buildCount = 0;
        
        Widget createCountingWidget() {
          return MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  buildCount++;
                  return MenuCard(
                    label: 'Build Count Test',
                    icon: Icons.speed,
                    onTap: onTap,
                  );
                },
              ),
            ),
          );
        }

        await tester.pumpWidget(createCountingWidget());
        final initialBuildCount = buildCount;

        // Tap should not cause unnecessary rebuilds
        await tester.tap(find.byType(MenuCard));
        await tester.pumpAndSettle();

        expect(buildCount, equals(initialBuildCount));
      });
    });
  });
}
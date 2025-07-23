import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/screen/home_screen.dart';
import 'package:flutter_petchbumpen_register/widgets/menu_card.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('should display app title and menu cards', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Assert
      expect(find.text('บ้านเพชรบำเพ็ญ'), findsOneWidget);
      expect(find.text('สถานปฏิบัติธรรม'), findsOneWidget);
      expect(find.byType(MenuCard), findsAtLeastNWidgets(4)); // Main menu cards
    });

    testWidgets('should display registration menu card', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Assert
      expect(find.text('ลงทะเบียน'), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('should display white robe menu card', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Assert
      expect(find.text('เบิกชุดขาว'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    });

    testWidgets('should display daily summary menu card', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Assert
      expect(find.text('สรุปผลประจำวัน'), findsOneWidget);
      expect(find.byIcon(Icons.summarize), findsOneWidget);
    });

    testWidgets('should navigate to registration when tapped', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Find and tap registration card
      final registrationCard = find.widgetWithText(MenuCard, 'ลงทะเบียน');
      await tester.tap(registrationCard);
      await tester.pumpAndSettle();

      // Assert navigation occurred
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('should handle secret developer mode activation', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Find the logo and tap it 12 times quickly
      final logo = find.text('🏛️');
      for (int i = 0; i < 12; i++) {
        await tester.tap(logo);
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Assert toast or developer mode activation
      expect(find.textContaining('Secret Developer Mode'), findsOneWidget);
    });

    testWidgets('should be scrollable on small screens', (WidgetTester tester) async {
      // Arrange - Set small screen size
      tester.binding.window.physicalSizeTestValue = const Size(360, 640);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Assert
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      
      // Cleanup
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    });

    testWidgets('should display correct theme colors', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            primarySwatch: Colors.purple,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
          ),
          home: const HomeScreen(),
        ),
      );

      // Assert
      expect(find.byType(HomeScreen), findsOneWidget);
      
      // Check if theme is applied
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, isNotNull);
    });
  });
}
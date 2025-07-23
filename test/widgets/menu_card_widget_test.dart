import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/widgets/menu_card.dart';

void main() {
  group('MenuCard Widget Tests', () {
    testWidgets('should display title and icon correctly', (WidgetTester tester) async {
      // Arrange
      const title = 'ลงทะเบียน';
      const icon = Icons.person_add;
      const color = Colors.blue;
      bool tapped = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuCard(
              title: title,
              icon: icon,
              color: color,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(title), findsOneWidget);
      expect(find.byIcon(icon), findsOneWidget);
      
      // Test tap functionality
      await tester.tap(find.byType(MenuCard));
      expect(tapped, isTrue);
    });

    testWidgets('should handle long titles gracefully', (WidgetTester tester) async {
      // Arrange
      const longTitle = 'ลงทะเบียนผู้มาปฏิบัติธรรมและจัดการข้อมูลส่วนตัว';
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuCard(
              title: longTitle,
              icon: Icons.person,
              color: Colors.green,
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(longTitle), findsOneWidget);
    });

    testWidgets('should apply custom colors correctly', (WidgetTester tester) async {
      // Arrange
      const testColor = Colors.purple;
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuCard(
              title: 'Test',
              icon: Icons.test_outlined,
              color: testColor,
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, testColor);
    });

    testWidgets('should be accessible with semantics', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuCard(
              title: 'เบิกชุดขาว',
              icon: Icons.qr_code_scanner,
              color: Colors.orange,
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.bySemanticsLabel('เบิกชุดขาว'), findsOneWidget);
    });
  });
}
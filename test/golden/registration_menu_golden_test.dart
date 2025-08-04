import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/screen/registration/registration_menu.dart';

void main() {
  group('RegistrationMenu Golden Tests', () {
    testWidgets('registration menu golden test', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegistrationMenu()));
      
      // Wait for the widget to be fully rendered
      await tester.pumpAndSettle();
      
      // Take a screenshot for golden test comparison
      await expectLater(
        find.byType(RegistrationMenu),
        matchesGoldenFile('registration_menu_golden.png'),
      );
    });

    testWidgets('registration menu with different themes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const RegistrationMenu(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(RegistrationMenu),
        matchesGoldenFile('registration_menu_dark_theme_golden.png'),
      );
    });
  });
}

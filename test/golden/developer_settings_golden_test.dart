import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/screen/developer_settings.dart';

void main() {
  group('DeveloperSettingsScreen Golden Tests', () {
    testWidgets('developer settings golden test', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DeveloperSettingsScreen()));
      
      // Wait for the widget to be fully rendered
      await tester.pumpAndSettle();
      
      // Take a screenshot for golden test comparison
      await expectLater(
        find.byType(DeveloperSettingsScreen),
        matchesGoldenFile('developer_settings_golden.png'),
      );
    });

    testWidgets('developer settings with loading state', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DeveloperSettingsScreen()));
      
      // Don't wait for settle to capture loading state
      await tester.pump();
      
      await expectLater(
        find.byType(DeveloperSettingsScreen),
        matchesGoldenFile('developer_settings_loading_golden.png'),
      );
    });
  });
}

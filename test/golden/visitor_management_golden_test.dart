import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/screen/visitor_management.dart';

void main() {
  group('VisitorManagementScreen Golden Tests', () {
    testWidgets('visitor management golden test', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VisitorManagementScreen()));
      
      // Wait for the widget to be fully rendered
      await tester.pumpAndSettle();
      
      // Take a screenshot for golden test comparison
      await expectLater(
        find.byType(VisitorManagementScreen),
        matchesGoldenFile('visitor_management_golden.png'),
      );
    });

    testWidgets('visitor management with loading state', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VisitorManagementScreen()));
      
      // Don't wait for settle to capture loading state
      await tester.pump();
      
      await expectLater(
        find.byType(VisitorManagementScreen),
        matchesGoldenFile('visitor_management_loading_golden.png'),
      );
    });
  });
}

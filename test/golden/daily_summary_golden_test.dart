import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/screen/daily_summary.dart';

void main() {
  group('DailySummaryScreen Golden Tests', () {
    testWidgets('daily summary golden test', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailySummaryScreen()));
      
      // Wait for the widget to be fully rendered
      await tester.pumpAndSettle();
      
      // Take a screenshot for golden test comparison
      await expectLater(
        find.byType(DailySummaryScreen),
        matchesGoldenFile('daily_summary_golden.png'),
      );
    });

    testWidgets('daily summary with loading state', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailySummaryScreen()));
      
      // Don't wait for settle to capture loading state
      await tester.pump();
      
      await expectLater(
        find.byType(DailySummaryScreen),
        matchesGoldenFile('daily_summary_loading_golden.png'),
      );
    });
  });
}

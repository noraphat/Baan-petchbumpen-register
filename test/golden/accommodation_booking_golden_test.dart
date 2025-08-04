import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/screen/accommodation_booking_screen.dart';

void main() {
  group('AccommodationBookingScreen Golden Tests', () {
    testWidgets('accommodation booking golden test', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AccommodationBookingScreen()));
      
      // Wait for the widget to be fully rendered
      await tester.pumpAndSettle();
      
      // Take a screenshot for golden test comparison
      await expectLater(
        find.byType(AccommodationBookingScreen),
        matchesGoldenFile('accommodation_booking_golden.png'),
      );
    });

    testWidgets('accommodation booking with loading state', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AccommodationBookingScreen()));
      
      // Don't wait for settle to capture loading state
      await tester.pump();
      
      await expectLater(
        find.byType(AccommodationBookingScreen),
        matchesGoldenFile('accommodation_booking_loading_golden.png'),
      );
    });
  });
}

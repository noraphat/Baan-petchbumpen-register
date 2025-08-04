import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/screen/accommodation_booking_screen.dart';

void main() {
  group('AccommodationBookingScreen Unit Tests', () {
    testWidgets('should display accommodation booking screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AccommodationBookingScreen()));

      // ตรวจสอบว่ามี AppBar
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AccommodationBookingScreen()));

      // ตรวจสอบว่ามี CircularProgressIndicator เมื่อเริ่มต้น
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display date selector', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AccommodationBookingScreen()));

      // ตรวจสอบว่ามี IconButton สำหรับเลือกวันที่
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('should display map container', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AccommodationBookingScreen()));

      // ตรวจสอบว่ามี Container สำหรับแสดงแผนที่
      expect(find.byType(Container), findsWidgets);
    });
  });
}

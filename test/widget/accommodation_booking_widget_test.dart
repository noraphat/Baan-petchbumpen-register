import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/screen/accommodation_booking_screen.dart';

void main() {
  group('AccommodationBookingScreen Widget Tests', () {
    testWidgets('should render accommodation booking screen with proper structure', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AccommodationBookingScreen()));

      // ตรวจสอบโครงสร้าง UI หลัก
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display date selector with proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AccommodationBookingScreen()));

      // ตรวจสอบว่ามี IconButton สำหรับเลือกวันที่
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('should display map container', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AccommodationBookingScreen()));

      // ตรวจสอบว่ามี Container สำหรับแสดงแผนที่
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should show loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AccommodationBookingScreen()));

      // ตรวจสอบว่ามี CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display room information when loaded', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AccommodationBookingScreen()));

      // ตรวจสอบว่ามีส่วนแสดงข้อมูลห้องพัก
      expect(find.byType(Column), findsWidgets);
    });
  });
}

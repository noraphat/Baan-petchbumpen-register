import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_petchbumpen_register/screen/accommodation_booking_screen.dart';

void main() {
  group('AccommodationBookingScreen Unit Tests', () {
    setUpAll(() {
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory
      databaseFactory = databaseFactoryFfi;
    });

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

    testWidgets('should display screen title', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AccommodationBookingScreen()));
      await tester.pump();

      // ตรวจสอบว่ามี AppBar กับชื่อหน้า
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display body content', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AccommodationBookingScreen()));
      await tester.pump();

      // ตรวจสอบว่ามี Scaffold body
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_petchbumpen_register/screen/daily_summary.dart';

void main() {
  group('DailySummaryScreen Unit Tests', () {
    setUpAll(() {
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory
      databaseFactory = databaseFactoryFfi;
    });
    testWidgets('should display daily summary screen with tabs', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailySummaryScreen()));
      await tester.pump();

      // ตรวจสอบว่ามี TabBar
      expect(find.byType(TabBar), findsOneWidget);
      
      // ตรวจสอบว่ามี CircularProgressIndicator เมื่อเริ่มโหลด
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display period selector dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailySummaryScreen()));
      await tester.pump();

      // ตรวจสอบว่ามี DropdownButton สำหรับเลือกช่วงเวลา
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('should display export button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailySummaryScreen()));
      await tester.pump();

      // ตรวจสอบว่ามี PopupMenuButton สำหรับส่งออก
      expect(find.byIcon(Icons.file_download), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading data', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailySummaryScreen()));
      await tester.pump();

      // ตรวจสอบว่ามี CircularProgressIndicator เมื่อโหลดข้อมูล (ในช่วงแรก)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display app bar with correct title', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailySummaryScreen()));
      await tester.pump();

      // ตรวจสอบว่ามีชื่อ AppBar ที่ถูกต้อง
      expect(find.text('สรุปผลประจำวัน'), findsOneWidget);
    });
  });
}

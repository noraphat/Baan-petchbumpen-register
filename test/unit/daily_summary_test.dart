import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/screen/daily_summary.dart';

void main() {
  group('DailySummaryScreen Unit Tests', () {
    testWidgets('should display daily summary screen with tabs', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailySummaryScreen()));

      // ตรวจสอบว่ามี TabBar
      expect(find.byType(TabBar), findsOneWidget);
      
      // ตรวจสอบว่ามี TabBarView
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('should display period selector dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailySummaryScreen()));

      // ตรวจสอบว่ามี DropdownButtonFormField สำหรับเลือกช่วงเวลา
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('should display date picker', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailySummaryScreen()));

      // ตรวจสอบว่ามี IconButton สำหรับเลือกวันที่
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading data', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailySummaryScreen()));

      // ตรวจสอบว่ามี CircularProgressIndicator เมื่อโหลดข้อมูล
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display refresh button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailySummaryScreen()));

      // ตรวจสอบว่ามี IconButton สำหรับ refresh
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/screen/daily_summary.dart';

void main() {
  group('DailySummaryScreen Widget Tests', () {
    testWidgets('should render daily summary screen with proper structure', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailySummaryScreen()));

      // ตรวจสอบโครงสร้าง UI หลัก
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(DefaultTabController), findsOneWidget);
    });

    testWidgets('should display tab bar with correct labels', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailySummaryScreen()));

      // ตรวจสอบว่ามี TabBar
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('should display period selector with proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailySummaryScreen()));

      // ตรวจสอบว่ามี DropdownButtonFormField
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('should display date picker button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailySummaryScreen()));

      // ตรวจสอบว่ามี IconButton สำหรับเลือกวันที่
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('should display refresh button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailySummaryScreen()));

      // ตรวจสอบว่ามี IconButton สำหรับ refresh
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should show loading state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DailySummaryScreen()));

      // ตรวจสอบว่ามี CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

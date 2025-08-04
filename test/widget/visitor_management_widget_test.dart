import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/screen/visitor_management.dart';

void main() {
  group('VisitorManagementScreen Widget Tests', () {
    testWidgets('should render visitor management screen with proper structure', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VisitorManagementScreen()));

      // ตรวจสอบโครงสร้าง UI หลัก
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display search field with proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VisitorManagementScreen()));

      // ตรวจสอบว่ามี TextField สำหรับค้นหา
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should display filter dropdowns', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VisitorManagementScreen()));

      // ตรวจสอบว่ามี DropdownButtonFormField สำหรับกรองข้อมูล
      expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
    });

    testWidgets('should display visitor list', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VisitorManagementScreen()));

      // ตรวจสอบว่ามี ListView สำหรับแสดงรายชื่อผู้ปฏิบัติธรรม
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should show loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VisitorManagementScreen()));

      // ตรวจสอบว่ามี CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display sort options', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VisitorManagementScreen()));

      // ตรวจสอบว่ามีปุ่มสำหรับเรียงลำดับข้อมูล
      expect(find.byType(IconButton), findsWidgets);
    });
  });
}

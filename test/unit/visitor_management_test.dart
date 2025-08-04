import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/screen/visitor_management.dart';

void main() {
  group('VisitorManagementScreen Unit Tests', () {
    testWidgets('should display visitor management screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VisitorManagementScreen()));

      // ตรวจสอบว่ามี AppBar
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display search field', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VisitorManagementScreen()));

      // ตรวจสอบว่ามี TextField สำหรับค้นหา
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should display filter dropdowns', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VisitorManagementScreen()));

      // ตรวจสอบว่ามี DropdownButtonFormField สำหรับกรองข้อมูล
      expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
    });

    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VisitorManagementScreen()));

      // ตรวจสอบว่ามี CircularProgressIndicator เมื่อเริ่มต้น
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display visitor list', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VisitorManagementScreen()));

      // ตรวจสอบว่ามี ListView หรือ ListView.builder
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}

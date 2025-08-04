import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/screen/developer_settings.dart';

void main() {
  group('DeveloperSettingsScreen Widget Tests', () {
    testWidgets('should render developer settings screen with proper structure', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DeveloperSettingsScreen()));

      // ตรวจสอบโครงสร้าง UI หลัก
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display deleted records section', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DeveloperSettingsScreen()));

      // ตรวจสอบว่ามีส่วนแสดงข้อมูลที่ถูกลบ
      expect(find.text('ข้อมูลที่ถูกลบ'), findsOneWidget);
    });

    testWidgets('should display map management button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DeveloperSettingsScreen()));

      // ตรวจสอบว่ามีปุ่มจัดการแผนที่
      expect(find.text('จัดการแผนที่'), findsOneWidget);
    });

    testWidgets('should display deleted records list', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DeveloperSettingsScreen()));

      // ตรวจสอบว่ามี ListView สำหรับแสดงข้อมูลที่ถูกลบ
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should show loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DeveloperSettingsScreen()));

      // ตรวจสอบว่ามี CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display action buttons for deleted records', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DeveloperSettingsScreen()));

      // ตรวจสอบว่ามีปุ่มสำหรับจัดการข้อมูลที่ถูกลบ
      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });
}

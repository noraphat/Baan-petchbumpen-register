import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/screen/registration/registration_menu.dart';

void main() {
  group('RegistrationMenu Widget Tests', () {
    testWidgets('should render registration menu correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegistrationMenu()));

      // ตรวจสอบโครงสร้าง UI
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('should display both registration options with proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegistrationMenu()));

      // ตรวจสอบตัวเลือกการลงทะเบียน
      final manualOption = find.text('กรอกเอง');
      final captureOption = find.text('ถ่ายรูปบัตรประชาชน');

      expect(manualOption, findsOneWidget);
      expect(captureOption, findsOneWidget);

      // ตรวจสอบว่าตัวเลือกอยู่ใน Card
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('should have proper spacing between options', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegistrationMenu()));

      // ตรวจสอบว่ามี SizedBox สำหรับเว้นระยะ
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('should display chevron icons in list tiles', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegistrationMenu()));

      // ตรวจสอบว่ามีไอคอน chevron_right ใน ListTile
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    });

    testWidgets('should have proper padding in body', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegistrationMenu()));

      // ตรวจสอบว่ามี Padding widget
      expect(find.byType(Padding), findsOneWidget);
    });
  });
}

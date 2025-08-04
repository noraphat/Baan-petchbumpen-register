import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/screen/registration/registration_menu.dart';

void main() {
  group('RegistrationMenu Unit Tests', () {
    testWidgets('should display registration menu with two options', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegistrationMenu()));

      // ตรวจสอบว่ามีเมนู 2 ตัวเลือก
      expect(find.text('กรอกเอง'), findsOneWidget);
      expect(find.text('ถ่ายรูปบัตรประชาชน'), findsOneWidget);
      
      // ตรวจสอบไอคอน
      expect(find.byIcon(Icons.edit_note), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('should navigate to manual form when tapping กรอกเอง', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegistrationMenu()));

      // แตะที่เมนูกรอกเอง
      await tester.tap(find.text('กรอกเอง'));
      await tester.pumpAndSettle();

      // ตรวจสอบว่ามีการ navigate ไปยัง ManualForm
      expect(find.byType(ManualForm), findsOneWidget);
    });

    testWidgets('should navigate to capture form when tapping ถ่ายรูปบัตรประชาชน', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegistrationMenu()));

      // แตะที่เมนูถ่ายรูปบัตรประชาชน
      await tester.tap(find.text('ถ่ายรูปบัตรประชาชน'));
      await tester.pumpAndSettle();

      // ตรวจสอบว่ามีการ navigate ไปยัง CaptureForm
      expect(find.byType(CaptureForm), findsOneWidget);
    });

    testWidgets('should display correct app bar title', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegistrationMenu()));

      // ตรวจสอบชื่อแอปบาร์
      expect(find.text('เมนูลงทะเบียน'), findsOneWidget);
    });

    testWidgets('should have proper card styling for options', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegistrationMenu()));

      // ตรวจสอบว่ามี Card widgets
      expect(find.byType(Card), findsNWidgets(2));
      
      // ตรวจสอบว่ามี ListTile ในแต่ละ Card
      expect(find.byType(ListTile), findsNWidgets(2));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_petchbumpen_register/screen/developer_settings.dart';

void main() {
  group('DeveloperSettingsScreen Unit Tests', () {
    setUpAll(() {
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory
      databaseFactory = databaseFactoryFfi;
    });
    testWidgets('should display developer settings screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DeveloperSettingsScreen()));

      // ตรวจสอบว่ามี AppBar
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display deleted records section', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DeveloperSettingsScreen()));
      await tester.pump();

      // ตรวจสอบว่ามีส่วนแสดงข้อมูลที่ถูกลบ (ข้อความแบบเต็ม)
      expect(find.textContaining('ข้อมูลที่ถูกลบ'), findsOneWidget);
    });

    testWidgets('should display app bar title', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DeveloperSettingsScreen()));
      await tester.pump();

      // ตรวจสอบว่ามีชื่อ AppBar ที่ถูกต้อง
      expect(find.text('Developer Settings'), findsOneWidget);
    });

    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DeveloperSettingsScreen()));
      await tester.pump();

      // ตรวจสอบว่ามี CircularProgressIndicator เมื่อเริ่มต้น
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

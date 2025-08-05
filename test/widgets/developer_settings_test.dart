import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/screen/developer_settings.dart';
import 'package:flutter_petchbumpen_register/services/db_helper.dart';
import 'package:flutter_petchbumpen_register/models/reg_data.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DbHelper dbHelper;

  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DbHelper();
    await dbHelper.clearAllData();
  });

  tearDown(() async {
    await dbHelper.clearAllData();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: const DeveloperSettingsScreen(),
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
    );
  }

  group('DeveloperSettingsScreen Widget Tests', () {
    testWidgets('should display app bar with correct title and icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check app bar title
      expect(find.text('Developer Settings'), findsOneWidget);
      expect(find.byIcon(Icons.developer_mode), findsOneWidget);
    });

    testWidgets('should display header information', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check header text
      expect(find.text('🗑️ ข้อมูลที่ถูกลบ (Soft Delete)'), findsOneWidget);
      expect(find.text('รายการข้อมูลที่ผู้ใช้ลบแล้ว แต่ยังคงเก็บไว้ในฐานข้อมูล'), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Should show loading indicator before data loads
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no deleted records', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.byIcon(Icons.delete_sweep), findsOneWidget);
      expect(find.text('ไม่มีข้อมูลที่ถูกลบ'), findsOneWidget);
      expect(find.text('พบข้อมูลที่ถูกลบ 0 รายการ'), findsOneWidget);
    });

    testWidgets('should display deleted records when available', (tester) async {
      // Create test deleted record
      final testRecord = RegData.manual(
        id: '1234567890123',
        first: 'สมชาย',
        last: 'ทดสอบ',
        dob: '15 มกราคม 2530',
        phone: '0812345678',
        addr: 'กรุงเทพมหานคร',
        gender: 'ชาย',
      );
      
      // Insert and then soft delete the record
      await dbHelper.insert(testRecord);
      await dbHelper.delete(testRecord.id);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check record display
      expect(find.text('สมชาย ทดสอบ'), findsOneWidget);
      expect(find.text('ID: ${testRecord.id}'), findsOneWidget);
      expect(find.text('โทร: 0812345678'), findsOneWidget);
      expect(find.text('พบข้อมูลที่ถูกลบ 1 รายการ'), findsOneWidget);
    });

    testWidgets('should display record with ID card status', (tester) async {
      // Create test record with ID card
      final testRecord = RegData.fromIdCard(
        id: '1234567890123',
        first: 'สมหญิง',
        last: 'มีบัตร',
        dob: '20 กุมภาพันธ์ 2535',
        addr: 'นครปฐม',
        gender: 'หญิง',
      );
      
      await dbHelper.insert(testRecord);
      await dbHelper.delete(testRecord.id);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check ID card status display
      expect(find.text('มีบัตรฯ'), findsOneWidget);
      expect(find.text('สมหญิง มีบัตร'), findsOneWidget);
    });

    testWidgets('should display record without ID card status', (tester) async {
      // Create test record without ID card
      final testRecord = RegData.manual(
        id: '0987654321098',
        first: 'สมศักดิ์',
        last: 'ไม่มีบัตร',
        dob: '10 มีนาคม 2540',
        phone: '0891234567',
        addr: 'เชียงใหม่',
        gender: 'ชาย',
      );
      
      await dbHelper.insert(testRecord);
      await dbHelper.delete(testRecord.id);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check no ID card status display
      expect(find.text('ไม่มีบัตรฯ'), findsOneWidget);
      expect(find.text('สมศักดิ์ ไม่มีบัตร'), findsOneWidget);
    });

    testWidgets('should display restore and delete buttons for each record', (tester) async {
      final testRecord = RegData.manual(
        id: '1111111111111',
        first: 'ทดสอบ',
        last: 'ปุ่ม',
        dob: '1 มกราคม 2500',
        phone: '0801234567',
        addr: 'สุราษฎร์ธานี',
        gender: 'อื่น ๆ',
      );
      
      await dbHelper.insert(testRecord);
      await dbHelper.delete(testRecord.id);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check buttons are present
      expect(find.text('กู้คืน'), findsOneWidget);
      expect(find.text('ลบถาวร'), findsOneWidget);
      expect(find.byIcon(Icons.restore), findsOneWidget);
      expect(find.byIcon(Icons.delete_forever), findsOneWidget);
    });

    testWidgets('should show restore confirmation dialog when restore button tapped', (tester) async {
      final testRecord = RegData.manual(
        id: '2222222222222',
        first: 'ผู้ใช้',
        last: 'กู้คืน',
        dob: '5 พฤษภาคม 2525',
        phone: '0821234567',
        addr: 'ภูเก็ต',
        gender: 'หญิง',
      );
      
      await dbHelper.insert(testRecord);
      await dbHelper.delete(testRecord.id);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap restore button
      await tester.tap(find.text('กู้คืน'));
      await tester.pumpAndSettle();

      // Check confirmation dialog
      expect(find.text('ยืนยันการกู้คืนข้อมูล'), findsOneWidget);
      expect(find.text('ต้องการกู้คืนข้อมูลของ ผู้ใช้ กู้คืน หรือไม่?'), findsOneWidget);
      expect(find.text('ยกเลิก'), findsOneWidget);
      expect(find.text('กู้คืน'), findsNWidgets(2)); // One in list, one in dialog
    });

    testWidgets('should show permanent delete confirmation dialog when delete button tapped', (tester) async {
      final testRecord = RegData.manual(
        id: '3333333333333',
        first: 'ผู้ใช้',
        last: 'ลบถาวร',
        dob: '12 มิถุนายน 2530',
        phone: '0831234567',
        addr: 'ขอนแก่น',
        gender: 'ชาย',
      );
      
      await dbHelper.insert(testRecord);
      await dbHelper.delete(testRecord.id);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.text('ลบถาวร'));
      await tester.pumpAndSettle();

      // Check confirmation dialog
      expect(find.text('⚠️ ยืนยันการลบถาวร'), findsOneWidget);
      expect(find.text('ต้องการลบข้อมูลของ ผู้ใช้ ลบถาวร ออกจากฐานข้อมูลถาวรหรือไม่?\n\nหลังจากลบแล้วจะไม่สามารถกู้คืนได้อีก!'), findsOneWidget);
      expect(find.text('ยกเลิก'), findsOneWidget);
      expect(find.text('ลบถาวร'), findsNWidgets(2)); // One in list, one in dialog
    });

    testWidgets('should cancel restore dialog when cancel button tapped', (tester) async {
      final testRecord = RegData.manual(
        id: '4444444444444',
        first: 'ทดสอบ',
        last: 'ยกเลิก',
        dob: '30 กันยายน 2535',
        phone: '0841234567',
        addr: 'อุดรธานี',
        gender: 'หญิง',
      );
      
      await dbHelper.insert(testRecord);
      await dbHelper.delete(testRecord.id);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open restore dialog
      await tester.tap(find.text('กู้คืน'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('ยืนยันการกู้คืนข้อมูล'), findsNothing);
    });

    testWidgets('should cancel permanent delete dialog when cancel button tapped', (tester) async {
      final testRecord = RegData.manual(
        id: '5555555555555',
        first: 'ทดสอบ',
        last: 'ยกเลิกลบ',
        dob: '25 ตุลาคม 2540',
        phone: '0851234567',
        addr: 'ลำปาง',
        gender: 'ชาย',
      );
      
      await dbHelper.insert(testRecord);
      await dbHelper.delete(testRecord.id);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open delete dialog
      await tester.tap(find.text('ลบถาวร'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('⚠️ ยืนยันการลบถาวร'), findsNothing);
    });

    testWidgets('should restore record when confirmed', (tester) async {
      final testRecord = RegData.manual(
        id: '6666666666666',
        first: 'กู้คืน',
        last: 'สำเร็จ',
        dob: '15 พฤศจิกายน 2532',
        phone: '0861234567',
        addr: 'เพชรบุรี',
        gender: 'หญิง',
      );
      
      await dbHelper.insert(testRecord);
      await dbHelper.delete(testRecord.id);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open restore dialog and confirm
      await tester.tap(find.text('กู้คืน'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('กู้คืน').last); // Tap confirm button
      await tester.pumpAndSettle();

      // Should show success message
      expect(find.text('กู้คืนข้อมูลเรียบร้อยแล้ว'), findsOneWidget);
      
      // Record should no longer appear in deleted list
      expect(find.text('กู้คืน สำเร็จ'), findsNothing);
      expect(find.text('พบข้อมูลที่ถูกลบ 0 รายการ'), findsOneWidget);
    });

    testWidgets('should permanently delete record when confirmed', (tester) async {
      final testRecord = RegData.manual(
        id: '7777777777777',
        first: 'ลบ',
        last: 'ถาวร',
        dob: '8 ธันวาคม 2528',
        phone: '0871234567',
        addr: 'ตราด',
        gender: 'ชาย',
      );
      
      await dbHelper.insert(testRecord);
      await dbHelper.delete(testRecord.id);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open delete dialog and confirm
      await tester.tap(find.text('ลบถาวร'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('ลบถาวร').last); // Tap confirm button
      await tester.pumpAndSettle();

      // Should show success message
      expect(find.text('ลบข้อมูลถาวรเรียบร้อยแล้ว'), findsOneWidget);
      
      // Record should no longer appear in deleted list
      expect(find.text('ลบ ถาวร'), findsNothing);
      expect(find.text('พบข้อมูลที่ถูกลบ 0 รายการ'), findsOneWidget);
    });

    testWidgets('should display multiple deleted records', (tester) async {
      // Create multiple test records
      final records = [
        RegData.manual(
          id: '1000000000001',
          first: 'คนที่',
          last: 'หนึ่ง',
          dob: '1 มกราคม 2500',
          phone: '0801111111',
          addr: 'กรุงเทพ',
          gender: 'ชาย',
        ),
        RegData.manual(
          id: '1000000000002',
          first: 'คนที่',
          last: 'สอง',
          dob: '2 กุมภาพันธ์ 2501',
          phone: '0802222222',
          addr: 'นนทบุรี',
          gender: 'หญิง',
        ),
        RegData.fromIdCard(
          id: '1000000000003',
          first: 'คนที่',
          last: 'สาม',
          dob: '3 มีนาคม 2502',
          addr: 'ปทุมธานี',
          gender: 'อื่น ๆ',
        ),
      ];
      
      // Insert and delete all records
      for (final record in records) {
        await dbHelper.insert(record);
        await dbHelper.delete(record.id);
      }

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check all records are displayed
      expect(find.text('คนที่ หนึ่ง'), findsOneWidget);
      expect(find.text('คนที่ สอง'), findsOneWidget);
      expect(find.text('คนที่ สาม'), findsOneWidget);
      expect(find.text('พบข้อมูลที่ถูกลบ 3 รายการ'), findsOneWidget);
      
      // Check ID card status
      expect(find.text('ไม่มีบัตรฯ'), findsNWidgets(2)); // First two records
      expect(find.text('มีบัตรฯ'), findsOneWidget); // Third record
      
      // Check buttons for each record
      expect(find.text('กู้คืน'), findsNWidgets(3));
      expect(find.text('ลบถาวร'), findsNWidgets(3));
    });

    testWidgets('should scroll through long list of deleted records', (tester) async {
      // Create many test records
      final records = <RegData>[];
      for (int i = 1; i <= 20; i++) {
        final record = RegData.manual(
          id: '200000000000${i.toString().padLeft(2, '0')}',
          first: 'ทดสอบ$i',
          last: 'หมายเลข$i',
          dob: '${i % 28 + 1} มกราคม 2500',
          phone: '080000${i.toString().padLeft(4, '0')}',
          addr: 'ที่อยู่ $i',
          gender: i % 3 == 0 ? 'อื่น ๆ' : (i % 2 == 0 ? 'หญิง' : 'ชาย'),
        );
        records.add(record);
        await dbHelper.insert(record);
        await dbHelper.delete(record.id);
      }

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check initial records are visible
      expect(find.text('ทดสอบ1 หมายเลข1'), findsOneWidget);
      expect(find.text('พบข้อมูลที่ถูกลบ 20 รายการ'), findsOneWidget);
      
      // Scroll down to see more records
      await tester.dragUntilVisible(
        find.text('ทดสอบ20 หมายเลข20'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      
      // Check bottom record is now visible
      expect(find.text('ทดสอบ20 หมายเลข20'), findsOneWidget);
    });

    testWidgets('should handle empty phone number display', (tester) async {
      final testRecord = RegData.manual(
        id: '8888888888888',
        first: 'ไม่มี',
        last: 'เบอร์โทร',
        dob: '20 เมษายน 2520',
        phone: '', // Empty phone
        addr: 'ระยอง',
        gender: 'หญิง',
      );
      
      await dbHelper.insert(testRecord);
      await dbHelper.delete(testRecord.id);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check empty phone display
      expect(find.text('โทร: -'), findsOneWidget);
      expect(find.text('ไม่มี เบอร์โทร'), findsOneWidget);
    });

    testWidgets('should format Thai date correctly', (tester) async {
      final testRecord = RegData.manual(
        id: '9999999999999',
        first: 'ทดสอบ',
        last: 'วันที่',
        dob: '31 ธันวาคม 2543',
        phone: '0891111111',
        addr: 'สงขลา',
        gender: 'ชาย',
      );
      
      await dbHelper.insert(testRecord);
      await dbHelper.delete(testRecord.id);

      // Wait a bit to ensure updated_at timestamp is different
      await Future.delayed(const Duration(milliseconds: 100));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check Thai date format is displayed (should contain Thai month names)
      final deleteTimeText = find.textContaining('ลบเมื่อ:');
      expect(deleteTimeText, findsOneWidget);
      
      // Find the widget and verify it contains Thai month name
      final textWidget = tester.widget<Text>(deleteTimeText);
      final dateText = textWidget.data!;
      
      // Should contain Thai month name
      final thaiMonths = [
        'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
        'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
      ];
      
      final containsThaiMonth = thaiMonths.any((month) => dateText.contains(month));
      expect(containsThaiMonth, isTrue);
    });
  });

  group('DeveloperSettingsScreen Error Handling', () {
    testWidgets('should handle database errors gracefully', (tester) async {
      // Close database to simulate error
      final db = await dbHelper.db;
      await db.close();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should still render without crashing
      expect(find.text('Developer Settings'), findsOneWidget);
      expect(find.text('🗑️ ข้อมูลที่ถูกลบ (Soft Delete)'), findsOneWidget);
    });
  });

  group('DeveloperSettingsScreen Accessibility', () {
    testWidgets('should be accessible with screen reader', (tester) async {
      final testRecord = RegData.manual(
        id: '0000000000001',
        first: 'การเข้าถึง',
        last: 'ทดสอบ',
        dob: '1 มกราคม 2500',
        phone: '0800000001',
        addr: 'ทดสอบการเข้าถึง',
        gender: 'ชาย',
      );
      
      await dbHelper.insert(testRecord);
      await dbHelper.delete(testRecord.id);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check semantic labels are available
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(TextButton), findsAtLeastNWidgets(2));
      
      // Check button semantics
      final restoreButton = find.text('กู้คืน');
      final deleteButton = find.text('ลบถาวร');
      
      expect(restoreButton, findsOneWidget);
      expect(deleteButton, findsOneWidget);
      
      // These buttons should be tappable
      expect(tester.widget<TextButton>(find.ancestor(
        of: restoreButton,
        matching: find.byType(TextButton),
      ).first).onPressed, isNotNull);
      
      expect(tester.widget<TextButton>(find.ancestor(
        of: deleteButton,
        matching: find.byType(TextButton),
      ).first).onPressed, isNotNull);
    });
  });
}
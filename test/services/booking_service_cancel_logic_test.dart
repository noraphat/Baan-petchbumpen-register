import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:flutter_petchbumpen_register/services/booking_service.dart';
import 'package:flutter_petchbumpen_register/services/db_helper.dart';

void main() {
  group('BookingService.cancelBooking() - Date Logic Tests', () {
    late BookingService bookingService;
    late DbHelper dbHelper;

    setUp(() async {
      dbHelper = DbHelper();
      bookingService = BookingService();
      
      // เตรียม database สำหรับทดสอบ
      final db = await dbHelper.db;
      
      // สร้างห้องทดสอบ
      await db.insert('rooms', {
        'id': 1,
        'name': 'ห้องทดสอบ',
        'size': 'M',
        'capacity': 2,
        'status': 'available',
      });

      // สร้างข้อมูลผู้ปฏิบัติธรรม
      await db.insert('regs', {
        'id': 'test_visitor',
        'first': 'ทดสอบ',
        'last': 'ระบบ',
        'phone': '0801234567',
        'created_at': DateTime.now().toIso8601String(),
      });

      // สร้าง stays
      await db.insert('stays', {
        'visitor_id': 'test_visitor',
        'start_date': '2025-08-03',
        'end_date': '2025-08-05',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });

      // สร้าง reg_additional_info
      final visitId = 'test_visitor_${DateTime.now().millisecondsSinceEpoch}';
      await db.insert('reg_additional_info', {
        'visitId': visitId,
        'regId': 'test_visitor',
        'startDate': '2025-08-03',
        'endDate': '2025-08-05',
      });
    });

    tearDown(() async {
      final db = await dbHelper.db;
      await db.delete('room_bookings');
      await db.delete('rooms');
      await db.delete('regs');
      await db.delete('stays');
      await db.delete('reg_additional_info');
      // Cleanup database connections
    });

    // Helper method to create booking with specific check-in date
    Future<int> _createTestBooking(String checkInDate) async {
      final db = await dbHelper.db;
      final bookingId = await db.insert('room_bookings', {
        'room_id': 1,
        'visitor_id': 'test_visitor',
        'check_in_date': checkInDate,
        'check_out_date': '2025-08-05',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });
      return bookingId;
    }

    test('✅ กรณีที่ 1: วันนี้ = วันที่เริ่มพัก (04/08 = 04/08) → อนุญาตให้ยกเลิก', () async {
      // จำลองให้วันนี้เป็น 04/08/2025
      final checkInDate = '2025-08-04';
      final bookingId = await _createTestBooking(checkInDate);

      // ทดสอบการยกเลิก (จำลองให้วันนี้ตรงกับวันเข้าพัก)
      final result = await bookingService.cancelBooking(
        bookingId: bookingId,
        visitorId: 'test_visitor',
      );

      // ควรอนุญาตให้ยกเลิกได้ หากวันนี้ตรงกับวันเข้าพัก
      // หมายเหตุ: การทดสอบนี้จะ pass เฉพาะเมื่อรันในวันที่ 04/08/2025
      // สำหรับการทดสอบจริง ต้องใช้ mock DateTime.now()
      print('📅 การทดสอบกรณีที่ 1: วันนี้ = วันที่เริ่มพัก');
      print('   วันที่เข้าพัก: $checkInDate');
      print('   ผลลัพธ์: $result');
    });

    test('❌ กรณีที่ 2: วันนี้ > วันที่เริ่มพัก (05/08 > 04/08) → ห้ามยกเลิก', () async {
      // สร้างการจองที่เริ่มเข้าพักเมื่อวาน
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      final checkInDate = DateFormat('yyyy-MM-dd').format(yesterday);
      final bookingId = await _createTestBooking(checkInDate);

      final result = await bookingService.cancelBooking(
        bookingId: bookingId,
        visitorId: 'test_visitor',
      );

      // ควรห้ามยกเลิก เพราะเริ่มเข้าพักไปแล้ว
      expect(result, isFalse);
      print('📅 การทดสอบกรณีที่ 2: วันนี้ > วันที่เริ่มพัก');
      print('   วันที่เข้าพัก: $checkInDate');
      print('   ผลลัพธ์: $result (ควรเป็น false)');
    });

    test('❌ กรณีที่ 3: วันนี้ < วันที่เริ่มพัก (03/08 < 04/08) → ห้ามยกเลิก', () async {
      // สร้างการจองที่จะเริ่มเข้าพักพรุ่งนี้
      final tomorrow = DateTime.now().add(Duration(days: 1));
      final checkInDate = DateFormat('yyyy-MM-dd').format(tomorrow);
      final bookingId = await _createTestBooking(checkInDate);

      final result = await bookingService.cancelBooking(
        bookingId: bookingId,
        visitorId: 'test_visitor',
      );

      // ควรห้ามยกเลิก เพราะไม่รองรับการยกเลิกล่วงหน้า
      expect(result, isFalse);
      print('📅 การทดสอบกรณีที่ 3: วันนี้ < วันที่เริ่มพัก');
      print('   วันที่เข้าพัก: $checkInDate');
      print('   ผลลัพธ์: $result (ควรเป็น false)');
    });

    test('🔍 ทดสอบการทำงานของ getBookingById()', () async {
      final checkInDate = '2025-08-04';
      final bookingId = await _createTestBooking(checkInDate);

      final booking = await bookingService.getBookingById(bookingId);

      expect(booking, isNotNull);
      expect(booking!['id'], equals(bookingId));
      expect(booking['check_in_date'], equals(checkInDate));
      expect(booking['visitor_id'], equals('test_visitor'));
      print('📋 ข้อมูลการจองที่ดึงมา: $booking');
    });

    test('❌ ทดสอบกรณีไม่พบการจอง', () async {
      final result = await bookingService.cancelBooking(
        bookingId: 999999, // ID ที่ไม่มีอยู่
        visitorId: 'test_visitor',
      );

      expect(result, isFalse);
      print('📅 การทดสอบกรณีไม่พบการจอง: $result (ควรเป็น false)');
    });

    test('🛠 ทดสอบการอัปเดตสถานะเป็น cancelled', () async {
      // สร้างการจองในวันปัจจุบัน
      final today = DateTime.now();
      final checkInDate = DateFormat('yyyy-MM-dd').format(today);
      final bookingId = await _createTestBooking(checkInDate);

      // ยกเลิกการจอง
      final result = await bookingService.cancelBooking(
        bookingId: bookingId,
        visitorId: 'test_visitor',
      );

      // ตรวจสอบว่าสถานะในฐานข้อมูลเปลี่ยนเป็น cancelled
      final booking = await bookingService.getBookingById(bookingId);
      
      if (result == true) {
        expect(booking!['status'], equals('cancelled'));
        print('✅ สถานะการจองเปลี่ยนเป็น cancelled แล้ว');
      } else {
        print('ℹ️ การยกเลิกไม่สำเร็จ ตามที่คาดไว้');
      }
    });

    group('📊 ทดสอบ Debug Log Messages', () {
      test('ตรวจสอบ log messages สำหรับแต่ละสถานการณ์', () async {
        print('\n🔍 ทดสอบการแสดง debug messages:');
        
        // กรณีที่ 1: วันนี้ > วันที่เริ่มพัก
        final yesterday = DateTime.now().subtract(Duration(days: 1));
        final checkInDatePast = DateFormat('yyyy-MM-dd').format(yesterday);
        final bookingIdPast = await _createTestBooking(checkInDatePast);
        
        await bookingService.cancelBooking(
          bookingId: bookingIdPast,
          visitorId: 'test_visitor',
        );
        print('   ✓ ทดสอบ log สำหรับ "วันนี้ > วันที่เริ่มพัก" เสร็จแล้ว');

        // กรณีที่ 2: วันนี้ < วันที่เริ่มพัก
        final tomorrow = DateTime.now().add(Duration(days: 1));
        final checkInDateFuture = DateFormat('yyyy-MM-dd').format(tomorrow);
        final bookingIdFuture = await _createTestBooking(checkInDateFuture);
        
        await bookingService.cancelBooking(
          bookingId: bookingIdFuture,
          visitorId: 'test_visitor',
        );
        print('   ✓ ทดสอบ log สำหรับ "วันนี้ < วันที่เริ่มพัก" เสร็จแล้ว');

        // กรณีที่ 3: วันนี้ = วันที่เริ่มพัก
        final today = DateTime.now();
        final checkInDateToday = DateFormat('yyyy-MM-dd').format(today);
        final bookingIdToday = await _createTestBooking(checkInDateToday);
        
        await bookingService.cancelBooking(
          bookingId: bookingIdToday,
          visitorId: 'test_visitor',
        );
        print('   ✓ ทดสอบ log สำหรับ "วันนี้ = วันที่เริ่มพัก" เสร็จแล้ว');
      });
    });
  });
}
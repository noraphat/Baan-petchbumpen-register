import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import '../models/reg_data.dart';

/// Service สำหรับจัดการการจองห้องพักแยกจากการจัดการวันที่ลงทะเบียน
class BookingService {
  final DbHelper _dbHelper = DbHelper();

  /// Getter สำหรับเข้าถึง DbHelper
  DbHelper get dbHelper => _dbHelper;

  /// อัพเดตวันที่ออกของการจองห้องพัก (ไม่กระทบ reg_additional_info)
  Future<bool> updateRoomBookingCheckOut({
    required int bookingId,
    required DateTime newCheckOutDate,
    required String visitorId,
  }) async {
    try {
      debugPrint('🔧 อัพเดตการจองห้องพัก ID: $bookingId');
      debugPrint(
        '   วันที่ออกใหม่: ${DateFormat('yyyy-MM-dd').format(newCheckOutDate)}',
      );

      final db = await _dbHelper.db;
      final newCheckOutStr = DateFormat('yyyy-MM-dd').format(newCheckOutDate);

      // 1. อัพเดตเฉพาะ room_bookings table
      await db.update(
        'room_bookings',
        {'check_out_date': newCheckOutStr},
        where: 'id = ?',
        whereArgs: [bookingId],
      );

      debugPrint('✅ อัพเดต room_bookings สำเร็จ');

      // 2. ตรวจสอบว่าต้องอัพเดต stays หรือไม่
      // (เฉพาะกรณีที่ stays.end_date ตรงกับ room_bookings.check_out_date เดิม)
      final bookingResult = await db.query(
        'room_bookings',
        where: 'id = ?',
        whereArgs: [bookingId],
      );

      if (bookingResult.isNotEmpty) {
        final originalCheckOut =
            bookingResult.first['check_out_date'] as String;

        // ตรวจสอบว่ามี stays ที่ตรงกับวันที่ออกเดิมหรือไม่
        final staysResult = await db.query(
          'stays',
          where: 'visitor_id = ? AND end_date = ? AND status = ?',
          whereArgs: [visitorId, originalCheckOut, 'active'],
        );

        if (staysResult.isNotEmpty) {
          // อัพเดต stays เฉพาะกรณีที่ end_date ตรงกับ room_bookings เดิม
          await db.update(
            'stays',
            {'end_date': newCheckOutStr},
            where: 'visitor_id = ? AND end_date = ? AND status = ?',
            whereArgs: [visitorId, originalCheckOut, 'active'],
          );
          debugPrint('✅ อัพเดต stays สำเร็จ (เพราะตรงกับ room_bookings เดิม)');
        } else {
          debugPrint('ℹ️ ไม่อัพเดต stays (เพราะไม่ตรงกับ room_bookings เดิม)');
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการอัพเดตการจองห้องพัก: $e');
      return false;
    }
  }

  /// ดึงข้อมูลการจองห้องพักที่มีอยู่ (ไม่รวมการจองที่ต้องการแยกออกไป)
  Future<List<Map<String, dynamic>>> getExistingRoomBookings({
    required int roomId,
    required DateTime startDate,
    required DateTime endDate,
    int? excludeBookingId,
  }) async {
    try {
      final db = await _dbHelper.db;
      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      debugPrint('🔍 ดึงข้อมูลการจองห้องพักที่มีอยู่');
      debugPrint('   ห้อง: $roomId');
      debugPrint('   ช่วงวันที่: $startDateStr - $endDateStr');
      if (excludeBookingId != null) {
        debugPrint('   แยกการจอง ID: $excludeBookingId ออกไป');
      }

      String query = '''
        SELECT id, check_in_date, check_out_date, visitor_id, room_id
        FROM room_bookings
        WHERE room_id = ? 
          AND status != 'cancelled'
          AND (
            (check_in_date <= ? AND check_out_date >= ?) OR
            (check_in_date <= ? AND check_out_date >= ?) OR
            (check_in_date >= ? AND check_out_date <= ?)
          )
      ''';

      List<dynamic> args = [
        roomId,
        startDateStr,
        startDateStr,
        endDateStr,
        endDateStr,
        startDateStr,
        endDateStr,
      ];

      if (excludeBookingId != null) {
        query += ' AND id != ?';
        args.add(excludeBookingId);
      }

      final result = await db.rawQuery(query, args);

      debugPrint('   พบการจอง ${result.length} รายการ');
      for (final booking in result) {
        debugPrint(
          '   - ID ${booking['id']}: ${booking['check_in_date']} - ${booking['check_out_date']}',
        );
      }

      return result;
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการดึงข้อมูลการจอง: $e');
      return [];
    }
  }

  /// ตรวจสอบการขัดแย้งของการจองห้องพัก
  Future<bool> hasBookingConflict({
    required int roomId,
    required DateTime startDate,
    required DateTime endDate,
    int? excludeBookingId,
  }) async {
    final existingBookings = await getExistingRoomBookings(
      roomId: roomId,
      startDate: startDate,
      endDate: endDate,
      excludeBookingId: excludeBookingId,
    );

    return existingBookings.isNotEmpty;
  }

  /// ดึงข้อมูลช่วงเวลาปฏิบัติธรรม (reg_additional_info)
  Future<RegAdditionalInfo?> getPracticePeriod(String visitorId) async {
    try {
      // ดึงข้อมูลจาก reg_additional_info ตาม visitId
      final db = await _dbHelper.db;

      // หา visitId จาก stays table
      final staysResult = await db.query(
        'stays',
        where: 'visitor_id = ? AND status = ?',
        whereArgs: [visitorId, 'active'],
        orderBy: 'created_at DESC',
        limit: 1,
      );

      if (staysResult.isNotEmpty) {
        final stay = staysResult.first;
        final visitId =
            '${visitorId}_${DateTime.parse(stay['created_at'] as String).millisecondsSinceEpoch}';

        // ดึงข้อมูลจาก reg_additional_info
        final additionalInfoResult = await db.query(
          'reg_additional_info',
          where: 'visitId = ?',
          whereArgs: [visitId],
        );

        if (additionalInfoResult.isNotEmpty) {
          return RegAdditionalInfo.fromMap(additionalInfoResult.first);
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการดึงข้อมูลช่วงเวลาปฏิบัติธรรม: $e');
      return null;
    }
  }

  /// ตรวจสอบว่าการจองห้องพักอยู่ในช่วงเวลาปฏิบัติธรรมหรือไม่
  Future<bool> isBookingWithinPracticePeriod({
    required String visitorId,
    required DateTime bookingStartDate,
    required DateTime bookingEndDate,
  }) async {
    final practiceInfo = await getPracticePeriod(visitorId);

    if (practiceInfo == null ||
        practiceInfo.startDate == null ||
        practiceInfo.endDate == null) {
      debugPrint('⚠️ ไม่พบข้อมูลช่วงเวลาปฏิบัติธรรม');
      return false;
    }

    final practiceStart = DateTime(
      practiceInfo.startDate!.year,
      practiceInfo.startDate!.month,
      practiceInfo.startDate!.day,
    );
    final practiceEnd = DateTime(
      practiceInfo.endDate!.year,
      practiceInfo.endDate!.month,
      practiceInfo.endDate!.day,
    );
    final bookingStart = DateTime(
      bookingStartDate.year,
      bookingStartDate.month,
      bookingStartDate.day,
    );
    final bookingEnd = DateTime(
      bookingEndDate.year,
      bookingEndDate.month,
      bookingEndDate.day,
    );

    // ตรวจสอบว่าการจองอยู่ในช่วงเวลาปฏิบัติธรรม
    final isWithin =
        (bookingStart.isAtSameMomentAs(practiceStart) ||
            bookingStart.isAfter(practiceStart)) &&
        (bookingEnd.isAtSameMomentAs(practiceEnd) ||
            bookingEnd.isBefore(practiceEnd));

    debugPrint('🔍 ตรวจสอบการจองในช่วงเวลาปฏิบัติธรรม:');
    debugPrint(
      '   ช่วงเวลาปฏิบัติธรรม: ${DateFormat('yyyy-MM-dd').format(practiceStart)} - ${DateFormat('yyyy-MM-dd').format(practiceEnd)}',
    );
    debugPrint(
      '   ช่วงเวลาจอง: ${DateFormat('yyyy-MM-dd').format(bookingStart)} - ${DateFormat('yyyy-MM-dd').format(bookingEnd)}',
    );
    debugPrint('   อยู่ในช่วงเวลาปฏิบัติธรรม: $isWithin');

    return isWithin;
  }

  /// สร้างการจองห้องพักใหม่
  Future<bool> createRoomBooking({
    required int roomId,
    required String visitorId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
  }) async {
    try {
      // ตรวจสอบการขัดแย้ง
      final hasConflict = await hasBookingConflict(
        roomId: roomId,
        startDate: checkInDate,
        endDate: checkOutDate,
      );

      if (hasConflict) {
        debugPrint('❌ พบการจองที่ขัดแย้ง');
        return false;
      }

      // ตรวจสอบว่าอยู่ในช่วงเวลาปฏิบัติธรรม
      final isWithin = await isBookingWithinPracticePeriod(
        visitorId: visitorId,
        bookingStartDate: checkInDate,
        bookingEndDate: checkOutDate,
      );

      if (!isWithin) {
        debugPrint('❌ การจองไม่อยู่ในช่วงเวลาปฏิบัติธรรม');
        return false;
      }

      final db = await _dbHelper.db;
      final checkInStr = DateFormat('yyyy-MM-dd').format(checkInDate);
      final checkOutStr = DateFormat('yyyy-MM-dd').format(checkOutDate);

      await db.insert('room_bookings', {
        'room_id': roomId,
        'visitor_id': visitorId,
        'check_in_date': checkInStr,
        'check_out_date': checkOutStr,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ สร้างการจองห้องพักสำเร็จ');
      return true;
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการสร้างการจอง: $e');
      return false;
    }
  }
}

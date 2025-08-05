import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import '../models/reg_data.dart';

/// ผลลัพธ์การตรวจสอบการจองห้องพัก
class BookingValidationResult {
  final bool isValid;
  final String? errorMessage;

  const BookingValidationResult({required this.isValid, this.errorMessage});

  /// สร้างผลลัพธ์ที่ถูกต้อง
  factory BookingValidationResult.success() {
    return const BookingValidationResult(isValid: true);
  }

  /// สร้างผลลัพธ์ที่ไม่ถูกต้อง
  factory BookingValidationResult.error(String message) {
    return BookingValidationResult(isValid: false, errorMessage: message);
  }
}

/// Service สำหรับจัดการการจองห้องพักแยกจากการจัดการวันที่ลงทะเบียน
class BookingService {
  final DbHelper _dbHelper = DbHelper();

  /// Getter สำหรับเข้าถึง DbHelper
  DbHelper get dbHelper => _dbHelper;

  /// อัพเดตวันที่เข้าและออกของการจองห้องพัก (ไม่กระทบ reg_additional_info)
  /// Returns BookingValidationResult instead of bool for better error handling
  Future<BookingValidationResult> updateRoomBookingDatesWithValidation({
    required int bookingId,
    required DateTime newCheckInDate,
    required DateTime newCheckOutDate,
    required String visitorId,
  }) async {
    try {
      debugPrint('🔧 อัพเดตการจองห้องพัก ID: $bookingId');
      debugPrint(
        '   วันที่เข้าใหม่: ${DateFormat('yyyy-MM-dd').format(newCheckInDate)}',
      );
      debugPrint(
        '   วันที่ออกใหม่: ${DateFormat('yyyy-MM-dd').format(newCheckOutDate)}',
      );

      // ตรวจสอบว่าอยู่ในช่วงเวลาปฏิบัติธรรม
      final practiceInfo = await getPracticePeriod(visitorId);
      if (practiceInfo == null ||
          practiceInfo.startDate == null ||
          practiceInfo.endDate == null) {
        return BookingValidationResult.error('ไม่พบข้อมูลช่วงเวลาปฏิบัติธรรม');
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
        newCheckInDate.year,
        newCheckInDate.month,
        newCheckInDate.day,
      );
      final bookingEnd = DateTime(
        newCheckOutDate.year,
        newCheckOutDate.month,
        newCheckOutDate.day,
      );

      if (bookingStart.isBefore(practiceStart) ||
          bookingEnd.isAfter(practiceEnd)) {
        return BookingValidationResult.error(
          'วันที่จองต้องอยู่ในช่วงเวลาปฏิบัติธรรม\n'
          '(${DateFormat('dd/MM/yyyy').format(practiceStart)} - ${DateFormat('dd/MM/yyyy').format(practiceEnd)})',
        );
      }

      // ตรวจสอบการขัดแย้งในห้องเดียวกัน
      final db = await _dbHelper.db;
      final bookingResult = await db.query(
        'room_bookings',
        where: 'id = ?',
        whereArgs: [bookingId],
      );

      if (bookingResult.isEmpty) {
        return BookingValidationResult.error('ไม่พบข้อมูลการจอง');
      }

      final roomId = bookingResult.first['room_id'] as int;
      final hasConflict = await hasBookingConflict(
        roomId: roomId,
        startDate: newCheckInDate,
        endDate: newCheckOutDate,
        excludeBookingId: bookingId,
      );

      if (hasConflict) {
        return BookingValidationResult.error(
          'มีการจองอื่นขัดแย้งในช่วงเวลาที่เลือก',
        );
      }

      final newCheckInStr = DateFormat('yyyy-MM-dd').format(newCheckInDate);
      final newCheckOutStr = DateFormat('yyyy-MM-dd').format(newCheckOutDate);

      // อัพเดต room_bookings table
      await db.update(
        'room_bookings',
        {'check_in_date': newCheckInStr, 'check_out_date': newCheckOutStr},
        where: 'id = ?',
        whereArgs: [bookingId],
      );

      debugPrint('✅ อัพเดต room_bookings สำเร็จ');
      return BookingValidationResult.success();
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการอัพเดตการจองห้องพัก: $e');
      return BookingValidationResult.error('เกิดข้อผิดพลาดในการอัพเดต: $e');
    }
  }

  /// Legacy method for backward compatibility
  Future<bool> updateRoomBookingDates({
    required int bookingId,
    required DateTime newCheckInDate,
    required DateTime newCheckOutDate,
    required String visitorId,
  }) async {
    final result = await updateRoomBookingDatesWithValidation(
      bookingId: bookingId,
      newCheckInDate: newCheckInDate,
      newCheckOutDate: newCheckOutDate,
      visitorId: visitorId,
    );
    return result.isValid;
  }

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

  /// Check if booking can be cancelled
  /// Only allows cancellation if today is the same as the check-in date
  Future<BookingValidationResult> canCancelBooking({
    required int bookingId,
    required String visitorId,
  }) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        return BookingValidationResult.error('ไม่พบข้อมูลการจอง');
      }

      final checkInDate = DateTime.parse(booking['check_in_date'] as String);
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final checkInDateOnly = DateTime(
        checkInDate.year,
        checkInDate.month,
        checkInDate.day,
      );

      debugPrint('🔍 ตรวจสอบสิทธิ์ในการยกเลิกการจอง:');
      debugPrint(
        '   วันที่เข้าพัก: ${DateFormat('yyyy-MM-dd').format(checkInDateOnly)}',
      );
      debugPrint(
        '   วันที่วันนี้: ${DateFormat('yyyy-MM-dd').format(todayOnly)}',
      );

      // ✅ อนุญาตให้ยกเลิกได้เฉพาะในวันที่เข้าพักเท่านั้น
      if (!todayOnly.isAtSameMomentAs(checkInDateOnly)) {
        debugPrint('❌ ไม่สามารถยกเลิกได้ - อนุญาตเฉพาะในวันที่เข้าพักเท่านั้น');
        return BookingValidationResult.error(
          'ไม่สามารถยกเลิกการจองได้ - หากต้องการเปลี่ยนแปลง กรุณาใช้เมนู “ปรับปรุงวันที่เข้าพัก” สำหรับห้องที่มีการเข้าพักเกิน 1 วันแล้ว',
        );
      }

      debugPrint('✅ อนุญาตให้ยกเลิก - วันนี้ตรงกับวันที่เข้าพัก');
      return BookingValidationResult.success();
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการตรวจสอบการยกเลิก: $e');
      return BookingValidationResult.error(
        'เกิดข้อผิดพลาดในการตรวจสอบสิทธิ์การยกเลิกการจอง',
      );
    }
  }

  /// ตรวจสอบว่าสามารถเปลี่ยนห้องได้หรือไม่
  /// ต้องตรวจสอบว่าห้องปลายทางว่างครบทุกวันในช่วงที่จะย้าย
  Future<BookingValidationResult> canTransferRoom({
    required int currentBookingId,
    required int targetRoomId,
    required String visitorId,
  }) async {
    try {
      final db = await _dbHelper.db;

      // ดึงข้อมูลการจองปัจจุบัน
      final bookingResult = await db.query(
        'room_bookings',
        where: 'id = ?',
        whereArgs: [currentBookingId],
      );

      if (bookingResult.isEmpty) {
        return BookingValidationResult.error('ไม่พบข้อมูลการจอง');
      }

      final booking = bookingResult.first;
      final checkInDate = DateTime.parse(booking['check_in_date'] as String);
      final checkOutDate = DateTime.parse(booking['check_out_date'] as String);

      debugPrint('🔍 ตรวจสอบการเปลี่ยนห้อง:');
      debugPrint('   ห้องปลายทาง: $targetRoomId');
      debugPrint(
        '   ช่วงวันที่: ${DateFormat('yyyy-MM-dd').format(checkInDate)} - ${DateFormat('yyyy-MM-dd').format(checkOutDate)}',
      );

      // ตรวจสอบการจองที่ขัดแย้งในห้องปลายทาง
      final conflicts = await getExistingRoomBookings(
        roomId: targetRoomId,
        startDate: checkInDate,
        endDate: checkOutDate,
        excludeBookingId: currentBookingId,
      );

      if (conflicts.isNotEmpty) {
        debugPrint('❌ ห้องปลายทางไม่ว่าง');
        final conflictDates = conflicts
            .map((c) {
              final start = DateTime.parse(c['check_in_date'] as String);
              final end = DateTime.parse(c['check_out_date'] as String);
              return '${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}';
            })
            .join(', ');

        return BookingValidationResult.error(
          'ไม่สามารถเปลี่ยนห้องได้ เนื่องจากห้องปลายทางไม่ว่างในช่วงวันที่:\n$conflictDates',
        );
      }

      debugPrint('✅ สามารถเปลี่ยนห้องได้');
      return BookingValidationResult.success();
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการตรวจสอบการเปลี่ยนห้อง: $e');
      return BookingValidationResult.error('เกิดข้อผิดพลาดในการตรวจสอบ');
    }
  }

  /// ดึงข้อมูลการจองตาม ID
  Future<Map<String, dynamic>?> getBookingById(int bookingId) async {
    try {
      final db = await _dbHelper.db;
      final result = await db.query(
        'room_bookings',
        where: 'id = ?',
        whereArgs: [bookingId],
      );

      if (result.isEmpty) {
        debugPrint('❌ ไม่พบการจอง ID: $bookingId');
        return null;
      }

      return result.first;
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการดึงข้อมูลการจอง: $e');
      return null;
    }
  }

  /// Cancel room booking
  /// Only allows cancellation if today is the same as the check-in date
  Future<bool> cancelBooking({
    required int bookingId,
    required String visitorId,
  }) async {
    try {
      // Get booking data
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        debugPrint('❌ Booking not found with ID: $bookingId');
        return false;
      }

      // Compare today with check-in date (date only, no time)
      final checkInDate = DateTime.parse(booking['check_in_date'] as String);
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final checkInDateOnly = DateTime(
        checkInDate.year,
        checkInDate.month,
        checkInDate.day,
      );

      debugPrint('🔍 Checking room cancellation:');
      debugPrint(
        '   Check-in date: ${DateFormat('yyyy-MM-dd').format(checkInDateOnly)}',
      );
      debugPrint('   Today: ${DateFormat('yyyy-MM-dd').format(todayOnly)}');

      // 🛑 Cancellation Rules: Only allow if today equals check-in date
      if (!todayOnly.isAtSameMomentAs(checkInDateOnly)) {
        debugPrint('❌ Cannot cancel – allowed only on the check-in date.');
        return false;
      }

      // If we reach here, today equals check-in date - cancellation allowed
      debugPrint('✅ Cancellation allowed – today matches check-in date');

      final db = await _dbHelper.db;

      // Update status to cancelled
      await db.update(
        'room_bookings',
        {'status': 'cancelled'},
        where: 'id = ?',
        whereArgs: [bookingId],
      );

      debugPrint(
        '✅ Room booking cancelled successfully - booking ID: $bookingId',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error cancelling booking: $e');
      return false;
    }
  }

  /// เปลี่ยนห้องพัก
  Future<bool> transferRoom({
    required int currentBookingId,
    required int targetRoomId,
    required String visitorId,
  }) async {
    try {
      // ตรวจสอบว่าสามารถเปลี่ยนห้องได้หรือไม่
      final validation = await canTransferRoom(
        currentBookingId: currentBookingId,
        targetRoomId: targetRoomId,
        visitorId: visitorId,
      );

      if (!validation.isValid) {
        debugPrint('❌ ไม่สามารถเปลี่ยนห้องได้: ${validation.errorMessage}');
        return false;
      }

      final db = await _dbHelper.db;

      // อัพเดตห้องใหม่
      await db.update(
        'room_bookings',
        {'room_id': targetRoomId},
        where: 'id = ?',
        whereArgs: [currentBookingId],
      );

      debugPrint('✅ เปลี่ยนห้องสำเร็จ');
      return true;
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการเปลี่ยนห้อง: $e');
      return false;
    }
  }

  /// สรุปการใช้งานห้องพักในช่วงเวลาที่กำหนด
  Future<List<RoomUsageSummary>> getRoomUsageSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final iseSingleDay =
          startDate.isAtSameMomentAs(endDate) ||
          endDate.difference(startDate).inDays == 0;

      debugPrint('🔍 สรุปการใช้งานห้องพัก');
      debugPrint(
        '   ช่วงเวลา: ${DateFormat('yyyy-MM-dd').format(startDate)} - ${DateFormat('yyyy-MM-dd').format(endDate)}',
      );
      debugPrint('   เป็นวันเดียว: $iseSingleDay');

      if (iseSingleDay) {
        return await _getDailyRoomStatus(startDate);
      } else {
        return await _getMultiDayRoomUsage(startDate, endDate);
      }
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการสรุปการใช้งานห้อง: $e');
      return [];
    }
  }

  /// ดึงสถานะห้องพักรายวัน (สำหรับวันเดียว)
  Future<List<RoomUsageSummary>> _getDailyRoomStatus(DateTime date) async {
    final db = await _dbHelper.db;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    debugPrint('📅 ดึงสถานะห้องพักรายวัน: $dateStr');

    // ดึงข้อมูลห้องทั้งหมดพร้อมสถานะการจอง
    final result = await db.rawQuery(
      '''
      SELECT 
        r.id,
        r.name,
        r.status as room_status,
        r.size,
        r.capacity,
        CASE 
          WHEN rb.id IS NOT NULL THEN 'จองแล้ว'
          WHEN r.status = 'occupied' THEN 'มีผู้เข้าพัก'
          WHEN r.status = 'available' THEN 'ว่าง'
          WHEN r.status = 'maintenance' THEN 'ปิดปรับปรุง'
          ELSE 'ไม่ทราบสถานะ'
        END as daily_status,
        rb.visitor_id,
        COALESCE(regs.first || ' ' || regs.last, '') as guest_name
      FROM rooms r
      LEFT JOIN room_bookings rb ON r.id = rb.room_id 
        AND rb.status != 'cancelled'
        AND ? >= rb.check_in_date 
        AND ? <= rb.check_out_date
      LEFT JOIN regs ON rb.visitor_id = regs.id
      ORDER BY r.name
    ''',
      [dateStr, dateStr],
    );

    debugPrint('   พบห้อง ${result.length} ห้อง');

    return result
        .map(
          (row) => RoomUsageSummary(
            roomId: row['id'] as int,
            roomName: row['name'] as String,
            roomSize: row['size'] as String,
            capacity: row['capacity'] as int,
            usageDays: 0, // ไม่ใช้สำหรับรายวัน
            dailyStatus: row['daily_status'] as String,
            guestName: row['guest_name'] as String? ?? '',
            isSingleDay: true,
          ),
        )
        .toList();
  }

  /// ดึงจำนวนวันที่ใช้งานห้อง (สำหรับหลายวัน)
  Future<List<RoomUsageSummary>> _getMultiDayRoomUsage(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _dbHelper.db;
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    debugPrint('📊 ดึงจำนวนวันที่ใช้งานห้อง: $startDateStr - $endDateStr');

    // คำนวณจำนวนวันที่แต่ละห้องถูกใช้งาน
    final result = await db.rawQuery(
      '''
      SELECT 
        r.id,
        r.name,
        r.size,
        r.capacity,
        COALESCE(usage_data.usage_days, 0) as usage_days,
        usage_data.total_bookings
      FROM rooms r
      LEFT JOIN (
        SELECT 
          rb.room_id,
          COUNT(DISTINCT rb.id) as total_bookings,
          SUM(
            CASE 
              WHEN rb.check_out_date <= ? THEN 
                julianday(rb.check_out_date) - julianday(MAX(rb.check_in_date, ?)) + 1
              WHEN rb.check_in_date >= ? THEN
                julianday(MIN(rb.check_out_date, ?)) - julianday(rb.check_in_date) + 1
              ELSE
                julianday(?) - julianday(?) + 1
            END
          ) as usage_days
        FROM room_bookings rb
        WHERE rb.status != 'cancelled'
          AND NOT (rb.check_out_date < ? OR rb.check_in_date > ?)
        GROUP BY rb.room_id
      ) usage_data ON r.id = usage_data.room_id
      ORDER BY r.name
    ''',
      [
        endDateStr, startDateStr, // สำหรับ CASE แรก
        startDateStr, endDateStr, // สำหรับ CASE สอง
        endDateStr, startDateStr, // สำหรับ CASE สาม
        startDateStr, endDateStr, // สำหรับ WHERE clause
      ],
    );

    debugPrint('   พบห้อง ${result.length} ห้อง');

    return result.map((row) {
      final usageDays = (row['usage_days'] as num?)?.toInt() ?? 0;
      final totalBookings = (row['total_bookings'] as num?)?.toInt() ?? 0;

      debugPrint(
        '   ห้อง ${row['name']}: ${usageDays} วัน (${totalBookings} การจอง)',
      );

      return RoomUsageSummary(
        roomId: row['id'] as int,
        roomName: row['name'] as String,
        roomSize: row['size'] as String,
        capacity: row['capacity'] as int,
        usageDays: usageDays,
        dailyStatus: '', // ไม่ใช้สำหรับหลายวัน
        guestName: '',
        isSingleDay: false,
      );
    }).toList();
  }
}

/// คลาสสำหรับเก็บข้อมูลสรุปการใช้งานห้องพัก
class RoomUsageSummary {
  final int roomId;
  final String roomName;
  final String roomSize;
  final int capacity;
  final int usageDays;
  final String dailyStatus;
  final String guestName;
  final bool isSingleDay;

  const RoomUsageSummary({
    required this.roomId,
    required this.roomName,
    required this.roomSize,
    required this.capacity,
    required this.usageDays,
    required this.dailyStatus,
    required this.guestName,
    required this.isSingleDay,
  });

  @override
  String toString() {
    if (isSingleDay) {
      return 'RoomUsageSummary(${roomName}: ${dailyStatus}${guestName.isNotEmpty ? ' - ${guestName}' : ''})';
    } else {
      return 'RoomUsageSummary(${roomName}: ${usageDays} วัน)';
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// ผลลัพธ์การตรวจสอบความถูกต้องของการปรับปรุงวันที่เข้าพัก
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final ValidationErrorType? errorType;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.errorType,
  });

  /// สร้างผลลัพธ์ที่ถูกต้อง
  factory ValidationResult.success() {
    return const ValidationResult(isValid: true);
  }

  /// สร้างผลลัพธ์ที่ไม่ถูกต้อง
  factory ValidationResult.error(String message, ValidationErrorType type) {
    return ValidationResult(
      isValid: false,
      errorMessage: message,
      errorType: type,
    );
  }
}

/// ประเภทของข้อผิดพลาดในการตรวจสอบ
enum ValidationErrorType {
  endDateBeforeToday, // วันสิ้นสุดก่อนวันปัจจุบัน
  endDateBeforeStartDate, // วันสิ้นสุดก่อนวันเริ่มต้น
  conflictingBookings, // มีการจองที่ขัดแย้ง
  invalidDateRange, // ช่วงวันที่ไม่ถูกต้อง
}

/// Utility class สำหรับตรวจสอบความถูกต้องของการปรับปรุงวันที่เข้าพัก
class StayDurationValidator {
  /// ตรวจสอบความถูกต้องของการปรับปรุงวันที่เข้าพัก
  static ValidationResult validateUpdatedStayDate({
    required DateTime startDate,
    required DateTime newEndDate,
    required List<DateTimeRange> existingBookings,
    required DateTime today,
  }) {
    debugPrint('🔍 ตรวจสอบการปรับปรุงวันที่เข้าพัก:');
    debugPrint('   startDate: $startDate');
    debugPrint('   newEndDate: $newEndDate');
    debugPrint('   today: $today');
    debugPrint('   existingBookings: ${existingBookings.length} รายการ');

    // แปลงเป็นวันที่เท่านั้น (ตัดเวลา) เพื่อเปรียบเทียบ
    final startDateOnly = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final newEndDateOnly = DateTime(
      newEndDate.year,
      newEndDate.month,
      newEndDate.day,
    );
    final todayOnly = DateTime(today.year, today.month, today.day);

    debugPrint('   startDateOnly: $startDateOnly');
    debugPrint('   newEndDateOnly: $newEndDateOnly');
    debugPrint('   todayOnly: $todayOnly');

    // 1. ตรวจสอบว่า newEndDate ต้องไม่ก่อนวันปัจจุบัน
    if (newEndDateOnly.isBefore(todayOnly)) {
      debugPrint('❌ newEndDate ก่อนวันปัจจุบัน');
      return ValidationResult.error(
        'ไม่สามารถลดวันเข้าพักให้เลยวันปัจจุบันได้\n'
        'วันที่สิ้นสุดใหม่ต้องไม่ก่อน ${_formatDate(todayOnly)}',
        ValidationErrorType.endDateBeforeToday,
      );
    }

    // 2. ตรวจสอบว่า newEndDate ต้องไม่ก่อน startDate
    if (newEndDateOnly.isBefore(startDateOnly)) {
      debugPrint('❌ newEndDate ก่อน startDate');
      return ValidationResult.error(
        'วันที่สิ้นสุดใหม่ต้องไม่ก่อนวันที่เริ่มต้น\n'
        'วันที่เริ่มต้น: ${_formatDate(startDateOnly)}\n'
        'วันที่สิ้นสุดใหม่: ${_formatDate(newEndDateOnly)}',
        ValidationErrorType.endDateBeforeStartDate,
      );
    }

    // 3. ตรวจสอบการจองที่ขัดแย้ง
    final conflictingBookings = _findConflictingBookings(
      startDateOnly,
      newEndDateOnly,
      existingBookings,
    );

    if (conflictingBookings.isNotEmpty) {
      debugPrint('❌ พบการจองที่ขัดแย้ง: ${conflictingBookings.length} รายการ');
      return ValidationResult.error(
        'ไม่สามารถลดช่วงวันเข้าพักได้ เพราะมีการจองห้องในวันดังกล่าว\n'
        'กรุณายกเลิกการจองก่อน',
        ValidationErrorType.conflictingBookings,
      );
    }

    debugPrint('✅ การปรับปรุงวันที่เข้าพักถูกต้อง');
    return ValidationResult.success();
  }

  /// ค้นหาการจองที่ขัดแย้งกับช่วงวันที่ใหม่
  static List<DateTimeRange> _findConflictingBookings(
    DateTime startDate,
    DateTime endDate,
    List<DateTimeRange> existingBookings,
  ) {
    final conflictingBookings = <DateTimeRange>[];

    for (final booking in existingBookings) {
      final bookingStart = DateTime(
        booking.start.year,
        booking.start.month,
        booking.start.day,
      );
      final bookingEnd = DateTime(
        booking.end.year,
        booking.end.month,
        booking.end.day,
      );

      debugPrint(
        '   ตรวจสอบการจอง: ${_formatDate(bookingStart)} - ${_formatDate(bookingEnd)}',
      );

      // ตรวจสอบว่าการจองนี้ขัดแย้งกับช่วงวันที่ใหม่หรือไม่
      // การจองจะขัดแย้งถ้ามีช่วงวันที่ที่ทับซ้อนกัน
      // ใช้การตรวจสอบที่แม่นยำมากขึ้น
      final hasOverlap =
          !(bookingEnd.isBefore(startDate) || bookingStart.isAfter(endDate));

      if (hasOverlap) {
        // ตรวจสอบเพิ่มเติมว่าเป็นการจองเดียวกันหรือไม่
        // ถ้าเป็นการจองเดียวกัน (startDate และ endDate อยู่ในช่วงการจองเดิม) ให้ข้ามไป
        final isSameBooking =
            (startDate.isAtSameMomentAs(bookingStart) ||
                startDate.isAfter(bookingStart)) &&
            (endDate.isAtSameMomentAs(bookingEnd) ||
                endDate.isBefore(bookingEnd));

        if (!isSameBooking) {
          conflictingBookings.add(booking);
          debugPrint(
            '   - การจองที่ขัดแย้ง: ${_formatDate(bookingStart)} - ${_formatDate(bookingEnd)}',
          );
        } else {
          debugPrint('   - ข้ามการจองเดียวกัน');
        }
      }
    }

    return conflictingBookings;
  }

  /// จัดรูปแบบวันที่
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// ตรวจสอบว่าวันที่สองวันเป็นวันเดียวกันหรือไม่
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// คำนวณจำนวนวันระหว่างวันที่สองวัน
  static int calculateDaysDifference(DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(start).inDays;
  }

  /// สร้างข้อความสรุปการเปลี่ยนแปลง
  static String generateChangeSummary({
    required DateTime originalStartDate,
    required DateTime originalEndDate,
    required DateTime newStartDate,
    required DateTime newEndDate,
  }) {
    final originalDays =
        calculateDaysDifference(originalStartDate, originalEndDate) + 1;
    final newDays = calculateDaysDifference(newStartDate, newEndDate) + 1;
    final dayDifference = newDays - originalDays;

    String summary = 'สรุปการเปลี่ยนแปลง:\n';
    summary +=
        '• วันที่เริ่มต้น: ${_formatDate(originalStartDate)} → ${_formatDate(newStartDate)}\n';
    summary +=
        '• วันที่สิ้นสุด: ${_formatDate(originalEndDate)} → ${_formatDate(newEndDate)}\n';
    summary += '• จำนวนวัน: $originalDays วัน → $newDays วัน\n';

    if (dayDifference > 0) {
      summary += '• การเปลี่ยนแปลง: เพิ่ม $dayDifference วัน';
    } else if (dayDifference < 0) {
      summary += '• การเปลี่ยนแปลง: ลด ${dayDifference.abs()} วัน';
    } else {
      summary += '• การเปลี่ยนแปลง: ไม่มีการเปลี่ยนแปลง';
    }

    return summary;
  }

  /// ตรวจสอบว่าการเปลี่ยนแปลงเป็นไปตามเงื่อนไขหรือไม่
  static bool isChangeAllowed({
    required DateTime originalStartDate,
    required DateTime originalEndDate,
    required DateTime newStartDate,
    required DateTime newEndDate,
    required DateTime today,
  }) {
    // ตรวจสอบว่าการเปลี่ยนแปลงไม่ทำให้วันเริ่มต้นย้อนหลัง
    if (newStartDate.isBefore(originalStartDate)) {
      return false;
    }

    // ตรวจสอบว่าการเปลี่ยนแปลงไม่ทำให้วันสิ้นสุดย้อนหลัง
    if (newEndDate.isBefore(originalStartDate)) {
      return false;
    }

    // ตรวจสอบว่าการเปลี่ยนแปลงไม่ทำให้วันสิ้นสุดก่อนวันปัจจุบัน
    if (newEndDate.isBefore(today)) {
      return false;
    }

    return true;
  }
}

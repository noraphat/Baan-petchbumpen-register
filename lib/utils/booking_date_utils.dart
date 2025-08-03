import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utility class สำหรับจัดการวันที่ในการจองห้องพัก
class BookingDateUtils {
  /// ฟังก์ชันสำหรับกำหนดวันเริ่มต้นที่สามารถจองได้
  /// ป้องกันการจองย้อนหลัง โดยใช้วันปัจจุบันเป็นค่าขั้นต่ำ
  static DateTime getFirstAvailableBookingDate(DateTime registrationStartDate) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final startDateOnly = DateTime(
      registrationStartDate.year,
      registrationStartDate.month,
      registrationStartDate.day,
    );

    debugPrint('📅 getFirstAvailableBookingDate:');
    debugPrint('   registrationStartDate: $registrationStartDate');
    debugPrint('   today: $today');
    debugPrint('   startDateOnly: $startDateOnly');
    debugPrint('   todayOnly: $todayOnly');

    // ถ้า registrationStartDate < วันนี้ → return วันนี้
    if (startDateOnly.isBefore(todayOnly)) {
      debugPrint('   → ใช้วันปัจจุบัน (ป้องกันการจองย้อนหลัง)');
      return todayOnly;
    } else {
      debugPrint('   → ใช้วันที่ลงทะเบียน');
      return startDateOnly;
    }
  }

  /// ฟังก์ชันสำหรับกำหนดวันสิ้นสุดที่สามารถจองได้
  /// ใช้ endDate จากข้อมูลการลงทะเบียน
  static DateTime getLastAvailableBookingDate(DateTime registrationEndDate) {
    final endDateOnly = DateTime(
      registrationEndDate.year,
      registrationEndDate.month,
      registrationEndDate.day,
    );

    debugPrint('📅 getLastAvailableBookingDate:');
    debugPrint('   registrationEndDate: $registrationEndDate');
    debugPrint('   endDateOnly: $endDateOnly');
    debugPrint('   → ใช้วันที่สิ้นสุดการลงทะเบียน');

    return endDateOnly;
  }

  /// ฟังก์ชันสำหรับสร้างช่วงวันที่เริ่มต้นสำหรับ DateRangePicker
  /// ใช้ firstDate เป็นวันเริ่มต้น และ lastDate เป็นวันสิ้นสุด
  static DateTimeRange getInitialDateRange(
    DateTime firstDate,
    DateTime lastDate,
  ) {
    // ตรวจสอบว่า firstDate ไม่เกิน lastDate
    if (firstDate.isAfter(lastDate)) {
      debugPrint('⚠️ firstDate เกิน lastDate - ใช้ lastDate เป็นทั้งสองค่า');
      return DateTimeRange(start: lastDate, end: lastDate);
    }

    // ใช้ช่วงเต็มที่อนุญาต
    debugPrint('📅 getInitialDateRange:');
    debugPrint('   firstDate: $firstDate');
    debugPrint('   lastDate: $lastDate');
    debugPrint('   → ใช้ช่วงเต็มที่อนุญาต');

    return DateTimeRange(start: firstDate, end: lastDate);
  }

  /// ฟังก์ชันสำหรับตรวจสอบว่าเป็นวันเดียวกันหรือไม่
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// ฟังก์ชันสำหรับตรวจสอบความถูกต้องของช่วงวันที่การจอง
  static bool validateBookingDateRange(
    DateTimeRange selectedRange,
    DateTime registrationStartDate,
    DateTime registrationEndDate,
  ) {
    debugPrint('🔍 Validating booking date range:');
    debugPrint('   Selected: ${selectedRange.start} - ${selectedRange.end}');
    debugPrint('   Registered: $registrationStartDate - $registrationEndDate');

    // แปลงเป็นวันที่เท่านั้น (ตัดเวลา) เพื่อเปรียบเทียบ
    final selectedStartDate = DateTime(
      selectedRange.start.year,
      selectedRange.start.month,
      selectedRange.start.day,
    );
    final selectedEndDate = DateTime(
      selectedRange.end.year,
      selectedRange.end.month,
      selectedRange.end.day,
    );

    // ใช้ฟังก์ชันใหม่เพื่อกำหนดช่วงวันที่ที่อนุญาต
    final allowedFirstDate = getFirstAvailableBookingDate(
      registrationStartDate,
    );
    final allowedLastDate = getLastAvailableBookingDate(registrationEndDate);

    debugPrint('   Allowed range: $allowedFirstDate - $allowedLastDate');

    // ตรวจสอบว่าวันเริ่มต้นต้องไม่ก่อนวันที่อนุญาต
    final startValid =
        selectedStartDate.isAtSameMomentAs(allowedFirstDate) ||
        selectedStartDate.isAfter(allowedFirstDate);

    // ตรวจสอบว่าวันสิ้นสุดต้องไม่หลังวันที่อนุญาต
    final endValid =
        selectedEndDate.isAtSameMomentAs(allowedLastDate) ||
        selectedEndDate.isBefore(allowedLastDate);

    // ตรวจสอบว่าวันเริ่มต้นไม่หลังวันสิ้นสุด
    final rangeValid =
        selectedStartDate.isBefore(selectedEndDate) ||
        isSameDay(selectedStartDate, selectedEndDate);

    debugPrint(
      '   Start valid: $startValid, End valid: $endValid, Range valid: $rangeValid',
    );
    debugPrint('   Start check: $selectedStartDate >= $allowedFirstDate');
    debugPrint('   End check: $selectedEndDate <= $allowedLastDate');

    return startValid && endValid && rangeValid;
  }

  /// ฟังก์ชันสำหรับสร้างข้อความ error ที่ชัดเจนสำหรับช่วงวันที่ที่ไม่ถูกต้อง
  static String getDateRangeErrorMessage(
    DateTimeRange selectedRange,
    DateTime registrationStartDate,
    DateTime registrationEndDate,
    String Function(String) formatDate, // ฟังก์ชันสำหรับจัดรูปแบบวันที่
  ) {
    final selectedStart = formatDate(selectedRange.start.toIso8601String());
    final selectedEnd = formatDate(selectedRange.end.toIso8601String());
    final regStart = formatDate(registrationStartDate.toIso8601String());
    final regEnd = formatDate(registrationEndDate.toIso8601String());

    // แปลงเป็นวันที่เท่านั้น (ตัดเวลา) เพื่อเปรียบเทียบ
    final selectedStartDate = DateTime(
      selectedRange.start.year,
      selectedRange.start.month,
      selectedRange.start.day,
    );
    final selectedEndDate = DateTime(
      selectedRange.end.year,
      selectedRange.end.month,
      selectedRange.end.day,
    );

    // ใช้ฟังก์ชันใหม่เพื่อกำหนดช่วงวันที่ที่อนุญาต
    final allowedFirstDate = getFirstAvailableBookingDate(
      registrationStartDate,
    );
    final allowedLastDate = getLastAvailableBookingDate(registrationEndDate);
    final allowedStart = formatDate(allowedFirstDate.toIso8601String());
    final allowedEnd = formatDate(allowedLastDate.toIso8601String());

    String errorMessage = '❌ **ไม่สามารถเลือกวันเกินช่วงที่อนุญาตได้**\n\n';

    // ตรวจสอบว่าวันเริ่มต้นหรือวันสิ้นสุดที่เกิน
    if (selectedStartDate.isBefore(allowedFirstDate)) {
      errorMessage +=
          '• วันเริ่มต้น ($selectedStart) ต้องไม่ก่อนวันที่อนุญาต ($allowedStart)\n';
    }

    if (selectedEndDate.isAfter(allowedLastDate)) {
      errorMessage +=
          '• วันสิ้นสุด ($selectedEnd) ต้องไม่หลังวันที่อนุญาต ($allowedEnd)\n';
    }

    errorMessage += '\n**ช่วงที่เลือก:** $selectedStart - $selectedEnd\n';
    errorMessage += '**ช่วงที่อนุญาต:** $allowedStart - $allowedEnd\n';

    // แสดงข้อมูลเพิ่มเติมหากมีการเปลี่ยนแปลงจากข้อมูลการลงทะเบียน
    if (allowedFirstDate.isAfter(registrationStartDate)) {
      errorMessage += '**ข้อมูลการลงทะเบียน:** $regStart - $regEnd\n';
      errorMessage +=
          '⚠️ วันที่เริ่มต้นถูกปรับเป็นวันปัจจุบัน (ไม่สามารถจองย้อนหลังได้)\n\n';
    } else {
      errorMessage += '\n';
    }

    errorMessage +=
        '⚠️ กรุณาเลือกวันที่ระหว่าง $allowedStart ถึง $allowedEnd เท่านั้น';

    return errorMessage;
  }
}

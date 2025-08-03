# การแก้ไขปัญหาการอัพเดตข้อมูลการจอง

## ปัญหาที่พบ
เมื่อพยายามอัพเดตข้อมูลการจอง ระบบแสดงข้อความ error:
```
❌ พบการจองที่ขัดแย้ง: 1 รายการ
- การจองที่ขัดแย้ง: 03/08/2025 - 05/08/2025
```

## สาเหตุของปัญหา
1. ฟังก์ชัน `_getExistingBookingsForRoom` ดึงข้อมูลการจองที่มีอยู่ทั้งหมด รวมถึงการจองปัจจุบัน
2. ฟังก์ชัน `_findConflictingBookings` ใน `StayDurationValidator` ตรวจสอบการขัดแย้งแบบเข้มงวดเกินไป
3. ระบบคิดว่าการจองปัจจุบันขัดแย้งกับตัวเอง

## การแก้ไขที่ทำ

### 1. ปรับปรุงฟังก์ชัน `_getExistingBookingsForRoom`
- เพิ่มพารามิเตอร์ `excludeBookingId` เพื่อแยกการจองที่ต้องการออกไป
- เพิ่ม debug log เพื่อติดตามการทำงาน
- ปรับปรุง SQL query เพื่อไม่รวมการจองที่ต้องการแยกออกไป

```dart
Future<List<DateTimeRange>> _getExistingBookingsForRoom(
  int roomId,
  DateTime startDate,
  DateTime endDate, {
  int? excludeBookingId,
}) async {
  // ... existing code ...
  
  // ถ้ามีการจองที่ต้องการแยกออกไป
  if (excludeBookingId != null) {
    query += ' AND id != ?';
    args.add(excludeBookingId);
    debugPrint('   แยกการจอง ID: $excludeBookingId ออกไป');
  }
}
```

### 2. ปรับปรุงฟังก์ชัน `_validateUpdatedStayDate`
- ส่ง ID ของการจองปัจจุบันไปยัง `_getExistingBookingsForRoom`
- เพิ่ม debug log เพื่อติดตามการทำงาน

```dart
Future<ValidationResult> _validateUpdatedStayDate(
  Map<String, dynamic> occupantInfo,
  DateTime newEndDate,
) async {
  final currentBookingId = occupantInfo['id'];
  
  // ดึงข้อมูลการจองที่มีอยู่ (ไม่รวมการจองปัจจุบัน)
  final existingBookings = await _getExistingBookingsForRoom(
    occupantInfo['room_id'],
    currentCheckIn,
    newEndDate,
    excludeBookingId: currentBookingId,
  );
}
```

### 3. ปรับปรุงฟังก์ชัน `_findConflictingBookings`
- ปรับปรุงการตรวจสอบการทับซ้อนให้แม่นยำมากขึ้น
- เพิ่มการตรวจสอบว่าเป็นการจองเดียวกันหรือไม่
- เพิ่ม debug log เพื่อติดตามการทำงาน

```dart
static List<DateTimeRange> _findConflictingBookings(
  DateTime startDate,
  DateTime endDate,
  List<DateTimeRange> existingBookings,
) {
  // ใช้การตรวจสอบที่แม่นยำมากขึ้น
  final hasOverlap = !(bookingEnd.isBefore(startDate) || bookingStart.isAfter(endDate));
  
  if (hasOverlap) {
    // ตรวจสอบเพิ่มเติมว่าเป็นการจองเดียวกันหรือไม่
    final isSameBooking = (startDate.isAtSameMomentAs(bookingStart) || startDate.isAfter(bookingStart)) &&
                         (endDate.isAtSameMomentAs(bookingEnd) || endDate.isBefore(bookingEnd));
    
    if (!isSameBooking) {
      conflictingBookings.add(booking);
    }
  }
}
```

## ผลลัพธ์ที่คาดหวัง
- สามารถอัพเดตข้อมูลการจองได้โดยไม่เกิด error
- ระบบจะตรวจสอบการขัดแย้งกับการจองอื่นๆ เท่านั้น ไม่รวมการจองปัจจุบัน
- มี debug log ที่ชัดเจนเพื่อติดตามการทำงาน

## การทดสอบ
สร้างไฟล์ `test_booking_update.dart` เพื่อทดสอบการทำงานของการอัพเดตการจอง

## ไฟล์ที่แก้ไข
1. `lib/utils/stay_duration_validator.dart`
2. `lib/screen/accommodation_booking_screen.dart`
3. `test_booking_update.dart` (ไฟล์ทดสอบใหม่) 